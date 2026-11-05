import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/enums/task_priority.dart';
import 'package:daybook/data/repositories/entries_repository.dart';
import 'package:daybook/data/repositories/tasks_and_goals_repository.dart';
import 'package:daybook/domain/models/capture_item.dart';
import 'package:daybook/domain/models/rich_note.dart';
import 'package:daybook/domain/services/banglish_parser.dart';
import 'package:daybook/domain/services/inbox_service.dart';
import 'package:daybook/presentation/screens/inbox_screen.dart';
import 'package:daybook/presentation/widgets/command_palette.dart';
import 'package:daybook/presentation/widgets/universal_quick_capture_sheet.dart';

class GoldenTestCase {
  final String phrase;
  final ParsedIntentType expectedIntent;
  final double? expectedAmount;
  final TaskPriority? expectedPriority;
  final bool expectDueDate;

  const GoldenTestCase({
    required this.phrase,
    required this.expectedIntent,
    this.expectedAmount,
    this.expectedPriority,
    this.expectDueDate = false,
  });
}

/// 100-phrase golden benchmark dataset spanning Tasks, Expenses, Notes, Habits, Moods, and Alarms
/// covering Bangla script, English, Banglish transliteration, and diurnal time patterns.
const List<GoldenTestCase> kBanglishGoldenDataset = [
  // 1-20: Tasks & Deadlines (Banglish & Bangla)
  GoldenTestCase(phrase: 'Dudh kinte hobe kal shokal 9ta', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'কাল বিকাল ৫টায় ডক্টর কল করতে হবে', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'Assignment submit korbo ashchhe shukrobar', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'Office meeting at 11am tomorrow urgent p1', expectedIntent: ParsedIntentType.task, expectedPriority: TaskPriority.p1, expectDueDate: true),
  GoldenTestCase(phrase: 'Babu ke phone dite hobe rat 9tai', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'Flutter project build push korte hobe ajke', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'ডিম আর পাউরুটি কিনতে হবে আজ সন্ধ্যায়', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'Doctor appointment on porshu dupur 2ta', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'Renew passport online joruri p1', expectedIntent: ParsedIntentType.task, expectedPriority: TaskPriority.p1),
  GoldenTestCase(phrase: 'English presentation slide finish korte hobe', expectedIntent: ParsedIntentType.task),
  GoldenTestCase(phrase: 'Buy medicine for mom kal sokal 8ta', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'Electricity bill payment dite hobe', expectedIntent: ParsedIntentType.expense),
  GoldenTestCase(phrase: 'Call landlord about water line p2', expectedIntent: ParsedIntentType.task, expectedPriority: TaskPriority.p2),
  GoldenTestCase(phrase: 'Clean desk and setup workspace shomoy pele p4', expectedIntent: ParsedIntentType.task, expectedPriority: TaskPriority.p4),
  GoldenTestCase(phrase: 'Send CV to Tech lead via email', expectedIntent: ParsedIntentType.task),
  GoldenTestCase(phrase: 'Next week shombar 10am client meeting', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'বই পড়া শেষ করব পরশু রাত ১০টায়', expectedIntent: ParsedIntentType.task, expectDueDate: true),
  GoldenTestCase(phrase: 'Organize files on laptop drive todo', expectedIntent: ParsedIntentType.task),
  GoldenTestCase(phrase: 'Prepare weekly review report', expectedIntent: ParsedIntentType.task),
  GoldenTestCase(phrase: 'Doctor followup visit ashchhe robibar', expectedIntent: ParsedIntentType.task, expectDueDate: true),

  // 21-45: Expenses & Money Logs (BDT, Taka, Tk, Bengali Numerals)
  GoldenTestCase(phrase: 'Rickshaw vara dilam 60 taka', expectedIntent: ParsedIntentType.expense, expectedAmount: 60.0),
  GoldenTestCase(phrase: 'রিকশা ভাড়া দিলাম ৫০ টাকা', expectedIntent: ParsedIntentType.expense, expectedAmount: 50.0),
  GoldenTestCase(phrase: 'Super shop bazar 1450 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 1450.0),
  GoldenTestCase(phrase: 'আজকের বাজার খরচ ১২০০ টাকা', expectedIntent: ParsedIntentType.expense, expectedAmount: 1200.0),
  GoldenTestCase(phrase: 'Wifi bill 800 tk paid', expectedIntent: ParsedIntentType.expense, expectedAmount: 800.0),
  GoldenTestCase(phrase: 'Lunch with team 350 taka', expectedIntent: ParsedIntentType.expense, expectedAmount: 350.0),
  GoldenTestCase(phrase: 'Pathao ride 120 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 120.0),
  GoldenTestCase(phrase: 'Cha and biscuits 40 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 40.0),
  GoldenTestCase(phrase: 'Babu ke 500 tk dhar dilam', expectedIntent: ParsedIntentType.expense, expectedAmount: 500.0),
  GoldenTestCase(phrase: 'ঔষধ কিনলাম ২৫০ টাকা', expectedIntent: ParsedIntentType.expense, expectedAmount: 250.0),
  GoldenTestCase(phrase: 'Mobile recharge 200 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 200.0),
  GoldenTestCase(phrase: 'Current bill dilam 1850 taka', expectedIntent: ParsedIntentType.expense, expectedAmount: 1850.0),
  GoldenTestCase(phrase: 'Book bought 420 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 420.0),
  GoldenTestCase(phrase: 'Coffee 180 taka', expectedIntent: ParsedIntentType.expense, expectedAmount: 180.0),
  GoldenTestCase(phrase: 'Bus vara 25 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 25.0),
  GoldenTestCase(phrase: 'বাস ভাড়া ৩০ টাকা দিলাম', expectedIntent: ParsedIntentType.expense, expectedAmount: 30.0),
  GoldenTestCase(phrase: 'Spent 500 tk for fruits', expectedIntent: ParsedIntentType.expense, expectedAmount: 500.0),
  GoldenTestCase(phrase: 'Gym subscription 1500 tk payment', expectedIntent: ParsedIntentType.expense, expectedAmount: 1500.0),
  GoldenTestCase(phrase: 'Bought groceries ৳ 850', expectedIntent: ParsedIntentType.expense, expectedAmount: 850.0),
  GoldenTestCase(phrase: 'Online shopping 2400 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 2400.0),
  GoldenTestCase(phrase: 'CNG fare 250 taka', expectedIntent: ParsedIntentType.expense, expectedAmount: 250.0),
  GoldenTestCase(phrase: 'Snacks and water 75 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 75.0),
  GoldenTestCase(phrase: 'Metro rail ticket 40 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 40.0),
  GoldenTestCase(phrase: 'Borrowed 1000 tk from Hasan', expectedIntent: ParsedIntentType.expense, expectedAmount: 1000.0),
  GoldenTestCase(phrase: 'Print documents cost 65 taka', expectedIntent: ParsedIntentType.expense, expectedAmount: 65.0),

  // 46-60: Habits & Health Streaks
  GoldenTestCase(phrase: 'Pani khailam 2 liter water streak', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'আজকে ২ লিটার পানি খেলাম', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Morning workout done 30 mins', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Meditation korlam 15 minutes', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Read 10 pages of book habit', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Evening walk 5000 steps habit', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'আজকের নামাজ সম্পন্ন', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Daily water intake completed', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'No sugar streak day 5 habit', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Core exercise and stretching done', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: '30 minutes coding practice habit streak', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Cold shower taken habit', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Early sleep habit checkin', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Guitar practice completed obhyas', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: 'Gym leg day session finished', expectedIntent: ParsedIntentType.habit),

  // 61-75: Mood & Emotional Wellness Check-ins
  GoldenTestCase(phrase: 'Mon valo nei ajke feeling down', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'আজ মন খুব ভালো লাগছে', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Feeling energetic and motivated today', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Feeling anxious about the upcoming exam', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Khub shanto lagchhe mon', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Exhausted after long commute mood low', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Very happy with our release today', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Feeling sad and distracted', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Tired and sleepy after heavy day', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Feeling peaceful sitting on rooftop', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Mon kharap pore kotha bolbo', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Great day achieved all goals feeling accomplished', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Frustrated by bugs in code today', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Feeling grateful for family dinner', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: 'Stressed about project deadline', expectedIntent: ParsedIntentType.mood),

  // 76-88: Alarms & Wake Quests
  GoldenTestCase(phrase: 'Alarm set koro kal sokal 6tai', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'কাল সকাল ৬:৩০ টায় অ্যালার্ম দাও', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Wake me up at 7am tomorrow', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Sokal 5:30ta ghoom theke uthbo alarm', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Set alarm for 6:00 AM math challenge', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Uthbo kal sokal 7tai', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'সকাল ৮টায় ডেকে দিও অ্যালার্ম', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Wake up alarm at 5am tomorrow', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Set wake quest alarm for 6:15 AM', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Sokal 6:45tai alarm chai', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Night flight reminder alarm 11pm', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Fajr prayer alarm at 4:45 AM', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Wake quest strict alarm 7:30am', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),

  // 89-105: Explicit Command Palette Overrides and Rich Notes / URLs
  GoldenTestCase(phrase: '/task Research Flutter clean architecture', expectedIntent: ParsedIntentType.task),
  GoldenTestCase(phrase: '/expense Lunch buffet 850 tk', expectedIntent: ParsedIntentType.expense, expectedAmount: 850.0),
  GoldenTestCase(phrase: '/note App architecture design ideas with Drift and SQLCipher', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: '/habit 8 glasses of water today', expectedIntent: ParsedIntentType.habit),
  GoldenTestCase(phrase: '/mood Feeling calm and focused', expectedIntent: ParsedIntentType.mood),
  GoldenTestCase(phrase: '/alarm Sokal 6:30 AM', expectedIntent: ParsedIntentType.alarm, expectDueDate: true),
  GoldenTestCase(phrase: 'Meeting notes with client about database sync requirements', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Check out this awesome article: https://flutter.dev/docs/drift', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Remember that the secret key is in secure storage', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Thoughts on personal reflections and journaling consistency', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Idea for new mobile app design system with OLED black', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Summary of discussion with mentor on backend scaling', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'WiFi router password and subnet configuration memo', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Recipe notes: add cinnamon and cardamom to chai', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Quote of the day: consistency beats brilliance every time', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'GitHub repo bookmark: https://github.com/rahat4528/daybook', expectedIntent: ParsedIntentType.note),
  GoldenTestCase(phrase: 'Random thoughts about evening rain and tea in Dhaka', expectedIntent: ParsedIntentType.note),
];

void main() {
  group('PART 6 — Banglish & Bangla Natural Language Parser Golden Benchmark Suite', () {
    test('Evaluates 100+ golden phrases and measures accuracy', () {
      int correctIntents = 0;
      int correctAmounts = 0;
      int amountEvaluated = 0;
      final refTime = DateTime(2026, 11, 6, 10, 0); // Reference: Friday morning

      final total = kBanglishGoldenDataset.length;
      expect(total >= 100, isTrue, reason: 'Dataset must contain at least 100 phrases');

      for (final testCase in kBanglishGoldenDataset) {
        final parsed = BanglishParser.parse(testCase.phrase, referenceTime: refTime);

        // Check intent classification accuracy
        if (parsed.intentType == testCase.expectedIntent) {
          correctIntents++;
        } else {
          debugPrint('Intent mismatch: "${testCase.phrase}" -> got ${parsed.intentType}, expected ${testCase.expectedIntent}');
        }

        // Check amount extraction accuracy if applicable
        if (testCase.expectedAmount != null) {
          amountEvaluated++;
          if (parsed.amount == testCase.expectedAmount) {
            correctAmounts++;
          } else {
            debugPrint('Amount mismatch: "${testCase.phrase}" -> got ${parsed.amount}, expected ${testCase.expectedAmount}');
          }
        }

        // Check date detection if required
        if (testCase.expectDueDate) {
          expect(parsed.dueDate, isNotNull,
              reason: 'Expected valid date extracted for: ${testCase.phrase}');
        }

        // Check priority detection if required
        if (testCase.expectedPriority != null) {
          expect(parsed.priority, equals(testCase.expectedPriority),
              reason: 'Expected priority ${testCase.expectedPriority} for: ${testCase.phrase}');
        }
      }

      final intentAccuracy = (correctIntents / total) * 100.0;
      final amountAccuracy = (correctAmounts / amountEvaluated) * 100.0;

      // Print verified metrics for audit report
      debugPrint('====================================================');
      debugPrint('PART 6 BANGLISH PARSER GOLDEN DATASET BENCHMARK');
      debugPrint('Total Phrases Evaluated: $total');
      debugPrint('Intent Accuracy: ${intentAccuracy.toStringAsFixed(2)}% ($correctIntents/$total)');
      debugPrint('Amount Accuracy: ${amountAccuracy.toStringAsFixed(2)}% ($correctAmounts/$amountEvaluated)');
      debugPrint('====================================================');

      // Strict Acceptance Gate: Minimum 95% accuracy
      expect(intentAccuracy >= 95.0, isTrue,
          reason: 'Parser must achieve at least 95% intent accuracy on golden dataset');
      expect(amountAccuracy >= 95.0, isTrue,
          reason: 'Parser must achieve at least 95% amount accuracy on financial phrases');
    });

    test('Bengali numerals are accurately mapped to Arabic digits', () {
      expect(BanglishParser.normalizeNumerals('১২৩৪৫৬৭৮৯০'), equals('1234567890'));
      expect(BanglishParser.normalizeNumerals('আজকের খরচ ৫০০ টাকা'), equals('আজকের খরচ 500 টাকা'));
    });

    test('Title cleaning extracts core task without temporal noise', () {
      final clean1 = BanglishParser.cleanTitle('Dudh kinte hobe kal shokal 9ta');
      expect(clean1.toLowerCase(), contains('dudh kinte hobe'));
      expect(clean1.toLowerCase().contains('kal'), isFalse);
    });
  });

  group('PART 6 — Inbox Service & Rich Note Triage Tests', () {
    late InboxService inboxService;
    late TasksAndGoalsRepository tasksRepo;
    late EntriesRepository entriesRepo;

    setUp(() {
      inboxService = InboxService();
      tasksRepo = TasksAndGoalsRepository();
      entriesRepo = EntriesRepository();
    });

    test('Captures ingest from typed, voice, and share intents', () {
      final c1 = inboxService.createCapture(
        rawText: 'Buy milk tomorrow 9am',
        source: CaptureSource.typed,
      );
      final c2 = inboxService.createCapture(
        rawText: 'Rickshaw 60 tk',
        source: CaptureSource.voice,
      );
      final c3 = inboxService.createCapture(
        rawText: 'https://flutter.dev/docs/security',
        source: CaptureSource.shareIntent,
      );

      expect(inboxService.unprocessedCount, equals(3));
      expect(inboxService.getUnprocessedCaptures().length, equals(3));
      expect(c1.isProcessed, isFalse);
      expect(c2.source, equals(CaptureSource.voice));
      expect(c3.source, equals(CaptureSource.shareIntent));
    });

    test('Triaging capture to Task writes to tasks repository and single event log', () {
      final cap = inboxService.createCapture(
        rawText: 'Submit assignment ashchhe shukrobar p1',
        source: CaptureSource.typed,
      );

      final task = inboxService.convertToTask(
        cap.id,
        tasksRepo: tasksRepo,
        entriesRepo: entriesRepo,
      );

      expect(task.title, contains('Submit assignment'));
      expect(task.priority, equals(TaskPriority.p1));
      expect(task.isFrog, isTrue);
      expect(inboxService.unprocessedCount, equals(0));

      // Verify event log received the entry
      final dayKey = InboxService.formatDayKey(DateTime.now());
      final page = entriesRepo.getDayPage(dayKey);
      expect(page.entries.any((e) => e.payload['taskId'] == task.id), isTrue);
    });

    test('Triaging capture to Expense writes to event log with amount and category', () {
      final cap = inboxService.createCapture(
        rawText: 'Rickshaw vara dilam 75 taka',
        source: CaptureSource.typed,
      );

      final exp = inboxService.convertToExpense(
        cap.id,
        entriesRepo: entriesRepo,
      );

      expect(exp['amount'], equals(75.0));
      expect(exp['category'], equals('Transport'));
      expect(inboxService.unprocessedCount, equals(0));

      final dayKey = InboxService.formatDayKey(DateTime.now());
      final page = entriesRepo.getDayPage(dayKey);
      expect(page.entries.any((e) => e.payload['amount'] == 75.0), isTrue);
    });

    test('Triaging capture to RichNote auto-detects links and supports checklists', () {
      final capLink = inboxService.createCapture(
        rawText: 'Read documentation at https://dart.dev/guides',
        source: CaptureSource.shareIntent,
      );

      final note = inboxService.convertToRichNote(
        capLink.id,
        entriesRepo: entriesRepo,
      );

      expect(note.type, equals(NoteType.link));
      expect(note.linkUrl, equals('https://dart.dev/guides'));

      // Test checklist rich note
      final checklistNote = inboxService.createRichNote(
        RichNote(
          id: 'note_cl_1',
          title: 'Morning Checklist',
          body: 'Checklist for high momentum morning',
          type: NoteType.checklist,
          checklistItems: const [
            ChecklistItem(id: 'i1', text: 'Drink 500ml water', isCompleted: false),
            ChecklistItem(id: 'i2', text: '5 min breathing meditation', isCompleted: false),
          ],
          dayKey: InboxService.formatDayKey(DateTime.now()),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(checklistNote.checklistItems.length, equals(2));
      inboxService.toggleChecklistItem('note_cl_1', 'i1');
      final updated = inboxService.getNotesForDay(InboxService.formatDayKey(DateTime.now())).firstWhere((n) => n.id == 'note_cl_1');
      expect(updated.checklistItems.first.isCompleted, isTrue);
    });

    test('Undo triage restores capture to unprocessed state', () {
      final cap = inboxService.createCapture(
        rawText: 'Test capture for undo',
        source: CaptureSource.typed,
      );

      inboxService.convertToTask(
        cap.id,
        tasksRepo: tasksRepo,
        entriesRepo: entriesRepo,
      );
      expect(inboxService.unprocessedCount, equals(0));

      final restored = inboxService.undoLastTriage();
      expect(restored, isNotNull);
      expect(inboxService.unprocessedCount, equals(1));
    });
  });

  group('PART 6 — Presentation Smoke & Interaction Tests', () {
    late InboxService inboxService;
    late TasksAndGoalsRepository tasksRepo;
    late EntriesRepository entriesRepo;

    setUp(() {
      inboxService = InboxService();
      tasksRepo = TasksAndGoalsRepository();
      entriesRepo = EntriesRepository();
    });

    testWidgets('CommandPalette renders search field and command list', (tester) async {
      String? selectedCmd;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CommandPalette(
              isBangla: false,
              onSelectCommand: (cmd) => selectedCmd = cmd,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('COMMAND PALETTE'), findsOneWidget);
      expect(find.text('/task'), findsOneWidget);
      expect(find.text('/expense'), findsOneWidget);
      expect(find.text('/note'), findsOneWidget);

      // Tap on /task
      await tester.tap(find.text('/task'));
      await tester.pumpAndSettle();

      expect(selectedCmd, equals('/task'));
    });

    testWidgets('UniversalQuickCaptureSheet renders text input, live chips, and saves', (tester) async {
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: UniversalQuickCaptureSheet(
              isBangla: false,
              inboxService: inboxService,
              tasksRepo: tasksRepo,
              entriesRepo: entriesRepo,
              onSaved: () => saved = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('UNIVERSAL QUICK CAPTURE'), findsOneWidget);

      // Enter task text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Dudh kinte hobe kal shokal 9ta');
      await tester.pumpAndSettle();

      // Check reactive parsed preview chips
      expect(find.text('Task'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
      expect(inboxService.getAllCaptures().isNotEmpty, isTrue);
    });

    testWidgets('InboxScreen displays triage list and actions', (tester) async {
      inboxService.createCapture(
        rawText: 'Rickshaw 60 tk',
        source: CaptureSource.typed,
      );
      inboxService.createCapture(
        rawText: 'Finish documentation tonight',
        source: CaptureSource.voice,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: InboxScreen(
            isBangla: false,
            inboxService: inboxService,
            tasksRepo: tasksRepo,
            entriesRepo: entriesRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('INBOX TRIAGE'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Badge counter
      expect(find.text('Rickshaw 60 tk'), findsOneWidget);
      expect(find.text('Finish documentation tonight'), findsOneWidget);

      // Tap Convert to Expense on the first card
      final expenseButtons = find.text('Expense');
      expect(expenseButtons, findsWidgets);

      await tester.tap(expenseButtons.first);
      await tester.pumpAndSettle();

      expect(inboxService.unprocessedCount, equals(1));
    });
  });
}
