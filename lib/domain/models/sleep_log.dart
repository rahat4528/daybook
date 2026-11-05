class SleepLog {
  final String id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final int qualityRating; // 1 to 5 stars
  final String notes;
  final int targetSleepHours;

  const SleepLog({
    required this.id,
    required this.bedtime,
    required this.wakeTime,
    this.qualityRating = 4,
    this.notes = '',
    this.targetSleepHours = 8,
  });

  /// Duration in minutes
  int get durationMinutes => wakeTime.difference(bedtime).inMinutes;

  /// Duration formatted e.g. "7h 30m"
  String get durationFormatted {
    final mins = durationMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  /// Sleep debt in minutes relative to target (positive means deficit)
  int get sleepDebtMinutes {
    final targetMins = targetSleepHours * 60;
    final deficit = targetMins - durationMinutes;
    return deficit > 0 ? deficit : 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bedtime': bedtime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'qualityRating': qualityRating,
        'notes': notes,
        'targetSleepHours': targetSleepHours,
      };

  factory SleepLog.fromJson(Map<String, dynamic> json) => SleepLog(
        id: json['id'] as String,
        bedtime: DateTime.parse(json['bedtime'] as String),
        wakeTime: DateTime.parse(json['wakeTime'] as String),
        qualityRating: json['qualityRating'] as int? ?? 4,
        notes: json['notes'] as String? ?? '',
        targetSleepHours: json['targetSleepHours'] as int? ?? 8,
      );
}

class WakeScoreResult {
  final int score; // 0-100
  final int ringToDismissSeconds;
  final int snoozeCount;
  final bool escapeHatchUsed;
  final int? minutesToFirstAction;
  final String breakdownBangla;
  final String breakdownEnglish;

  const WakeScoreResult({
    required this.score,
    required this.ringToDismissSeconds,
    this.snoozeCount = 0,
    this.escapeHatchUsed = false,
    this.minutesToFirstAction,
    required this.breakdownBangla,
    required this.breakdownEnglish,
  });
}
