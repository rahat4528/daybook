import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/data/repositories/entries_repository.dart';
import 'package:daybook/domain/models/day_page.dart';
import 'package:daybook/domain/models/focus_session.dart';
import 'package:daybook/domain/models/habit_item.dart';
import 'package:daybook/domain/models/journal_entry.dart';
import 'package:daybook/domain/services/focus_service.dart';
import 'package:daybook/domain/services/habit_service.dart';
import 'package:daybook/domain/services/wellness_service.dart';
import 'package:daybook/presentation/screens/focus_screen.dart';
import 'package:daybook/presentation/screens/habits_screen.dart';
import 'package:daybook/presentation/widgets/wellness_modal.dart';

void main() {
  group('PART 7 — Habits Engine & Streak Freeze Tests', () {
    late HabitService habitService;
    late EntriesRepository entriesRepo;

    setUp(() {
      habitService = HabitService();
      entriesRepo = EntriesRepository();
    });

    test('Habit toggles completion and increments streak', () {
      final habit = HabitItem(
        id: 'h_test_1',
        name: 'Drink Water',
        nameBn: 'পানি পান',
        targetValue: 2000,
        unit: 'ml',
        currentStreak: 0,
        createdAt: DateTime.now(),
      );
      habitService.saveHabit(habit);

      final today = DateTime.now();
      final dayKey = DayPageModel.formatDayKey(today);

      expect(habitService.isHabitCompleted('h_test_1', dayKey), isFalse);

      // Toggle ON
      final res = habitService.toggleHabit('h_test_1', date: today, entriesRepo: entriesRepo);
      expect(res, isTrue);
      expect(habitService.isHabitCompleted('h_test_1', dayKey), isTrue);

      final updated = habitService.getHabit('h_test_1')!;
      expect(updated.currentStreak, equals(1));
      expect(updated.longestStreak, equals(1));

      // Verify event log entry
      final page = entriesRepo.getDayPage(dayKey);
      expect(page.entries.any((e) => e.type == EntryType.habitLogged), isTrue);

      // Toggle OFF
      final resOff = habitService.toggleHabit('h_test_1', date: today, entriesRepo: entriesRepo);
      expect(resOff, isFalse);
      expect(habitService.isHabitCompleted('h_test_1', dayKey), isFalse);
      expect(habitService.getHabit('h_test_1')!.currentStreak, equals(0));
    });

    test('Earns 1 freeze token every 7 consecutive days (capped at 2)', () {
      final habit = HabitItem(
        id: 'h_streak_7',
        name: 'Morning Read',
        nameBn: 'বই পড়া',
        currentStreak: 6, // 1 day away from earning a token
        freezeTokens: 0,
        createdAt: DateTime.now(),
      );
      habitService.saveHabit(habit);

      habitService.toggleHabit('h_streak_7', date: DateTime.now(), entriesRepo: entriesRepo);

      final after7 = habitService.getHabit('h_streak_7')!;
      expect(after7.currentStreak, equals(7));
      expect(after7.freezeTokens, equals(1)); // Earned 1st freeze token

      // Fast-forward to 13-day streak with 1 token
      habitService.saveHabit(after7.copyWith(currentStreak: 13));
      habitService.toggleHabit('h_streak_7', date: DateTime.now().add(const Duration(days: 1)), entriesRepo: entriesRepo);

      final after14 = habitService.getHabit('h_streak_7')!;
      expect(after14.currentStreak, equals(14));
      expect(after14.freezeTokens, equals(2)); // Earned 2nd token (cap reached)

      // 21 days streak should still cap at 2 tokens
      habitService.saveHabit(after14.copyWith(currentStreak: 20));
      habitService.toggleHabit('h_streak_7', date: DateTime.now().add(const Duration(days: 2)), entriesRepo: entriesRepo);
      expect(habitService.getHabit('h_streak_7')!.freezeTokens, equals(2));
    });

    test('Consumes freeze token automatically when a day is missed', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey = DayPageModel.formatDayKey(yesterday);

      final habit = HabitItem(
        id: 'h_freeze_consume',
        name: 'Daily Meditation',
        nameBn: 'ধ্যান',
        currentStreak: 10,
        freezeTokens: 1,
        lastCompletedDayKey: DayPageModel.formatDayKey(today.subtract(const Duration(days: 2))),
        createdAt: today.subtract(const Duration(days: 15)),
      );
      habitService.saveHabit(habit);

      // Yesterday was missed, evaluate continuity
      habitService.evaluateStreakContinuity(today, entriesRepo);

      final evaluated = habitService.getHabit('h_freeze_consume')!;
      expect(evaluated.freezeTokens, equals(0)); // Token consumed
      expect(evaluated.currentStreak, equals(10)); // Streak preserved!
      expect(evaluated.lastCompletedDayKey, equals(yesterdayKey));

      // If missed another day with 0 tokens remaining
      habitService.evaluateStreakContinuity(today.add(const Duration(days: 2)), entriesRepo);
      expect(habitService.getHabit('h_freeze_consume')!.currentStreak, equals(0)); // Reset!
    });

    test('Generates 30-day heatmap with valid opacity tiers (0, 1, 4)', () {
      final habit = HabitItem(
        id: 'h_heat',
        name: 'Workout',
        nameBn: 'ব্যায়াম',
        createdAt: DateTime.now(),
      );
      habitService.saveHabit(habit);

      final today = DateTime.now();
      habitService.toggleHabit('h_heat', date: today, entriesRepo: entriesRepo);

      final heatmap = habitService.getHeatmap30Days('h_heat', today);
      expect(heatmap.length, equals(30));
      expect(heatmap.last, equals(4)); // 100% opacity today
      expect(heatmap.first, equals(0)); // 0% opacity for 29 days ago
    });
  });

  group('PART 7 — Focus Zone & Flip-to-Focus Engine Tests', () {
    late FocusService focusService;
    late EntriesRepository entriesRepo;

    setUp(() {
      focusService = FocusService();
      entriesRepo = EntriesRepository();
    });

    test('Focus timer state machine and interruption tracking', () {
      focusService.configureSession(
        taskTitle: 'Code Dart Architecture',
        targetMinutes: 25,
        soundscape: FocusSoundscape.rainOnTinRoof,
      );

      expect(focusService.state, equals(FocusState.idle));
      expect(focusService.targetSeconds, equals(1500));
      expect(focusService.timeFormatted, equals('25:00'));

      focusService.start();
      expect(focusService.state, equals(FocusState.running));

      focusService.pause();
      expect(focusService.state, equals(FocusState.paused));
      expect(focusService.interruptions, equals(1));

      focusService.resume();
      expect(focusService.state, equals(FocusState.running));

      final session = focusService.completeSession(entriesRepo: entriesRepo);
      expect(session.taskTitle, equals('Code Dart Architecture'));
      expect(session.interruptions, equals(1));
      expect(session.qualityScore, lessThan(1.0));

      final dayKey = DayPageModel.formatDayKey(DateTime.now());
      final page = entriesRepo.getDayPage(dayKey);
      expect(page.entries.any((e) => e.type == EntryType.focusSession), isTrue);
    });

    test('Flip-to-Focus detector starts timer face-down and pauses when picked up', () {
      focusService.configureSession(targetMinutes: 25);
      focusService.isFlipToFocusEnabled = true;

      // 1. Phone face down on desk (Z = -9.8 m/s²)
      final isFaceDown = focusService.evaluateAccelerometer(x: 0.1, y: 0.2, z: -9.8);
      expect(isFaceDown, isTrue);
      expect(focusService.state, equals(FocusState.running));

      // 2. Phone picked up (Z = +9.8 m/s²)
      final isPickedUp = focusService.evaluateAccelerometer(x: 0.5, y: 1.0, z: 9.8);
      expect(isPickedUp, isFalse);
      expect(focusService.state, equals(FocusState.paused));
      expect(focusService.interruptions, equals(1));
    });
  });

  group('PART 7 — Wellness Service & Check-in Tests', () {
    late WellnessService wellnessService;
    late EntriesRepository entriesRepo;

    setUp(() {
      wellnessService = WellnessService();
      entriesRepo = EntriesRepository();
    });

    test('Logs mood and energy ratings into single event log', () {
      final log = wellnessService.logCheckin(
        moodScore: 4,
        energyScore: 5,
        tags: ['Sleep', 'Work'],
        reflection: 'Strong momentum after morning walk',
        entriesRepo: entriesRepo,
      );

      expect(log.moodScore, equals(4));
      expect(log.energyScore, equals(5));
      expect(log.tags, contains('Sleep'));

      final dayKey = DayPageModel.formatDayKey(DateTime.now());
      final savedLog = wellnessService.getLogForDay(dayKey);
      expect(savedLog, isNotNull);

      final page = entriesRepo.getDayPage(dayKey);
      final entry = page.entries.firstWhere((e) => e.type == EntryType.moodEnergyCheckin);
      expect(entry.mood, equals(4));
      expect(entry.energy, equals(5));
    });
  });

  group('PART 7 — Presentation Screens Smoke Tests', () {
    late HabitService habitService;
    late FocusService focusService;
    late WellnessService wellnessService;
    late EntriesRepository entriesRepo;

    setUp(() {
      habitService = HabitService();
      focusService = FocusService();
      wellnessService = WellnessService();
      entriesRepo = EntriesRepository();
    });

    testWidgets('HabitsScreen renders habit cards, streak badges, and toggles', (tester) async {
      habitService.saveHabit(
        HabitItem(
          id: 'h_ui_1',
          name: 'Daily Reading',
          nameBn: 'দৈনিক বই পড়া',
          currentStreak: 4,
          freezeTokens: 1,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: HabitsScreen(
            isBangla: false,
            habitService: habitService,
            entriesRepo: entriesRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('HABITS & STREAKS'), findsOneWidget);
      expect(find.text('Daily Reading'), findsOneWidget);
      expect(find.text('Streak: 4 days'), findsOneWidget);
      expect(find.text('❄️'), findsOneWidget); // Freeze token badge

      // Tap toggle button
      final checkIcon = find.byIcon(Icons.check);
      expect(checkIcon, findsOneWidget);
      await tester.tap(checkIcon);
      await tester.pumpAndSettle();

      expect(habitService.getHabit('h_ui_1')!.currentStreak, equals(5));
    });

    testWidgets('FocusScreen renders dial, soundscape trigger, and controls', (tester) async {
      focusService.configureSession(taskTitle: 'Solve Algorithm Problem', targetMinutes: 25);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FocusScreen(
            isBangla: false,
            focusService: focusService,
            entriesRepo: entriesRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FOCUS ZONE'), findsOneWidget);
      expect(find.text('Solve Algorithm Problem'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('START FOCUS'), findsOneWidget);

      // Start session
      await tester.tap(find.text('START FOCUS'));
      await tester.pumpAndSettle();

      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('COMPLETE'), findsOneWidget);

      // Clean up timer before tear-down
      focusService.reset();
      await tester.pump();
    });

    testWidgets('WellnessModal renders mood/energy selectors and saves', (tester) async {
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    WellnessModal.show(
                      ctx,
                      isBangla: false,
                      wellnessService: wellnessService,
                      entriesRepo: entriesRepo,
                      onSaved: () => saved = true,
                    );
                  },
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('MOOD & ENERGY CHECK-IN'), findsOneWidget);
      expect(find.text('COMPLETE CHECK-IN'), findsOneWidget);

      // Save check-in
      await tester.tap(find.text('COMPLETE CHECK-IN'));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
      expect(wellnessService.allLogs.isNotEmpty, isTrue);
    });
  });
}
