// Automated Test Suite for the Five Core Features in DayBook
// Covers Trip Countdowns, Link Saver, Habit Notifications, NFC Routines, and BLE Heart Rate.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/domain/models/trip_item.dart';
import 'package:daybook/domain/services/trip_service.dart';
import 'package:daybook/domain/models/saved_link_item.dart';
import 'package:daybook/domain/services/link_saver_service.dart';
import 'package:daybook/domain/models/habit_item.dart';
import 'package:daybook/domain/services/habit_service.dart';
import 'package:daybook/domain/services/habit_notification_service.dart';
import 'package:daybook/domain/services/nfc_routine_service.dart';
import 'package:daybook/domain/models/heart_rate_session.dart';
import 'package:daybook/domain/services/heart_rate_service.dart';
import 'package:daybook/data/repositories/entries_repository.dart';
import 'package:daybook/presentation/screens/trips_screen.dart';
import 'package:daybook/presentation/screens/links_screen.dart';
import 'package:daybook/presentation/screens/nfc_routines_screen.dart';
import 'package:daybook/presentation/screens/heart_rate_screen.dart';

void main() {
  group('PAGE 01 — Trip Countdown & Live Widgets Tests', () {
    test('TripItem computes countdown and formats route accurately', () {
      final departure = DateTime.now().toUtc().add(const Duration(days: 5, hours: 2, minutes: 30));
      final trip = TripItem(
        id: 'trip_test_1',
        originIata: 'DAC',
        destinationIata: 'LHR',
        destinationCity: 'London',
        flightNumber: 'BG201',
        departureTimeUtc: departure,
      );

      expect(trip.routeFormatted, equals('DAC ➔ LHR'));
      expect(trip.isDeparted, isFalse);
      expect(trip.countdownFormatted, contains('5d 2h'));

      final snapshot = trip.toWidgetSnapshot();
      expect(snapshot['route'], equals('DAC ➔ LHR'));
      expect(snapshot['destination'], equals('London'));
      expect(snapshot['statusText'], equals('SCHEDULED'));
    });

    test('TripService manages active trips, widget pinning, and JSON exports', () {
      final entriesRepo = EntriesRepository();
      final tripService = TripService(entriesRepo: entriesRepo);

      final trip2 = TripItem(
        id: 'trip_test_2',
        originIata: 'DAC',
        destinationIata: 'JFK',
        destinationCity: 'New York',
        flightNumber: 'EK202',
        departureTimeUtc: DateTime.now().toUtc().add(const Duration(days: 20)),
        isPinnedForWidget: true,
      );

      tripService.addTrip(trip2);
      expect(tripService.pinnedTrip?.id, equals('trip_test_2'));

      final widgetJson = tripService.exportWidgetJson();
      expect(widgetJson, contains('DAC ➔ JFK'));
      expect(widgetJson, contains('New York'));
    });
  });

  group('PAGE 02 — Link Saver inside Share Sheet Tests', () {
    test('Canonical URL normalization strips UTM and tracking parameters', () {
      const dirtyUrl = 'https://Example.com/article/?utm_source=twitter&utm_medium=social&ref=feed&id=123';
      final clean = SavedLinkItem.normalizeCanonicalUrl(dirtyUrl);
      expect(clean, equals('https://example.com/article?id=123'));

      final domain = SavedLinkItem.extractDomain(clean);
      expect(domain, equals('example.com'));
    });

    test('LinkSaverService captures links, handles tags, and detects duplicates', () {
      final entriesRepo = EntriesRepository();
      final linkService = LinkSaverService(entriesRepo: entriesRepo);

      final saved = linkService.saveLink(
        rawUrl: 'https://flutter.dev/multiplatform',
        title: 'Flutter Multiplatform Development',
        tags: ['flutter', 'dart'],
      );

      expect(saved.domain, equals('flutter.dev'));
      expect(saved.tags, contains('flutter'));

      // Check duplicate detection
      final dup = linkService.findDuplicate('https://flutter.dev/multiplatform?utm_source=google');
      expect(dup, isNotNull);
      expect(dup?.id, equals(saved.id));

      // Test search
      final searchResults = linkService.search(query: 'Multiplatform', tagFilter: 'flutter');
      expect(searchResults.length, equals(1));
    });
  });

  group('PAGE 03 — Habits Completed from Notifications Tests', () {
    test('Notification action DONE updates streak idempotently without double-count', () {
      final entriesRepo = EntriesRepository();
      final habitService = HabitService();
      final habit = HabitItem(
        id: 'habit_read',
        name: 'Evening Reading',
        nameBn: 'সন্ধ্যায় বই পড়া',
        createdAt: DateTime.now(),
      );
      habitService.saveHabit(habit);

      final notifService = HabitNotificationService(
        habitService: habitService,
        entriesRepo: entriesRepo,
      );

      // Tap 1: Done
      final success1 = notifService.handleNotificationAction(
        HabitNotificationService.actionDone,
        'habit_read',
      );
      expect(success1, isTrue);

      final updated = habitService.getHabit('habit_read');
      expect(updated?.currentStreak, equals(1));

      // Tap 2: Repeated Done (Idempotent: Should not double-increment)
      final success2 = notifService.handleNotificationAction(
        HabitNotificationService.actionDone,
        'habit_read',
      );
      expect(success2, isTrue);
      expect(habitService.getHabit('habit_read')?.currentStreak, equals(1));
    });

    test('Notification action SNOOZE schedules 30m delay without marking completed', () {
      final entriesRepo = EntriesRepository();
      final habitService = HabitService();
      final habit = HabitItem(
        id: 'habit_water',
        name: 'Drink Water',
        nameBn: 'পানি পান',
        createdAt: DateTime.now(),
      );
      habitService.saveHabit(habit);

      final notifService = HabitNotificationService(
        habitService: habitService,
        entriesRepo: entriesRepo,
      );

      final snoozed = notifService.handleNotificationAction(
        HabitNotificationService.actionSnooze,
        'habit_water',
      );
      expect(snoozed, isTrue);
      expect(notifService.isSnoozed('habit_water'), isTrue);
      // Streak must remain 0
      expect(habitService.getHabit('habit_water')?.currentStreak, equals(0));
    });
  });

  group('PAGE 04 — NFC Tags that Run Routines Tests', () {
    test('Scanning paired NFC tag triggers routine and applies 60s anti-bounce filter', () {
      final entriesRepo = EntriesRepository();
      final nfcService = NfcRoutineService(entriesRepo: entriesRepo);

      const tagUid = '04:A2:8B:11:F2:60:80'; // Plant tag
      final scan1 = nfcService.handleTagScan(tagUid);
      expect(scan1.success, isTrue);
      expect(scan1.routine?.name, equals('Water Desk Plants'));
      expect(scan1.routine?.totalCompletions, equals(1));

      // Second immediate scan within 60 seconds must be debounced
      final scan2 = nfcService.handleTagScan(tagUid);
      expect(scan2.success, isFalse);
      expect(scan2.message, contains('Debounced'));
      expect(nfcService.getRoutine('routine_plant')?.totalCompletions, equals(1));
    });

    test('Pairing a new NFC tag updates routine mapping and event log', () {
      final entriesRepo = EntriesRepository();
      final nfcService = NfcRoutineService(entriesRepo: entriesRepo);

      const newUid = '04:99:88:77:66:55:44';
      nfcService.pairTag(
        tagUid: newUid,
        label: 'Front Door Keys Tag',
        routineId: 'routine_keys',
      );

      final pairedTag = nfcService.getTagByUid(newUid);
      expect(pairedTag, isNotNull);
      expect(pairedTag?.label, equals('Front Door Keys Tag'));
      expect(nfcService.getRoutine('routine_keys')?.pairedTagUid, equals(newUid));
    });
  });

  group('PAGE 05 — Heart Rate Monitor over Bluetooth Tests', () {
    test('Accurately classifies physiological training zones based on HRmax', () {
      const maxHr = 200;
      expect(WorkoutSessionRecord.classifyZone(110, maxHr: maxHr), equals(HeartRateZone.zone1)); // 55%
      expect(WorkoutSessionRecord.classifyZone(130, maxHr: maxHr), equals(HeartRateZone.zone2)); // 65%
      expect(WorkoutSessionRecord.classifyZone(150, maxHr: maxHr), equals(HeartRateZone.zone3)); // 75%
      expect(WorkoutSessionRecord.classifyZone(170, maxHr: maxHr), equals(HeartRateZone.zone4)); // 85%
      expect(WorkoutSessionRecord.classifyZone(190, maxHr: maxHr), equals(HeartRateZone.zone5)); // 95%
    });

    test('HeartRateService records telemetry and generates workout summary', () {
      final entriesRepo = EntriesRepository();
      final hrService = HeartRateService(entriesRepo: entriesRepo);

      hrService.startWorkout();
      expect(hrService.isWorkoutActive, isTrue);

      // Ingest live telemetry samples
      hrService.ingestDecodedBpm(130);
      hrService.ingestDecodedBpm(145);
      hrService.ingestDecodedBpm(160);

      expect(hrService.currentBpm, equals(160));
      expect(hrService.rollingSamples.length, equals(3));

      final workout = hrService.finishWorkout();
      expect(workout, isNotNull);
      expect(workout?.avgBpm, greaterThanOrEqualTo(140));
      expect(workout?.maxBpm, equals(160));
      expect(hrService.isWorkoutActive, isFalse);
    });
  });

  group('Presentation Smoke Tests for 5 Core Features', () {
    testWidgets('TripsScreen renders header, active pinned trip, and widget previews', (tester) async {
      final tripService = TripService();
      await tester.pumpWidget(
        MaterialApp(
          home: TripsScreen(tripService: tripService),
        ),
      );

      expect(find.text('TRIP COUNTDOWN'), findsOneWidget);
      expect(find.text('ACTIVE PINNED TRIP'), findsOneWidget);
      expect(find.text('LIVE WIDGET ARCHITECTURE PREVIEW'), findsOneWidget);
      expect(find.text('DAC'), findsOneWidget);
      expect(find.text('LHR'), findsOneWidget);
    });

    testWidgets('LinksScreen renders search bar, tags, and saved links', (tester) async {
      final linkService = LinkSaverService();
      await tester.pumpWidget(
        MaterialApp(
          home: LinksScreen(linkService: linkService),
        ),
      );

      expect(find.text('LINK SAVER'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('flutter.dev'), findsOneWidget);
    });

    testWidgets('NfcRoutinesScreen renders radar hero and routines list', (tester) async {
      final nfcService = NfcRoutineService();
      await tester.pumpWidget(
        MaterialApp(
          home: NfcRoutinesScreen(nfcService: nfcService),
        ),
      );

      expect(find.text('NFC ROUTINES'), findsOneWidget);
      expect(find.text('TAP PHYSICAL NFC STICKER'), findsOneWidget);
      expect(find.text('Water Desk Plants'), findsOneWidget);
      expect(find.text('Keys Placed at Home'), findsOneWidget);
    });

    testWidgets('HeartRateScreen renders telemetry HUD and zone indicators', (tester) async {
      final hrService = HeartRateService();
      await tester.pumpWidget(
        MaterialApp(
          home: HeartRateScreen(hrService: hrService),
        ),
      );

      expect(find.text('HEART RATE TELEMETRY'), findsOneWidget);
      expect(find.text('BEATS PER MINUTE (BPM)'), findsOneWidget);
      expect(find.text('60-SECOND ROLLING TELEMETRY'), findsOneWidget);
      expect(find.text('WORKOUT SESSION TRACKER'), findsOneWidget);
    });
  });
}
