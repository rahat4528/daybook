import '../models/weather_and_briefing.dart';
import '../models/task_item.dart';
import '../models/alarm_item.dart';

class BriefingService {
  static const List<String> quotesEn = [
    'Focus on being productive instead of busy.',
    'Small disciplines repeated with consistency lead to great achievements.',
    'Master your morning, elevate your life.',
    'Action is the foundational key to all success.',
    'You do not rise to the level of your goals, you fall to the level of your systems.',
  ];

  static const List<String> quotesBn = [
    'ব্যস্ত থাকার চেয়ে ফলপ্রসূ হওয়া বেশি গুরুত্বপূর্ণ।',
    'প্রতিদিনের ছোট ছোট নিয়মনিষ্ঠাই বড় সাফল্যের চাবিকাঠি।',
    'সকালটা জয় করুন, পুরো দিনটা আপনার নিয়ন্ত্রণে থাকবে।',
    'কাজের শুরুই হলো সব সাফল্যের ভিত্তি।',
    'নিয়মানুবর্তিতাই ইচ্ছাশক্তিকে বাস্তবে রূপ দেয়।',
  ];

  /// Builds a deterministic, fully offline Morning Briefing.
  static DailyBriefing generateMorningBriefing({
    required List<TaskItem> tasks,
    required WeatherState weather,
    AlarmItem? firstAlarm,
    bool isBangla = false,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    final greeting = isBangla
        ? (now.hour < 12 ? 'শুভ সকাল' : (now.hour < 17 ? 'শুভ দুপুর' : 'শুভ সন্ধ্যা'))
        : (now.hour < 12 ? 'Good morning' : (now.hour < 17 ? 'Good afternoon' : 'Good evening'));

    final quotes = isBangla ? quotesBn : quotesEn;
    final quote = quotes[now.day % quotes.length];

    final weatherBrief = isBangla
        ? '${weather.cityName}-তে তাপমাত্রা ${weather.temperatureC.toStringAsFixed(1)}°C, আকাশ ${weather.condition.label}।'
        : '${weather.cityName}: ${weather.temperatureC.toStringAsFixed(1)}°C, ${weather.condition.label}.';

    // Prioritize top 3 tasks by dynamic score
    final todayTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => b.computeDynamicScore(now).compareTo(a.computeDynamicScore(now)));

    final topTitles = todayTasks.take(3).map((t) => t.title).toList();
    final totalMinutes = todayTasks.fold(0, (acc, t) => acc + t.estimatedMinutes);

    return DailyBriefing(
      date: now,
      greeting: greeting,
      quote: quote,
      weatherBrief: weatherBrief,
      topTaskTitles: topTitles,
      firstAlarmFormatted: firstAlarm?.timeFormatted,
      totalEstimatedMinutes: totalMinutes,
    );
  }

  /// Returns spoken TTS script for Morning Briefing
  static String generateSpokenMorningBriefing({
    required DailyBriefing briefing,
    String? frogTitle,
    bool isBangla = false,
  }) {
    if (isBangla) {
      return '${briefing.greeting}! ${briefing.weatherBrief} '
          '${frogTitle != null ? 'আজকের প্রধান লক্ষ্য: $frogTitle। ' : ''}'
          'আজকের মোট ${briefing.topTaskTitles.length}টি শীর্ষ কাজ আপনার অপেক্ষায় রয়েছে।';
    } else {
      return '${briefing.greeting}! ${briefing.weatherBrief} '
          '${frogTitle != null ? 'Daily Big Frog target: $frogTitle. ' : ''}'
          'You have ${briefing.topTaskTitles.length} high priority tasks lined up. Master your day.';
    }
  }

  /// Builds an Evening Reflection summary with rollover candidates.
  static EveningReflection generateEveningReview({
    required List<TaskItem> allTasks,
    int moodScore = 4,
    String notes = '',
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final completed = allTasks.where((t) => t.isCompleted).length;
    final pendingTasks = allTasks.where((t) => !t.isCompleted).toList();

    return EveningReflection(
      id: 'reflection_${now.year}_${now.month}_${now.day}',
      date: now,
      completedTasksCount: completed,
      pendingTasksCount: pendingTasks.length,
      moodScore: moodScore,
      reflectionNotes: notes,
      rolloverTaskIds: pendingTasks.map((t) => t.id).toList(),
    );
  }
}
