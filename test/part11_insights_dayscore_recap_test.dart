import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/domain/services/insights_service.dart';
import 'package:daybook/data/repositories/entries_repository.dart';
import 'package:daybook/presentation/screens/insights_screen.dart';

void main() {
  group('Part 11: Deterministic Day Score Algorithm Tests', () {
    late InsightsService insightsService;
    late EntriesRepository entriesRepo;

    setUp(() {
      entriesRepo = EntriesRepository();
      insightsService = InsightsService(entriesRepo: entriesRepo);
    });

    test('Full execution across all 5 pillars yields perfect 100 score and Mastery grade', () {
      final score = insightsService.computeDayScore(
        dayKey: '2026-11-06',
        overrideTasksCompleted: 5,
        overrideTasksTotal: 5, // 30.0 pts
        overrideWakeDiscipline: true, // 20.0 pts
        overrideFocusMinutes: 90, // 25.0 pts
        overrideHabitsDone: 3,
        overrideHabitsTotal: 3, // 15.0 pts
        overrideEveningReview: true, // 10.0 pts
      );

      expect(score.totalScore, equals(100));
      expect(score.taskScore, equals(30.0));
      expect(score.wakeScore, equals(20.0));
      expect(score.focusScore, equals(25.0));
      expect(score.habitScore, equals(15.0));
      expect(score.reflectionScore, equals(10.0));
      expect(score.gradeLabel(isBangla: false), equals('Mastery Day'));
      expect(score.gradeLabel(isBangla: true), contains('অসাধারণ দিন'));
    });

    test('Partial execution computes exact weighted sum and classification', () {
      final score = insightsService.computeDayScore(
        dayKey: '2026-11-05',
        overrideTasksCompleted: 2,
        overrideTasksTotal: 4, // 15.0 pts (50%)
        overrideWakeDiscipline: false, // 10.0 pts (snoozed)
        overrideFocusMinutes: 45, // 12.5 pts (50% of 90m)
        overrideHabitsDone: 1,
        overrideHabitsTotal: 2, // 7.5 pts (50%)
        overrideEveningReview: false, // 0.0 pts
      );

      // 15 + 10 + 12.5 + 7.5 + 0 = 45
      expect(score.totalScore, equals(45));
      expect(score.taskScore, equals(15.0));
      expect(score.wakeScore, equals(10.0));
      expect(score.focusScore, equals(12.5));
      expect(score.habitScore, equals(7.5));
      expect(score.reflectionScore, equals(0.0));
      expect(score.gradeLabel(isBangla: false), equals('Rest & Reset'));
    });

    test('Day Score is saved to single event log with breakdown payload', () {
      final dayKey = '2026-11-04';
      final score = insightsService.computeDayScore(
        dayKey: dayKey,
        overrideTasksCompleted: 4,
        overrideTasksTotal: 5,
        overrideWakeDiscipline: true,
        overrideFocusMinutes: 75,
        overrideHabitsDone: 2,
        overrideHabitsTotal: 3,
        overrideEveningReview: true,
      );

      final logged = entriesRepo.getEntriesForDay(dayKey);
      expect(logged.any((e) => e.payload['action'] == 'day_score_computed'), isTrue);
      expect(score.totalScore, greaterThanOrEqualTo(70));
    });

    test('Heatmap index maps correctly across 5 opacity tiers', () {
      expect(InsightsService.scoreToHeatmapIndex(92), equals(4)); // Tier 4 (100% lime)
      expect(InsightsService.scoreToHeatmapIndex(75), equals(3)); // Tier 3 (75% lime)
      expect(InsightsService.scoreToHeatmapIndex(55), equals(2)); // Tier 2 (50% lime)
      expect(InsightsService.scoreToHeatmapIndex(35), equals(1)); // Tier 1 (25% lime)
      expect(InsightsService.scoreToHeatmapIndex(15), equals(0)); // Tier 0 (dark)
    });
  });

  group('Part 11: Weekly Insights Aggregation Tests', () {
    late InsightsService insightsService;
    late EntriesRepository entriesRepo;

    setUp(() {
      entriesRepo = EntriesRepository();
      insightsService = InsightsService(entriesRepo: entriesRepo);
    });

    test('Computes 7-day rolling metrics and identifies peak energy period', () {
      final weekly = insightsService.computeWeeklyInsights(referenceDate: DateTime(2026, 11, 6));

      expect(weekly.dailyScores.length, equals(7));
      expect(weekly.averageScore, greaterThan(0));
      expect(weekly.totalFocusMinutes, greaterThan(0));
      expect(weekly.totalTasksCompleted, greaterThan(0));
      expect(weekly.totalHabitsCompleted, greaterThan(0));
      expect(weekly.bestDayScore, greaterThan(0));
      expect(weekly.peakEnergyPeriod, contains('Morning'));
    });
  });

  group('Part 11: InsightsScreen Widget Smoke Tests', () {
    late InsightsService insightsService;
    late EntriesRepository entriesRepo;

    setUp(() {
      entriesRepo = EntriesRepository();
      insightsService = InsightsService(entriesRepo: entriesRepo);
    });

    testWidgets('InsightsScreen renders score gauge, 5 pillars, and trajectory chart', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: InsightsScreen(
            isBangla: false,
            insightsService: insightsService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Day Score & Insights'), findsOneWidget);
      expect(find.text('TODAY\'S DAY SCORE'), findsOneWidget);
      expect(find.text('/ 100'), findsOneWidget);
      expect(find.text('5-PILLAR BREAKDOWN'), findsOneWidget);
      expect(find.text('Task Execution'), findsOneWidget);
      expect(find.text('Wake Quest Discipline'), findsOneWidget);
      expect(find.text('Deep Work Focus'), findsOneWidget);
      expect(find.text('Habit Streaks'), findsOneWidget);
      expect(find.text('Nightly Reflection'), findsOneWidget);
      expect(find.text('7-DAY WEEKLY TRAJECTORY'), findsOneWidget);
      expect(find.text('Peak Energy Window'), findsOneWidget);
    });
  });
}
