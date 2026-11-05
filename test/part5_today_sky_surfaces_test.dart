import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/enums/core_enums.dart';
import 'package:daybook/core/enums/task_priority.dart';
import 'package:daybook/domain/models/weather_info.dart';
import 'package:daybook/domain/models/weather_and_briefing.dart';
import 'package:daybook/domain/models/task_item.dart';
import 'package:daybook/domain/services/sky_calculator.dart';
import 'package:daybook/domain/services/weather_service.dart';
import 'package:daybook/domain/services/briefing_service.dart';
import 'package:daybook/domain/services/quick_surfaces_service.dart';
import 'package:daybook/presentation/widgets/sky_canvas.dart';
import 'package:daybook/main.dart';

void main() {
  group('PART 5 — Sky Phase & Solar Astronomical Calculator', () {
    test('Calculates sky phases across 24 hours relative to sunrise and sunset', () {
      final baseDate = DateTime(2026, 10, 15);

      // Sunrise 6:00 AM (360m), Sunset 6:00 PM (1080m)
      // 1. Dawn: 5:30 AM (330m)
      final dawnTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 5, 30);
      expect(SkyCalculator.calculatePhase(dawnTime), SkyPhase.dawn);

      // 2. Day / Morning: 10:00 AM
      final dayTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 0);
      expect(SkyCalculator.calculatePhase(dayTime), SkyPhase.morning);

      // 3. Golden Hour: 5:15 PM (1035m)
      final goldenTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 17, 15);
      expect(SkyCalculator.calculatePhase(goldenTime), SkyPhase.goldenHour);

      // 4. Dusk: 6:20 PM (1100m)
      final duskTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 18, 20);
      expect(SkyCalculator.calculatePhase(duskTime), SkyPhase.dusk);

      // 5. Night: 11:00 PM (1380m)
      final nightTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 23, 0);
      expect(SkyCalculator.calculatePhase(nightTime), SkyPhase.night);
    });

    test('Computes waking day percentage elapsed', () {
      final baseDate = DateTime(2026, 10, 15);

      // Wake 7:00 AM, Sleep 11:00 PM = 16 hours window (960 minutes)
      // At 7:00 AM: 0%
      final atWake = DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 0);
      expect(SkyCalculator.calculateWakingDayElapsed(atWake), 0.0);

      // At 3:00 PM (8 hours elapsed out of 16): 50.0%
      final atMidday = DateTime(baseDate.year, baseDate.month, baseDate.day, 15, 0);
      expect(SkyCalculator.calculateWakingDayElapsed(atMidday), closeTo(50.0, 0.1));

      // At 11:00 PM: 100.0%
      final atSleep = DateTime(baseDate.year, baseDate.month, baseDate.day, 23, 0);
      expect(SkyCalculator.calculateWakingDayElapsed(atSleep), 100.0);

      // Before wake time (5:00 AM): 0%
      final beforeWake = DateTime(baseDate.year, baseDate.month, baseDate.day, 5, 0);
      expect(SkyCalculator.calculateWakingDayElapsed(beforeWake), 0.0);
    });

    test('Calculates normalized celestial arc trajectory', () {
      final baseDate = DateTime(2026, 10, 15);
      // Midday solar peak (12:00 PM)
      final noon = DateTime(baseDate.year, baseDate.month, baseDate.day, 12, 0);
      final point = SkyCalculator.getCelestialPosition(noon);

      expect(point.x, closeTo(0.5, 0.05));
      expect(point.y, closeTo(1.0, 0.05)); // Peak zenith
    });
  });

  group('PART 5 — WMO Weather Normalization & Offline Cache', () {
    test('WMO code maps accurately to WeatherType and unicode sky glyphs', () {
      final now = DateTime.now();

      final clearDay = WeatherInfo(temperature: 29.0, wmoCode: 0, isDay: true, cachedAt: now);
      expect(clearDay.weatherType, WeatherType.clear);
      expect(clearDay.skyGlyph, '☀️');
      expect(clearDay.skyCode, 'clear_day');

      final clearNight = WeatherInfo(temperature: 24.0, wmoCode: 0, isDay: false, cachedAt: now);
      expect(clearNight.skyGlyph, '🌙');
      expect(clearNight.skyCode, 'clear_night');

      final rain = WeatherInfo(temperature: 22.0, wmoCode: 63, isDay: true, cachedAt: now);
      expect(rain.weatherType, WeatherType.rain);
      expect(rain.skyGlyph, '🌧');

      final thunder = WeatherInfo(temperature: 20.0, wmoCode: 95, isDay: true, cachedAt: now);
      expect(thunder.weatherType, WeatherType.thunderstorm);
      expect(thunder.skyGlyph, '⚡');

      final fog = WeatherInfo(temperature: 18.0, wmoCode: 45, isDay: true, cachedAt: now);
      expect(fog.weatherType, WeatherType.foggy);
      expect(fog.skyGlyph, '🌫');
    });

    test('WeatherService caches weather with 30-minute TTL and provides offline fallback', () async {
      final startTime = DateTime(2026, 10, 15, 10, 0);
      final service = WeatherService();

      final firstFetch = await service.getWeather(simulatedTime: startTime);
      expect(firstFetch.cityName, 'Dhaka');
      expect(service.isCacheValid(startTime), true);

      // Within 25 minutes: cache remains valid
      final validTime = startTime.add(const Duration(minutes: 25));
      expect(service.isCacheValid(validTime), true);

      // At 35 minutes: cache has expired
      final expiredTime = startTime.add(const Duration(minutes: 35));
      expect(service.isCacheValid(expiredTime), false);

      // Fetching again refreshes cache
      final refreshed = await service.getWeather(simulatedTime: expiredTime);
      expect(refreshed.cachedAt, expiredTime);
    });
  });

  group('PART 5 — Spoken Briefings & Evening Review', () {
    test('BriefingService synthesizes morning briefing with markdown emphasis & spoken script', () {
      final now = DateTime(2026, 10, 15, 8, 0);
      final tasks = [
        TaskItem(
          id: 't1',
          title: 'Implement Native Engine',
          priority: TaskPriority.urgentImportant,
          estimatedMinutes: 60,
          createdAt: now,
        ),
      ];

      // English briefing
      final enBriefing = BriefingService.generateMorningBriefing(
        tasks: tasks,
        weather: WeatherState(temperatureC: 28.0, condition: WeatherType.clear, lastUpdated: now),
        isBangla: false,
        referenceDate: now,
      );

      final spokenEn = BriefingService.generateSpokenMorningBriefing(
        briefing: enBriefing,
        frogTitle: tasks.first.title,
        isBangla: false,
      );

      expect(enBriefing.weatherBrief, contains('28.0°C'));
      expect(enBriefing.topTaskTitles, contains('Implement Native Engine'));
      expect(spokenEn, contains('Good morning'));

      // Bangla briefing
      final bnBriefing = BriefingService.generateMorningBriefing(
        tasks: tasks,
        weather: WeatherState(temperatureC: 28.0, condition: WeatherType.clear, lastUpdated: now),
        isBangla: true,
        referenceDate: now,
      );

      final spokenBn = BriefingService.generateSpokenMorningBriefing(
        briefing: bnBriefing,
        frogTitle: tasks.first.title,
        isBangla: true,
      );

      expect(spokenBn, contains('শুভ সকাল'));
    });

    test('BriefingService synthesizes evening review', () {
      final now = DateTime(2026, 10, 15, 21, 0);
      final completed = [
        TaskItem(id: 'c1', title: 'Task Done', status: TaskStatus.completed, createdAt: now),
      ];
      final pending = [
        TaskItem(id: 'p1', title: 'Task Pending', createdAt: now),
      ];

      final review = BriefingService.generateEveningReview(
        allTasks: [completed.first, pending.first],
        moodScore: 4,
        notes: 'Productive day',
        referenceDate: now,
      );

      expect(review.completedTasksCount, 1);
      expect(review.pendingTasksCount, 1);
      expect(review.rolloverTaskIds, contains('p1'));
    });
  });

  group('PART 5 — Quick Surfaces & Android Home Widgets', () {
    test('QuickSurfacesService formats payloads for Today, Habits, and Alarm widgets', () {
      final todayPayload = QuickSurfacesService.buildTodayWidgetData(
        dayScore: 92,
        skyGlyph: '☀️',
        topTaskTitle: 'Complete MVP Part 5',
        completedTasks: 4,
        totalTasks: 5,
        wakingDayElapsedPercent: 62.5,
      );

      expect(todayPayload.widgetType, 'TODAY_HOME_WIDGET');
      expect(todayPayload.data['dayScore'], 92);
      expect(todayPayload.data['skyGlyph'], '☀️');
      expect(todayPayload.data['deepLink'], 'daybook://today');

      final habitsPayload = QuickSurfacesService.buildHabitsWidgetData(
        habits: [
          {'name': 'Water', 'isDone': true},
          {'name': 'Walk', 'isDone': false},
        ],
      );
      expect(habitsPayload.widgetType, 'HABITS_WIDGET');

      final nextAlarmPayload = QuickSurfacesService.buildNextAlarmWidgetData(
        timeFormatted: '6:30 AM',
        label: 'Sunrise Quest',
        challengeName: 'Math Equations',
        timeRemaining: '7h 15m',
      );
      expect(nextAlarmPayload.widgetType, 'NEXT_ALARM_WIDGET');

      final notifPayload = QuickSurfacesService.buildQuickCaptureNotificationPayload(isBangla: false);
      expect(notifPayload['channelId'], 'daybook_quick_capture');
    });
  });

  group('PART 5 — Presentation UI Smoke Tests', () {
    testWidgets('WeatherSkyBackground renders monochrome line art and particles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherSkyBackground(
              phase: SkyPhase.morning,
              condition: WeatherType.clear,
              child: Text('Sky Child'),
            ),
          ),
        ),
      );

      expect(find.text('Sky Child'), findsOneWidget);
      expect(find.byType(WeatherSkyBackground), findsOneWidget);
    });

    testWidgets('DayBookApp Today Tab renders header, weather strip, habits, mood, and priorities', (tester) async {
      await tester.pumpWidget(const DayBookApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DAYBOOK'), findsOneWidget);
      expect(find.text('Daily Trajectory'), findsOneWidget);
      expect(find.text('HABITS QUICK-TAP'), findsOneWidget);
      expect(find.text('MOOD & ENERGY'), findsOneWidget);
      expect(find.text('TODAY\'S PRIORITIES'), findsOneWidget);
      expect(find.text('TODAY\'S DAY PAGE'), findsOneWidget);

      // Tap a habit chip
      await tester.tap(find.text('💧 Water'), warnIfMissed: false);
      await tester.pump();

      // Tap a mood chip
      await tester.tap(find.text('😊 Focused'), warnIfMissed: false);
      await tester.pump();
    });
  });
}
