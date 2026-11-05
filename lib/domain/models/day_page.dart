import 'journal_entry.dart';

class DayPageModel {
  static String formatDayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  final String dayKey; // YYYY-MM-DD
  final DateTime date;
  final String? title;
  final bool isStarred;
  final List<JournalEntry> entries;
  final String? nightlySummary;
  final String? reflectionNote;
  final String? gratitudeNote;
  final int calculatedScore;

  const DayPageModel({
    required this.dayKey,
    required this.date,
    this.title,
    this.isStarred = false,
    this.entries = const [],
    this.nightlySummary,
    this.reflectionNote,
    this.gratitudeNote,
    this.calculatedScore = 0,
  });

  /// 5 Opacity levels of Lime Green (#B6FF00) on black OLED
  /// 0: 15% opacity, 1: 35%, 2: 55%, 3: 75%, 4: 100%
  int get scoreTier {
    final score = calculatedScore > 0 ? calculatedScore : computeDayScore();
    if (score >= 80) return 4;
    if (score >= 60) return 3;
    if (score >= 40) return 2;
    if (score >= 20) return 1;
    return 0;
  }

  double get heatOpacity {
    switch (scoreTier) {
      case 4:
        return 1.0;
      case 3:
        return 0.75;
      case 2:
        return 0.55;
      case 1:
        return 0.35;
      case 0:
      default:
        return 0.15;
    }
  }

  int computeDayScore() {
    int score = 0;

    // Wake quest cleared
    if (entries.any((e) => e.type == EntryType.alarmDismissed)) {
      score += 20;
    }

    // Tasks completed (up to 30 pts)
    final tasksDone = entries.where((e) => e.type == EntryType.taskCompleted).length;
    score += (tasksDone * 10).clamp(0, 30);

    // Habits logged (up to 20 pts)
    final habits = entries.where((e) => e.type == EntryType.habitLogged).length;
    score += (habits * 10).clamp(0, 20);

    // Focus sessions (up to 15 pts)
    final focusSessions = entries.where((e) => e.type == EntryType.focusSession).length;
    score += (focusSessions * 10).clamp(0, 15);

    // Evening reflection or gratitude written (15 pts)
    if ((reflectionNote != null && reflectionNote!.trim().isNotEmpty) ||
        (gratitudeNote != null && gratitudeNote!.trim().isNotEmpty)) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  DayPageModel copyWith({
    String? dayKey,
    DateTime? date,
    String? title,
    bool? isStarred,
    List<JournalEntry>? entries,
    String? nightlySummary,
    String? reflectionNote,
    String? gratitudeNote,
    int? calculatedScore,
  }) {
    return DayPageModel(
      dayKey: dayKey ?? this.dayKey,
      date: date ?? this.date,
      title: title ?? this.title,
      isStarred: isStarred ?? this.isStarred,
      entries: entries ?? this.entries,
      nightlySummary: nightlySummary ?? this.nightlySummary,
      reflectionNote: reflectionNote ?? this.reflectionNote,
      gratitudeNote: gratitudeNote ?? this.gratitudeNote,
      calculatedScore: calculatedScore ?? this.calculatedScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_key': dayKey,
      'date': date.toIso8601String(),
      'title': title,
      'is_starred': isStarred,
      'entries': entries.map((e) => e.toJson()).toList(),
      'nightly_summary': nightlySummary,
      'reflection_note': reflectionNote,
      'gratitude_note': gratitudeNote,
      'calculated_score': calculatedScore,
    };
  }

  factory DayPageModel.fromJson(Map<String, dynamic> json) {
    final entryList = (json['entries'] as List<dynamic>? ?? [])
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return DayPageModel(
      dayKey: json['day_key'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      isStarred: json['is_starred'] == true,
      entries: entryList,
      nightlySummary: json['nightly_summary'] as String?,
      reflectionNote: json['reflection_note'] as String?,
      gratitudeNote: json['gratitude_note'] as String?,
      calculatedScore: json['calculated_score'] as int? ?? 0,
    );
  }
}
