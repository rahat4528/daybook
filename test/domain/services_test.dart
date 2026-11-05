import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/enums/task_priority.dart';
import 'package:daybook/core/enums/core_enums.dart';
import 'package:daybook/domain/models/task_item.dart';
import 'package:daybook/domain/models/subtask_item.dart';
import 'package:daybook/domain/models/alarm_item.dart';
import 'package:daybook/domain/models/daily_plan_block.dart';
import 'package:daybook/domain/models/weather_and_briefing.dart';
import 'package:daybook/domain/services/task_service.dart';
import 'package:daybook/domain/services/planner_service.dart';
import 'package:daybook/domain/services/alarm_challenge_engine.dart';
import 'package:daybook/domain/services/memory_vault_service.dart';
import 'package:daybook/domain/services/weather_scene_engine.dart';
import 'package:daybook/domain/services/briefing_service.dart';

void main() {
  group('TaskService Tests', () {
    late TaskService service;

    setUp(() {
      service = TaskService();
    });

    test('getTodayTasks returns tasks sorted by dynamic priority score', () {
      final now = DateTime(2026, 11, 6, 10, 0);

      service.addTask(
        title: 'Low task',
        priority: TaskPriority.neither,
        estimatedMinutes: 60,
        dueAt: DateTime(2026, 11, 6, 22, 0),
      );

      service.addTask(
        title: 'Emergency critical task',
        priority: TaskPriority.urgentImportant,
        estimatedMinutes: 15, // quick win
        dueAt: DateTime(2026, 11, 6, 11, 0), // due in 1 hr
      );

      final today = service.getTodayTasks(now);
      expect(today.length, 2);
      expect(today.first.title, 'Emergency critical task');
    });

    test('toggleSubtask auto-completes parent task when all subtasks done', () {
      final task = service.addTask(
        title: 'Parent Task',
        subtasks: [
          const SubtaskItem(id: 's1', title: 'Step 1', isCompleted: false),
          const SubtaskItem(id: 's2', title: 'Step 2', isCompleted: false),
        ],
      );

      service.toggleSubtask(task.id, 's1');
      var updated = service.tasks.firstWhere((t) => t.id == task.id);
      expect(updated.status, TaskStatus.inProgress);
      expect(updated.isCompleted, isFalse);

      service.toggleSubtask(task.id, 's2');
      updated = service.tasks.firstWhere((t) => t.id == task.id);
      expect(updated.status, TaskStatus.completed);
      expect(updated.isCompleted, isTrue);
    });

    test('Recurring task completion automatically spawns next iteration', () {
      final baseDue = DateTime(2026, 11, 6, 14, 0);
      final task = service.addTask(
        title: 'Daily Standup',
        recurrence: RecurrenceType.daily,
        dueAt: baseDue,
      );

      service.toggleTaskCompletion(task.id, baseDue);

      expect(service.tasks.length, 2);
      final spawned = service.tasks.firstWhere((t) => t.id != task.id);
      expect(spawned.title, 'Daily Standup');
      expect(spawned.dueAt, baseDue.add(const Duration(days: 1)));
      expect(spawned.isCompleted, isFalse);
    });
  });

  group('PlannerService Tests', () {
    test('generateDailyPlan fills available non-conflicting time slots', () {
      final planner = PlannerService();
      final tasks = [
        TaskItem(
          id: 't1',
          title: 'Deep Study',
          priority: TaskPriority.urgentImportant,
          estimatedMinutes: 60,
          createdAt: DateTime.now(),
        ),
        TaskItem(
          id: 't2',
          title: 'Gym Workout',
          priority: TaskPriority.importantNotUrgent,
          estimatedMinutes: 45,
          createdAt: DateTime.now(),
        ),
      ];

      const fixedMeeting = DailyPlanBlock(
        id: 'fixed-1',
        title: 'Team Sync',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 0,
        category: 'Meeting',
      );

      final plan = planner.generateDailyPlan(
        tasks: tasks,
        fixedBlocks: [fixedMeeting],
        wakeHour: 8,
        wakeMinute: 0,
        sleepHour: 22,
        sleepMinute: 0,
      );

      expect(plan.length, 3);
      // All blocks should have valid start and end
      for (final b in plan) {
        expect(b.endHour * 60 + b.endMinute > b.startHour * 60 + b.startMinute, isTrue);
      }
    });

    test('rolloverUnfinishedBlocks duplicates unfinished tasks with new IDs', () {
      final planner = PlannerService();
      const yBlocks = [
        DailyPlanBlock(
          id: 'b1',
          title: 'Finished Work',
          startHour: 9,
          startMinute: 0,
          endHour: 10,
          endMinute: 0,
          isCompleted: true,
        ),
        DailyPlanBlock(
          id: 'b2',
          title: 'Unfinished Article',
          startHour: 14,
          startMinute: 0,
          endHour: 15,
          endMinute: 0,
          isCompleted: false,
        ),
      ];

      final rolled = planner.rolloverUnfinishedBlocks(
        yesterdayBlocks: yBlocks,
        todayBlocks: [],
      );

      expect(rolled.length, 1);
      expect(rolled.first.title, 'Unfinished Article');
      expect(rolled.first.isCompleted, isFalse);
    });
  });

  group('AlarmChallengeEngine Tests', () {
    final engine = AlarmChallengeEngine(Random(42));

    test('Math equations evaluate to valid correct answers', () {
      final easy = engine.generateMathEquation(ChallengeDifficulty.easy);
      final medium = engine.generateMathEquation(ChallengeDifficulty.medium);
      final hard = engine.generateMathEquation(ChallengeDifficulty.hard);

      expect(easy.question.isNotEmpty, isTrue);
      expect(medium.question.isNotEmpty, isTrue);
      expect(hard.question.isNotEmpty, isTrue);
    });

    test('Memory sequence generation and verification', () {
      final seq = engine.generateMemorySequence(ChallengeDifficulty.easy);
      expect(seq.length, ChallengeDifficulty.easy.memorySequenceLength);

      expect(engine.verifyMemorySequence(seq, List.from(seq)), isTrue);
      expect(engine.verifyMemorySequence(seq, [0, 1, 2]), isFalse); // wrong length
    });

    test('QR Code verification handles normalized values and hashes', () {
      expect(engine.verifyQrCode('  BATHROOM_CODE ', 'bathroom_code'), isTrue);
      expect(engine.verifyQrCode('random_code', 'target_code'), isFalse);
    });

    test('Volume ramp and safety cutoff', () {
      expect(engine.computeVolumeRamp(0), 0.2);
      expect(engine.computeVolumeRamp(30), closeTo(0.6, 0.05));
      expect(engine.computeVolumeRamp(60), 1.0);

      final now = DateTime.now();
      expect(engine.hasExceededMaxRing(now.subtract(const Duration(minutes: 16)), now), isTrue);
      expect(engine.hasExceededMaxRing(now.subtract(const Duration(minutes: 5)), now), isFalse);
    });
  });

  group('MemoryVaultService Tests', () {
    test('Pinned memories are ranked first', () {
      final vault = MemoryVaultService();
      vault.addMemory(key: 'normal', value: 'value 1', isPinned: false);
      vault.addMemory(key: 'pinned', value: 'critical preference', isPinned: true);

      final results = vault.searchMemories();
      expect(results.first.key, 'pinned');
    });

    test('extractMemoryCandidates detects sleep and preference cues', () {
      final vault = MemoryVaultService();
      final candidates = vault.extractMemoryCandidates('I wake up at 6:30 am and I prefer morning study.');
      expect(candidates.isNotEmpty, isTrue);
    });
  });

  group('WeatherSceneEngine & BriefingService Tests', () {
    test('WMO code maps correctly', () {
      expect(WeatherSceneEngine.mapWmoCode(0), WeatherType.clear);
      expect(WeatherSceneEngine.mapWmoCode(2), WeatherType.partlyCloudy);
      expect(WeatherSceneEngine.mapWmoCode(61), WeatherType.rain);
      expect(WeatherSceneEngine.mapWmoCode(95), WeatherType.thunderstorm);
    });

    test('BriefingService aggregates top tasks and calculates total minutes', () {
      final tasks = [
        TaskItem(
          id: '1',
          title: 'Focus 1',
          priority: TaskPriority.urgentImportant,
          estimatedMinutes: 45,
          createdAt: DateTime.now(),
        ),
        TaskItem(
          id: '2',
          title: 'Focus 2',
          priority: TaskPriority.importantNotUrgent,
          estimatedMinutes: 30,
          createdAt: DateTime.now(),
        ),
      ];

      final weather = WeatherState(lastUpdated: DateTime.now());
      const alarm = AlarmItem(id: 'a1', hour: 7, minute: 0, label: 'Wake up');

      final briefing = BriefingService.generateMorningBriefing(
        tasks: tasks,
        weather: weather,
        firstAlarm: alarm,
        isBangla: false,
      );

      expect(briefing.topTaskTitles.length, 2);
      expect(briefing.totalEstimatedMinutes, 75);
      expect(briefing.firstAlarmFormatted, '7:00 AM');
    });

    test('BriefingService generates Evening Review summary', () {
      final tasks = [
        TaskItem(
          id: '1',
          title: 'Completed Item',
          status: TaskStatus.completed,
          createdAt: DateTime.now(),
        ),
        TaskItem(
          id: '2',
          title: 'Pending Item',
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      final review = BriefingService.generateEveningReview(
        allTasks: tasks,
        moodScore: 5,
        notes: 'Great productive day!',
      );

      expect(review.completedTasksCount, 1);
      expect(review.pendingTasksCount, 1);
      expect(review.rolloverTaskIds, ['2']);
      expect(review.moodScore, 5);
    });
  });
}
