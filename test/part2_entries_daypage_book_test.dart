import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/localization/app_localizations.dart';
import 'package:daybook/data/repositories/entries_repository.dart';
import 'package:daybook/domain/models/day_page.dart';
import 'package:daybook/domain/models/journal_entry.dart';
import 'package:daybook/domain/models/time_capsule.dart';
import 'package:daybook/domain/services/book_export_service.dart';
import 'package:daybook/domain/services/nightly_summary_service.dart';
import 'package:daybook/presentation/screens/book_screen.dart';
import 'package:daybook/presentation/screens/day_page_screen.dart';

void main() {
  group('PART 2 — Entries & Event Log Tests', () {
    test('JournalEntry serialization and typed event kinds', () {
      final now = DateTime(2026, 10, 15, 14, 30);
      final entry = JournalEntry(
        id: 'entry_test_1',
        type: EntryType.taskCompleted,
        ts: now,
        payload: {'task_name': 'Ship Part 2 DayBook'},
        mood: 5,
        energy: 4,
        source: 'user',
        dayKey: '2026-10-15',
        isPinned: true,
      );

      final json = entry.toJson();
      expect(json['id'], 'entry_test_1');
      expect(json['type'], 'task_completed');
      expect(json['is_pinned'], true);

      final deserialized = JournalEntry.fromJson(json);
      expect(deserialized.id, entry.id);
      expect(deserialized.type, EntryType.taskCompleted);
      expect(deserialized.mood, 5);
      expect(deserialized.energy, 4);
      expect(deserialized.isPinned, true);
      expect(deserialized.timeFormatted, '14:30');

      // Test English and Bangla displayText
      expect(deserialized.displayText(isBangla: false), 'Completed: Ship Part 2 DayBook');
      expect(deserialized.displayText(isBangla: true), 'সম্পন্ন: Ship Part 2 DayBook');
    });

    test('EntriesRepository CRUD and Undo stack', () {
      final repo = EntriesRepository();
      const dayKey = '2026-10-20';

      final entry = JournalEntry(
        id: 'entry_undo_test',
        type: EntryType.manualNote,
        ts: DateTime(2026, 10, 20, 10, 0),
        payload: {'note': 'Important morning insight'},
        dayKey: dayKey,
      );

      repo.insertEntry(entry);
      final pageBefore = repo.getDayPage(dayKey);
      expect(pageBefore.entries.length, 1);
      expect(repo.canUndo, false);

      // Delete entry
      final deleted = repo.deleteEntry('entry_undo_test');
      expect(deleted, true);
      expect(repo.canUndo, true);

      final pageAfterDelete = repo.getDayPage(dayKey);
      expect(pageAfterDelete.entries.isEmpty, true);

      // Trigger Undo
      final restored = repo.undo();
      expect(restored, isNotNull);
      expect(restored!.id, 'entry_undo_test');

      final pageAfterUndo = repo.getDayPage(dayKey);
      expect(pageAfterUndo.entries.length, 1);
      expect(pageAfterUndo.entries.first.id, 'entry_undo_test');
    });
  });

  group('PART 2 — Day Page & Nightly Summary Tests', () {
    test('Day Score calculation and 5-tier heat opacity mapping', () {
      final now = DateTime(2026, 10, 10);
      const dayKey = '2026-10-10';

      final entries = [
        JournalEntry(
          id: 'alarm_1',
          type: EntryType.alarmDismissed,
          ts: now.add(const Duration(hours: 6)),
          dayKey: dayKey,
        ),
        JournalEntry(
          id: 'task_1',
          type: EntryType.taskCompleted,
          ts: now.add(const Duration(hours: 9)),
          dayKey: dayKey,
        ),
        JournalEntry(
          id: 'task_2',
          type: EntryType.taskCompleted,
          ts: now.add(const Duration(hours: 11)),
          dayKey: dayKey,
        ),
        JournalEntry(
          id: 'habit_1',
          type: EntryType.habitLogged,
          ts: now.add(const Duration(hours: 12)),
          dayKey: dayKey,
        ),
        JournalEntry(
          id: 'focus_1',
          type: EntryType.focusSession,
          ts: now.add(const Duration(hours: 14)),
          payload: {'minutes': 45},
          dayKey: dayKey,
        ),
      ];

      final dayPage = DayPageModel(
        dayKey: dayKey,
        date: now,
        entries: entries,
        reflectionNote: 'Solid productive focus session.',
        gratitudeNote: 'Grateful for health.',
      );

      final score = dayPage.computeDayScore();
      // 20 (alarm) + 20 (2 tasks) + 10 (1 habit) + 10 (focus) + 15 (reflection) = 75
      expect(score, 75);
      expect(dayPage.scoreTier, 3); // 60-79 is Tier 3
      expect(dayPage.heatOpacity, 0.75); // Tier 3 maps to 75% Lime opacity
    });

    test('NightlySummaryService synthesizes 3-line daily summary offline', () {
      final now = DateTime(2026, 10, 12);
      const dayKey = '2026-10-12';

      final entries = [
        JournalEntry(
          id: 'alarm_1',
          type: EntryType.alarmDismissed,
          ts: now.add(const Duration(hours: 6, minutes: 30)),
          dayKey: dayKey,
        ),
        JournalEntry(
          id: 'task_1',
          type: EntryType.taskCompleted,
          ts: now.add(const Duration(hours: 10)),
          payload: {'task_name': 'Build Riverpod State'},
          dayKey: dayKey,
        ),
        JournalEntry(
          id: 'habit_1',
          type: EntryType.habitLogged,
          ts: now.add(const Duration(hours: 12)),
          payload: {'habit_name': 'Read 20 mins'},
          dayKey: dayKey,
        ),
        JournalEntry(
          id: 'step_1',
          type: EntryType.stepMilestone,
          ts: now.add(const Duration(hours: 17)),
          payload: {'steps': 8200},
          dayKey: dayKey,
        ),
      ];

      final page = DayPageModel(
        dayKey: dayKey,
        date: now,
        entries: entries,
        calculatedScore: 85,
      );

      // English summary
      final summaryEn = NightlySummaryService.synthesizeOfflineSummary(page, isBangla: false);
      final linesEn = summaryEn.split('\n');
      expect(linesEn.length, 3);
      expect(linesEn[0], contains('Woke up on schedule'));
      expect(linesEn[1], contains('8200 steps'));
      expect(linesEn[2], contains('Day Score of 85/100'));

      // Bangla summary
      final summaryBn = NightlySummaryService.synthesizeOfflineSummary(page, isBangla: true);
      final linesBn = summaryBn.split('\n');
      expect(linesBn.length, 3);
      expect(linesBn[0], contains('সম্পন্ন করা হয়েছে'));
      expect(linesBn[1], contains('৮২০০ কদম'));
      expect(linesBn[2], contains('দিন স্কোর অর্জিত হয়েছে'));
    });
  });

  group('PART 2 — Book, On This Day & Time Capsule Tests', () {
    test('On This Day throwbacks from 1 month and 1 year ago', () {
      final repo = EntriesRepository();
      final today = DateTime(2026, 10, 15);

      // Add throwback from 1 month ago (2026-09-15)
      repo.insertEntry(JournalEntry(
        id: 'throwback_month',
        type: EntryType.momentPinned,
        ts: DateTime(2026, 9, 15, 12, 0),
        payload: {'title': 'Started DayBook prototype 1 month ago'},
        dayKey: '2026-09-15',
      ));

      // Add throwback from 1 year ago (2025-10-15)
      repo.insertEntry(JournalEntry(
        id: 'throwback_year',
        type: EntryType.manualNote,
        ts: DateTime(2025, 10, 15, 12, 0),
        payload: {'title': 'One year anniversary note'},
        dayKey: '2025-10-15',
      ));

      final throwbacks = repo.getOnThisDay(today);
      expect(throwbacks.length, 2);
      expect(throwbacks.any((t) => t.dayKey == '2026-09-15'), true);
      expect(throwbacks.any((t) => t.dayKey == '2025-10-15'), true);
    });

    test('Time Capsule sealing, countdown, and unlocking', () {
      final now = DateTime.now();
      final locked = TimeCapsuleItem(
        id: 'cap_locked',
        title: 'Letter to Future Self',
        content: 'Remember why you started DayBook.',
        createdAt: now.subtract(const Duration(days: 5)),
        unlockAt: now.add(const Duration(days: 25)),
      );

      expect(locked.shouldUnlock, false);
      expect(locked.daysRemaining, greaterThanOrEqualTo(24));

      final eligible = TimeCapsuleItem(
        id: 'cap_ready',
        title: 'New Year Reflection',
        content: 'Welcome to 2026!',
        createdAt: now.subtract(const Duration(days: 100)),
        unlockAt: now.subtract(const Duration(days: 1)),
      );

      expect(eligible.shouldUnlock, true);
      expect(eligible.daysRemaining, 0);

      final repo = EntriesRepository();
      repo.addTimeCapsule(locked);
      repo.addTimeCapsule(eligible);

      final unlocked = repo.unlockEligibleCapsules(now);
      expect(unlocked.length, 1);
      expect(unlocked.first.id, 'cap_ready');
      expect(unlocked.first.isUnlocked, true);
    });
  });

  group('PART 2 — Simulated Month & Publication-Grade Export Gate', () {
    test('Simulated month seeds 30+ days and survives queries', () {
      final repo = EntriesRepository();
      repo.seedSimulatedMonth(2026, 10);

      final days = repo.getMonthDays(2026, 10);
      expect(days.length, 31); // October has 31 days

      // Ensure every single day has events, Day Score, and nightly summary
      for (final day in days) {
        expect(day.entries.isNotEmpty, true);
        expect(day.computeDayScore(), greaterThan(0));
        expect(day.nightlySummary, isNotNull);
      }
    });

    test('Export month to PDF generates valid PDF bytes in dark and print-friendly modes', () async {
      final repo = EntriesRepository();
      repo.seedSimulatedMonth(2026, 10);
      final days = repo.getMonthDays(2026, 10).take(5).toList();

      // 1. OLED Dark mode PDF
      final darkPdfBytes = await BookExportService.exportMonthToPdf(
        days,
        2026,
        10,
        blackOnWhite: false,
        isBangla: false,
      );
      expect(darkPdfBytes, isNotEmpty);
      // Valid PDF magic header starts with %PDF-
      final darkHeader = String.fromCharCodes(darkPdfBytes.take(5));
      expect(darkHeader, '%PDF-');

      // 2. Print-friendly black-on-white PDF
      final printPdfBytes = await BookExportService.exportMonthToPdf(
        days,
        2026,
        10,
        blackOnWhite: true,
        isBangla: false,
      );
      expect(printPdfBytes, isNotEmpty);
      final printHeader = String.fromCharCodes(printPdfBytes.take(5));
      expect(printHeader, '%PDF-');
    });

    test('Export month to Markdown and JSON formats', () {
      final repo = EntriesRepository();
      repo.seedSimulatedMonth(2026, 10);
      final days = repo.getMonthDays(2026, 10).take(3).toList();

      // Markdown
      final md = BookExportService.exportMonthToMarkdown(days, 2026, 10);
      expect(md, contains('# DayBook - October 2026'));
      expect(md, contains('### Timeline'));
      expect(md, contains('### Nightly Summary'));

      // JSON
      final jsonStr = BookExportService.exportMonthToJson(days, 2026, 10);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(parsed['app'], 'DayBook');
      expect(parsed['year'], 2026);
      expect(parsed['month'], 10);
      expect((parsed['days'] as List).length, 3);
    });

    test('Bangla Localization strings for Part 2 exist and format correctly', () {
      const bn = AppLocale(isBangla: true);
      const en = AppLocale(isBangla: false);

      expect(bn.dayPage, 'দিনের পৃষ্ঠা');
      expect(en.dayPage, 'Day Page');

      expect(bn.theBook, 'দিনবই');
      expect(en.theBook, 'Book');

      expect(bn.onThisDay, 'এই দিনে (থ্রোব্যাক)');
      expect(en.onThisDay, 'On This Day');

      expect(bn.nightlySummary, 'রাতের সারসংক্ষেপ');
      expect(en.nightlySummary, 'Nightly Summary');

      expect(bn.formatNumber(2026), '২০২৬');
      expect(en.formatNumber(2026), '2026');
    });
  });

  group('PART 2 — Presentation Widgets Smoke Tests', () {
    testWidgets('DayPageScreen renders timeline and actions without overflow', (tester) async {
      final repo = EntriesRepository();
      repo.seedSimulatedMonth(2026, 10);

      await tester.pumpWidget(
        MaterialApp(
          home: DayPageScreen(
            repository: repo,
            initialDate: DateTime(2026, 10, 15),
            isBangla: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Day Page'), findsOneWidget);
      expect(find.text('DAY TIMELINE'), findsOneWidget);
      expect(find.text('Nightly Summary'), findsOneWidget);
      expect(find.text('Add Note'), findsOneWidget);
    });

    testWidgets('BookScreen renders month shelf, heatmap, and page swiper', (tester) async {
      final repo = EntriesRepository();
      repo.seedSimulatedMonth(2026, 10);

      await tester.pumpWidget(
        MaterialApp(
          home: BookScreen(
            repository: repo,
            isBangla: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Heatmap Calendar'), findsOneWidget);
      expect(find.text('PAGE-TURN BOOK MODE'), findsOneWidget);
    });
  });
}
