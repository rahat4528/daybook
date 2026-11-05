import '../../core/localization/app_localizations.dart';
import '../models/day_page.dart';
import '../models/journal_entry.dart';

class NightlySummaryService {
  /// Synthesizes a deterministic 3-line daily summary offline from the day's event log.
  /// If online and AI key is provided, can be passed to the LLM proxy to polish.
  static String synthesizeOfflineSummary(DayPageModel page, {bool isBangla = false}) {
    final entries = page.entries;
    final score = page.calculatedScore > 0 ? page.calculatedScore : page.computeDayScore();
    final locale = AppLocale(isBangla: isBangla);

    // Line 1: Wake, Focus & Output
    final wakeEntry = entries.where((e) => e.type == EntryType.alarmDismissed).firstOrNull;
    final completedTasks = entries.where((e) => e.type == EntryType.taskCompleted).toList();
    final focusSessions = entries.where((e) => e.type == EntryType.focusSession).toList();
    final totalFocusMins = focusSessions.fold<int>(
      0,
      (sum, e) => sum + ((e.payload['minutes'] as int?) ?? 25),
    );

    String line1;
    if (isBangla) {
      final wakeStr = wakeEntry != null ? 'সকালে জাগ্রত হয়ে' : 'দিনটি শুরু করে';
      final focusStr = totalFocusMins > 0 ? '${locale.formatNumber(totalFocusMins)} মিনিট ফোকাসসহ' : '';
      final taskStr = '${locale.formatNumber(completedTasks.length)}টি কাজ সম্পন্ন করা হয়েছে।';
      line1 = '$wakeStr $focusStr $taskStr'.replaceAll('  ', ' ').trim();
    } else {
      final wakeStr = wakeEntry != null ? 'Woke up on schedule,' : 'Started the day,';
      final focusStr = totalFocusMins > 0 ? 'logged $totalFocusMins mins of deep focus,' : '';
      final taskStr = 'completed ${completedTasks.length} task${completedTasks.length == 1 ? '' : 's'}.';
      line1 = '$wakeStr $focusStr $taskStr'.replaceAll('  ', ' ').trim();
    }

    // Line 2: Habits, Steps & Energy
    final habits = entries.where((e) => e.type == EntryType.habitLogged).toList();
    final stepsEntry = entries.where((e) => e.type == EntryType.stepMilestone).firstOrNull;
    final stepCount = stepsEntry != null ? (stepsEntry.payload['steps'] as int? ?? 5000) : null;

    String line2;
    if (isBangla) {
      final habitStr = habits.isNotEmpty ? '${locale.formatNumber(habits.length)}টি অভ্যাস বজায় ছিল' : 'দৈনিক রুটিন অনুসরণ করা হয়েছে';
      final stepStr = stepCount != null ? 'এবং ${locale.formatNumber(stepCount)} কদম হাঁটা সম্পন্ন।' : '।';
      line2 = '$habitStr $stepStr';
    } else {
      final habitStr = habits.isNotEmpty ? 'Maintained ${habits.length} daily habit${habits.length == 1 ? '' : 's'}' : 'Kept daily routines steady';
      final stepStr = stepCount != null ? ' and logged $stepCount steps.' : '.';
      line2 = '$habitStr$stepStr';
    }

    // Line 3: Evening reflection, Mood & Day Score
    String line3;
    if (isBangla) {
      final moodStr = page.entries.where((e) => e.mood != null).map((e) => e.mood).lastOrNull;
      final moodText = moodStr != null ? 'মুড রেটিং ${locale.formatNumber(moodStr)}/৫ সহ ' : '';
      line3 = '$moodTextদিন স্কোর অর্জিত হয়েছে ${locale.formatNumber(score)}/১০০।';
    } else {
      final moodStr = page.entries.where((e) => e.mood != null).map((e) => e.mood).lastOrNull;
      final moodText = moodStr != null ? 'with a mood rating of $moodStr/5, ' : '';
      line3 = 'Closed the evening ${moodText}achieving a Day Score of $score/100.';
    }

    return '$line1\n$line2\n$line3';
  }

  /// Default reflection prompts in Bangla and English
  static String getRandomReflectionPrompt({bool isBangla = false}) {
    final promptsEn = [
      'What was the single most meaningful moment of today?',
      'Where did you direct your best energy, and what paid off?',
      'What is one lesson from today you will carry into tomorrow?',
      'Did your actions align with your top priorities today?',
    ];

    final promptsBn = [
      'আজকের দিনের সবচেয়ে অর্থবহ মুহূর্ত কোনটি ছিল?',
      'আজকে আপনার সেরা শক্তি কোন কাজে সবচেয়ে ভালো ফল দিয়েছে?',
      'আজকের থেকে কোন শিক্ষাটি আপনি আগামীকালের জন্য মনে রাখবেন?',
      'আজকের সারাদিনের কাজ কি আপনার মূল লক্ষ্যের সাথে সামঞ্জস্যপূর্ণ ছিল?',
    ];

    final list = isBangla ? promptsBn : promptsEn;
    return list[DateTime.now().day % list.length];
  }
}
