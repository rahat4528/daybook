import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/enums/task_priority.dart';
import 'package:daybook/core/enums/core_enums.dart';
import 'package:daybook/domain/models/subtask_item.dart';
import 'package:daybook/domain/models/task_item.dart';
import 'package:daybook/domain/models/alarm_item.dart';
import 'package:daybook/domain/models/daily_plan_block.dart';
import 'package:daybook/domain/models/chat_and_memory.dart';
import 'package:daybook/domain/models/weather_and_briefing.dart';

void main() {
  group('TaskItem Domain Model Tests', () {
    test('TaskItem serialization and deserialization integrity', () {
      final now = DateTime(2026, 11, 6, 10, 0);
      final task = TaskItem(
        id: 't-101',
        title: 'Review System Architecture',
        notes: 'Check database schema and platform channels',
        category: 'Work',
        priority: TaskPriority.urgentImportant,
        status: TaskStatus.inProgress,
        recurrence: RecurrenceType.daily,
        estimatedMinutes: 45,
        dueAt: DateTime(2026, 11, 6, 18, 0),
        subtasks: [
          const SubtaskItem(id: 'st-1', title: 'Verify SQLite schema', isCompleted: true),
          const SubtaskItem(id: 'st-2', title: 'Check AlarmManager hook', isCompleted: false),
        ],
        createdAt: now,
      );

      final json = task.toJson();
      final restored = TaskItem.fromJson(json);

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.notes, task.notes);
      expect(restored.category, task.category);
      expect(restored.priority, TaskPriority.urgentImportant);
      expect(restored.status, TaskStatus.inProgress);
      expect(restored.subtasks.length, 2);
      expect(restored.subtaskProgress, 0.5);
      expect(restored.isCompleted, isFalse);
    });

    test('Dynamic score prioritizes overdue and quick-win tasks', () {
      final ref = DateTime(2026, 11, 6, 12, 0);

      // Overdue P1 task
      final overdueTask = TaskItem(
        id: 't-1',
        title: 'Emergency Bugfix',
        priority: TaskPriority.urgentImportant,
        estimatedMinutes: 20, // Quick-win
        dueAt: DateTime(2026, 11, 6, 10, 0), // 2 hours overdue
        createdAt: ref,
      );

      // Normal P4 low priority task due tomorrow
      final lowTask = TaskItem(
        id: 't-2',
        title: 'Browse Wallpapers',
        priority: TaskPriority.neither,
        estimatedMinutes: 60,
        dueAt: DateTime(2026, 11, 7, 18, 0),
        createdAt: ref,
      );

      final scoreOverdue = overdueTask.computeDynamicScore(ref);
      final scoreLow = lowTask.computeDynamicScore(ref);

      // Overdue base(100) + overdue(80) + quickwin(10) = 190
      expect(scoreOverdue, 190.0);
      // Low base(25) + due tomorrow(15) = 40
      expect(scoreLow, 40.0);
      expect(scoreOverdue > scoreLow, isTrue);
    });
  });

  group('AlarmItem Domain Model Tests', () {
    test('Calculates next occurrence for repeating weekdays', () {
      // Friday Nov 6, 2026 at 10:00 AM (Friday is weekday 5)
      final fridayMorning = DateTime(2026, 11, 6, 10, 0);

      final mondayWednesdayAlarm = AlarmItem(
        id: 'alm-1',
        hour: 7,
        minute: 30,
        label: 'Morning Workout',
        repeatDays: const [1, 3], // Mon & Wed
        challengeType: AlarmChallengeType.math,
        difficulty: ChallengeDifficulty.medium,
      );

      final next = mondayWednesdayAlarm.getNextTrigger(fridayMorning);
      // Next Mon is Nov 9, 2026 (weekday 1)
      expect(next.weekday, 1);
      expect(next.hour, 7);
      expect(next.minute, 30);
      expect(next.isAfter(fridayMorning), isTrue);
    });

    test('AlarmItem serialization preserves challenge properties', () {
      const alarm = AlarmItem(
        id: 'alm-qr',
        hour: 6,
        minute: 0,
        label: 'Bathroom QR Alarm',
        challengeType: AlarmChallengeType.qrScan,
        difficulty: ChallengeDifficulty.hard,
        qrHash: 'sha256_bathroom_sink_123',
        minSteps: 30,
      );

      final json = alarm.toJson();
      final restored = AlarmItem.fromJson(json);

      expect(restored.challengeType, AlarmChallengeType.qrScan);
      expect(restored.qrHash, 'sha256_bathroom_sink_123');
      expect(restored.timeFormatted, '6:00 AM');
    });
  });

  group('DailyPlanBlock & Routine Tests', () {
    test('Time block calculates correct duration and formatted string', () {
      const block = DailyPlanBlock(
        id: 'dpb-1',
        title: 'Deep Coding Session',
        startHour: 9,
        startMinute: 15,
        endHour: 11,
        endMinute: 45,
        category: 'Study',
      );

      expect(block.durationMinutes, 150);
      expect(block.timeRangeFormatted, '9:15 AM - 11:45 AM');
    });

    test('DayRoutine totals steps duration correctly', () {
      const routine = DayRoutine(
        id: 'r-1',
        name: 'Morning Power Hour',
        steps: [
          RoutineStep(id: 's-1', title: 'Hydrate & Stretch', durationMinutes: 10),
          RoutineStep(id: 's-2', title: 'Review Daybook Briefing', durationMinutes: 15),
          RoutineStep(id: 's-3', title: 'Top 1 Priority Task', durationMinutes: 35),
        ],
      );

      expect(routine.totalMinutes, 60);
      expect(routine.steps.length, 3);
    });
  });

  group('PersonalMemory & ChatMessage Tests', () {
    test('Memory model handles serialization and pinning', () {
      final mem = PersonalMemory(
        id: 'mem-1',
        key: 'preferred_wake_time',
        value: '6:30 AM',
        kind: MemoryKind.preference,
        isPinned: true,
        createdAt: DateTime(2026, 11, 1),
      );

      final json = mem.toJson();
      final restored = PersonalMemory.fromJson(json);

      expect(restored.key, 'preferred_wake_time');
      expect(restored.value, '6:30 AM');
      expect(restored.kind, MemoryKind.preference);
      expect(restored.isPinned, isTrue);
    });

    test('ChatMessage supports assistant tool invocation payloads', () {
      final msg = ChatMessage(
        id: 'c-1',
        sender: MessageSender.assistant,
        content: 'I have scheduled your deep work session.',
        timestamp: DateTime(2026, 11, 6, 14, 0),
        toolInvocation: const AssistantToolInvocation(
          toolName: 'plan_day',
          parameters: {'start': '09:00', 'duration': 90, 'title': 'Deep Work'},
          resultSummary: 'Block added to daily planner.',
          isExecuted: true,
        ),
      );

      final json = msg.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.isUser, isFalse);
      expect(restored.toolInvocation?.toolName, 'plan_day');
      expect(restored.toolInvocation?.isExecuted, isTrue);
    });
  });

  group('Weather & Sky Engine Model Tests', () {
    test('Calculates sky phase relative to solar events', () {
      // Sunrise at 6:00, Sunset at 18:00 (6:00 PM)
      final weather = WeatherState(
        cityName: 'Dhaka',
        temperatureC: 28.0,
        sunriseHour: 6,
        sunriseMinute: 0,
        sunsetHour: 18,
        sunsetMinute: 0,
        lastUpdated: DateTime.now(),
      );

      // 5:30 AM -> 30 min before sunrise -> dawn
      expect(weather.getSkyPhase(DateTime(2026, 11, 6, 5, 30)), SkyPhase.dawn);
      // 9:00 AM -> morning
      expect(weather.getSkyPhase(DateTime(2026, 11, 6, 9, 0)), SkyPhase.morning);
      // 14:00 (2 PM) -> afternoon
      expect(weather.getSkyPhase(DateTime(2026, 11, 6, 14, 0)), SkyPhase.afternoon);
      // 17:30 (5:30 PM) -> 30 min before sunset -> goldenHour
      expect(weather.getSkyPhase(DateTime(2026, 11, 6, 17, 30)), SkyPhase.goldenHour);
      // 18:15 (6:15 PM) -> 15 min after sunset -> dusk
      expect(weather.getSkyPhase(DateTime(2026, 11, 6, 18, 15)), SkyPhase.dusk);
      // 23:00 (11:00 PM) -> night
      expect(weather.getSkyPhase(DateTime(2026, 11, 6, 23, 0)), SkyPhase.night);
    });
  });
}
