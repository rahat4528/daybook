import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/enums/task_priority.dart';
import 'package:daybook/core/enums/core_enums.dart';
import 'package:daybook/domain/models/task_item.dart';
import 'package:daybook/domain/models/daily_plan_block.dart';
import 'package:daybook/domain/models/alarm_item.dart';
import 'package:daybook/domain/services/task_service.dart';
import 'package:daybook/presentation/widgets/sky_canvas.dart';
import 'package:daybook/presentation/widgets/daily_progress_ring.dart';
import 'package:daybook/presentation/widgets/task_card.dart';
import 'package:daybook/presentation/screens/tasks_screen.dart';
import 'package:daybook/presentation/screens/planner_screen.dart';
import 'package:daybook/presentation/screens/alarm_screen.dart';

void main() {
  testWidgets('WeatherSkyBackground renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WeatherSkyBackground(
            phase: SkyPhase.morning,
            condition: WeatherType.clear,
            child: Text('Sky Content'),
          ),
        ),
      ),
    );

    expect(find.text('Sky Content'), findsOneWidget);
    expect(find.byType(WeatherSkyBackground), findsOneWidget);
  });

  testWidgets('DailyProgressRing displays correct fraction and percentage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DailyProgressRing(
            completedTasks: 3,
            totalTasks: 5,
            wakeHour: 6,
            wakeMinute: 30,
            sleepHour: 23,
            sleepMinute: 0,
            currentStreakDays: 7,
          ),
        ),
      ),
    );

    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('7 Day Streak'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget); // 3/5 = 60%
  });

  testWidgets('TaskCard shows title, priority badge and handles toggle tap', (WidgetTester tester) async {
    bool toggled = false;
    final task = TaskItem(
      id: 't-1',
      title: 'Review System Design',
      category: 'Work',
      priority: TaskPriority.urgentImportant,
      estimatedMinutes: 30,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            onToggleComplete: () {
              toggled = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Review System Design'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);

    // Tap checkbox
    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    await tester.pump();

    expect(toggled, isTrue);
  });

  testWidgets('TasksScreen renders tabs and lists tasks', (WidgetTester tester) async {
    final taskService = TaskService();
    taskService.addTask(
      title: 'Active Today Task',
      priority: TaskPriority.urgentImportant,
      dueAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TasksScreen(
          taskService: taskService,
          onDataChanged: () {},
        ),
      ),
    );

    expect(find.text('Task Command Center'), findsOneWidget);
    expect(find.text('Active Today Task'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('PlannerScreen displays planned blocks and auto-plan action', (WidgetTester tester) async {
    final taskService = TaskService();
    const blocks = [
      DailyPlanBlock(
        id: 'b1',
        title: 'Deep Coding',
        startHour: 9,
        startMinute: 0,
        endHour: 10,
        endMinute: 30,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PlannerScreen(
          planBlocks: blocks,
          taskService: taskService,
          onBlocksUpdated: (_) {},
        ),
      ),
    );

    expect(find.text('Daily Time-Block Planner'), findsOneWidget);
    expect(find.text('Deep Coding'), findsOneWidget);
    expect(find.text('9:00 AM - 10:30 AM'), findsOneWidget);
  });

  testWidgets('AlarmScreen lists alarms and test challenge button', (WidgetTester tester) async {
    const alarms = [
      AlarmItem(
        id: 'alm-1',
        hour: 6,
        minute: 45,
        label: 'Early Bird',
        challengeType: AlarmChallengeType.math,
        difficulty: ChallengeDifficulty.medium,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AlarmScreen(
          alarms: alarms,
          onAlarmsUpdated: (_) {},
        ),
      ),
    );

    expect(find.text('Smart Alarms & Challenges'), findsOneWidget);
    expect(find.text('6:45 AM'), findsOneWidget);
    expect(find.text('Early Bird'), findsOneWidget);
    expect(find.text('Test Challenge'), findsOneWidget);
  });
}

