import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/enums/core_enums.dart';
import 'package:daybook/core/enums/task_priority.dart';
import 'package:daybook/domain/models/goal_item.dart';
import 'package:daybook/domain/models/task_item.dart';
import 'package:daybook/domain/models/daily_plan_block.dart';
import 'package:daybook/domain/services/planner_algorithm.dart';
import 'package:daybook/domain/services/weekly_review_service.dart';
import 'package:daybook/domain/services/task_service.dart';
import 'package:daybook/data/repositories/tasks_and_goals_repository.dart';
import 'package:daybook/presentation/screens/planner_screen.dart';
import 'package:daybook/presentation/screens/tasks_screen.dart';

void main() {
  group('PART 3 — Deterministic Scoring & Prioritization Tests', () {
    test('Task dynamic score adheres to Eisenhower weights and deadline proximity', () {
      final now = DateTime(2026, 10, 15, 10, 0);

      // P1 Urgent & Important due in 4 hours
      final p1Task = TaskItem(
        id: 't_p1',
        title: 'Fix Critical Production Crash',
        priority: TaskPriority.urgentImportant,
        estimatedMinutes: 45,
        dueAt: now.add(const Duration(hours: 4)),
        createdAt: now,
      );

      // P2 Important Not Urgent due tomorrow
      final p2Task = TaskItem(
        id: 't_p2',
        title: 'Design Security Threat Model',
        priority: TaskPriority.importantNotUrgent,
        estimatedMinutes: 60,
        dueAt: now.add(const Duration(hours: 24)),
        createdAt: now,
      );

      // P4 Low Priority
      final p4Task = TaskItem(
        id: 't_p4',
        title: 'Organize desktop wallpaper',
        priority: TaskPriority.neither,
        estimatedMinutes: 15,
        createdAt: now,
      );

      final p1Score = p1Task.computeDynamicScore(now);
      final p2Score = p2Task.computeDynamicScore(now);
      final p4Score = p4Task.computeDynamicScore(now);

      // P1 (100 base + 50 due soon) > P2 (75 base + 30 tomorrow) > P4 (25 base + 10 quick win)
      expect(p1Score, greaterThan(p2Score));
      expect(p2Score, greaterThan(p4Score));
    });

    test('"Eat the Frog" algorithm picks the hardest daily focus challenge', () {
      final now = DateTime(2026, 10, 15);

      final tasks = [
        TaskItem(
          id: 't_easy',
          title: 'Reply to client email',
          priority: TaskPriority.neither,
          estimatedMinutes: 10,
          createdAt: now,
        ),
        TaskItem(
          id: 't_medium',
          title: 'Refactor database repository',
          priority: TaskPriority.importantNotUrgent,
          estimatedMinutes: 45,
          createdAt: now,
        ),
        TaskItem(
          id: 't_hardest_frog',
          title: 'Architect Native Kotlin Alarm Foreground Engine',
          priority: TaskPriority.urgentImportant,
          estimatedMinutes: 90,
          createdAt: now,
        ),
      ];

      final frog = PlannerAlgorithm.pickEatTheFrog(tasks);
      expect(frog, isNotNull);
      expect(frog!.id, 't_hardest_frog');
    });
  });

  group('PART 3 — Recurrence Engine Tests', () {
    test('Daily, Weekly, and Monthly recurrence date calculations', () {
      final base = DateTime(2026, 10, 10, 9, 0);

      final daily = TaskItem(
        id: 'rec_daily',
        title: 'Daily Meditation',
        recurrence: RecurrenceType.daily,
        dueAt: base,
        createdAt: base,
      );
      expect(daily.computeNextDueDate(base), DateTime(2026, 10, 11, 9, 0));

      final weekly = TaskItem(
        id: 'rec_weekly',
        title: 'Weekly Sprint Planning',
        recurrence: RecurrenceType.weekly,
        dueAt: base,
        createdAt: base,
      );
      expect(weekly.computeNextDueDate(base), DateTime(2026, 10, 17, 9, 0));

      final monthly = TaskItem(
        id: 'rec_monthly',
        title: 'Monthly Financial Audit',
        recurrence: RecurrenceType.monthly,
        dueAt: base,
        createdAt: base,
      );
      expect(monthly.computeNextDueDate(base), DateTime(2026, 11, 10, 9, 0));
    });

    test('Recurring task auto-generates next instance upon completion', () {
      final repo = TasksAndGoalsRepository();
      final now = DateTime(2026, 10, 15, 8, 0);

      final task = TaskItem(
        id: 'task_hab_recur',
        title: 'Morning 20m Reflection',
        recurrence: RecurrenceType.daily,
        dueAt: now,
        createdAt: now,
      );

      repo.addTask(task);
      expect(repo.getAllTasks().length, 1);

      // Complete recurring task
      final success = repo.toggleTask(task.id);
      expect(success, true);

      // Current task marked completed, next day instance spawned
      final all = repo.getAllTasks();
      expect(all.length, 2);
      expect(all.any((t) => t.isCompleted), true);
      expect(all.any((t) => !t.isCompleted && t.title == task.title), true);
    });
  });

  group('PART 3 — Dependency Graph & Blocker Constraints Tests', () {
    test('Blocked task cannot be completed until prerequisite is resolved', () {
      final repo = TasksAndGoalsRepository();
      final now = DateTime.now();

      final blocker = TaskItem(
        id: 'task_prereq',
        title: 'Draft API Contract',
        createdAt: now,
      );

      final dependent = TaskItem(
        id: 'task_api_client',
        title: 'Implement API Client',
        blockedByTaskIds: ['task_prereq'],
        createdAt: now,
      );

      repo.addTask(blocker);
      repo.addTask(dependent);

      // Attempt to complete dependent task while blocker is pending
      expect(repo.canCompleteTask('task_api_client'), false);
      final toggled = repo.toggleTask('task_api_client');
      expect(toggled, false); // Blocked!

      // Now complete the prerequisite blocker
      repo.toggleTask('task_prereq');
      expect(repo.canCompleteTask('task_api_client'), true);

      // Now dependent task can be completed cleanly
      final completedNow = repo.toggleTask('task_api_client');
      expect(completedNow, true);
    });
  });

  group('PART 3 — Daily Planner Engine & Energy-Aware Scheduling', () {
    test('Planner fits tasks deterministically and detects overload', () {
      final now = DateTime.now();

      final tasks = [
        TaskItem(
          id: 'plan_t1',
          title: 'Deep Architecture Writing',
          priority: TaskPriority.urgentImportant,
          estimatedMinutes: 120,
          createdAt: now,
        ),
        TaskItem(
          id: 'plan_t2',
          title: 'Code Review Pull Requests',
          priority: TaskPriority.importantNotUrgent,
          estimatedMinutes: 60,
          createdAt: now,
        ),
        TaskItem(
          id: 'plan_t3',
          title: 'Draft Release Notes',
          priority: TaskPriority.neither,
          estimatedMinutes: 30,
          createdAt: now,
        ),
      ];

      final result = PlannerAlgorithm.fitTasksIntoDay(
        tasks: tasks,
        wakeHour: 8,
        wakeMinute: 0,
        sleepHour: 20, // 12 hours window = 720 minutes
        sleepMinute: 0,
      );

      expect(result.blocks.isNotEmpty, true);
      expect(result.isOverloaded, false);
      expect(result.frogTask?.id, 'plan_t1');

      // Test overload scenario (wake 8pm, sleep 9pm = 60 mins available for 210 mins of tasks)
      final overloadedResult = PlannerAlgorithm.fitTasksIntoDay(
        tasks: tasks,
        wakeHour: 20,
        wakeMinute: 0,
        sleepHour: 21,
        sleepMinute: 0,
      );

      expect(overloadedResult.isOverloaded, true);
      expect(overloadedResult.deficitMinutes, greaterThan(0));
    });

    test('"Reset My Day" preserves past blocks and reshuffles remaining tasks', () {
      final now = DateTime(2026, 10, 15, 14, 0); // 2:00 PM

      final blocks = [
        const DailyPlanBlock(
          id: 'b_past_morning',
          title: 'Morning Awakening',
          startHour: 7,
          startMinute: 0,
          endHour: 8,
          endMinute: 0,
          isCompleted: true,
        ),
        const DailyPlanBlock(
          id: 'b_uncompleted_morning',
          title: 'Missed Deep Work Session',
          startHour: 9,
          startMinute: 0,
          endHour: 11,
          endMinute: 0,
          taskId: 't_missed',
          isCompleted: false,
        ),
      ];

      final tasks = [
        TaskItem(
          id: 't_missed',
          title: 'Missed Deep Work Session',
          estimatedMinutes: 60,
          createdAt: now,
        ),
      ];

      final reshuffled = PlannerAlgorithm.resetMyDay(
        currentBlocks: blocks,
        tasks: tasks,
        now: now,
        sleepHour: 23,
      );

      expect(reshuffled.isNotEmpty, true);
      // Completed morning block preserved
      expect(reshuffled.any((b) => b.id == 'b_past_morning'), true);
      // Remaining task rescheduled starting from after 2:00 PM
      final rescheduledBlock = reshuffled.firstWhere((b) => b.taskId == 't_missed');
      expect(rescheduledBlock.startHour, greaterThanOrEqualTo(14));
    });
  });

  group('PART 3 — Goals, Milestones & Weekly Review Tests', () {
    test('Goal progress percentage and achievement status', () {
      final now = DateTime.now();
      final goal = GoalItem(
        id: 'goal_test',
        title: 'Launch DayBook v1.0',
        targetDate: now.add(const Duration(days: 30)),
        createdAt: now,
        milestones: const [
          MilestoneItem(id: 'm1', goalId: 'goal_test', title: 'Part 1 UI', isCompleted: true),
          MilestoneItem(id: 'm2', goalId: 'goal_test', title: 'Part 2 Book', isCompleted: true),
          MilestoneItem(id: 'm3', goalId: 'goal_test', title: 'Part 3 Tasks', isCompleted: false),
        ],
      );

      expect(goal.progressPercentage, closeTo(0.666, 0.01));
      expect(goal.isAchieved, false);

      final achievedGoal = goal.copyWith(
        milestones: goal.milestones.map((m) => m.copyWith(isCompleted: true)).toList(),
      );
      expect(achievedGoal.progressPercentage, 1.0);
      expect(achievedGoal.isAchieved, true);
    });

    test('Weekly Review calculates completion rate and handles task carry-over', () {
      final now = DateTime.now();
      final tasks = [
        TaskItem(id: 't1', title: 'Task 1', status: TaskStatus.completed, createdAt: now),
        TaskItem(id: 't2', title: 'Task 2', status: TaskStatus.completed, createdAt: now),
        TaskItem(id: 't3', title: 'Task 3', status: TaskStatus.pending, dueAt: now, createdAt: now),
      ];

      final review = WeeklyReviewService.generateWeeklyReview(tasks);
      expect(review.completedTasksCount, 2);
      expect(review.pendingTasksCount, 1);
      expect(review.completionRate, closeTo(0.666, 0.01));
      expect(review.carryOverTasks.length, 1);

      // Rollover incomplete tasks 7 days ahead
      final rolledOver = WeeklyReviewService.rolloverIncompleteTasks(tasks, daysAhead: 7);
      final rolledTask = rolledOver.firstWhere((t) => t.id == 't3');
      expect(rolledTask.dueAt!.isAfter(now.add(const Duration(days: 6))), true);
    });
  });

  group('PART 3 — Presentation Smoke Tests', () {
    testWidgets('PlannerScreen renders header, auto-plan, and reset day buttons', (tester) async {
      final taskService = TaskService();
      taskService.addTask(title: 'Plan Test Task', estimatedMinutes: 30);

      await tester.pumpWidget(
        MaterialApp(
          home: PlannerScreen(
            planBlocks: const [],
            taskService: taskService,
            onBlocksUpdated: (_) {},
            isBangla: false,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Daily Time-Block Planner'), findsOneWidget);
      expect(find.text('Total Planned Time: 0h 0m'), findsOneWidget);
    });

    testWidgets('TasksScreen renders tabs and lists tasks', (tester) async {
      final taskService = TaskService();
      taskService.addTask(title: 'Active Task 1', estimatedMinutes: 25);

      await tester.pumpWidget(
        MaterialApp(
          home: TasksScreen(
            taskService: taskService,
            onDataChanged: () {},
            isBangla: false,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Task Command Center'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Active Task 1'), findsWidgets);
    });
  });
}
