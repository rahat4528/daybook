import '../models/sleep_log.dart';

class SleepService {
  final List<SleepLog> _logs = [];

  SleepService({List<SleepLog>? initialLogs}) {
    if (initialLogs != null && initialLogs.isNotEmpty) {
      _logs.addAll(initialLogs);
    } else {
      _seedRealisticWeek();
    }
  }

  List<SleepLog> get logs => List.unmodifiable(_logs);

  void addLog(SleepLog log) {
    _logs.removeWhere((l) => l.id == log.id);
    _logs.add(log);
    _logs.sort((a, b) => b.bedtime.compareTo(a.bedtime)); // Latest first
  }

  /// Calculates cumulative sleep debt over the past 7 logs (in minutes)
  int calculateWeeklySleepDebt({int targetDailyHours = 8}) {
    final recentLogs = _logs.take(7);
    if (recentLogs.isEmpty) return 0;

    int totalDeficit = 0;
    for (final log in recentLogs) {
      totalDeficit += log.sleepDebtMinutes;
    }
    return totalDeficit;
  }

  /// Average sleep duration over available logs
  double getAverageSleepDurationHours() {
    if (_logs.isEmpty) return 0.0;
    final totalMins = _logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    return (totalMins / _logs.length) / 60.0;
  }

  /// Calculates optimal wind-down reminder time based on tomorrow's alarm
  DateTime calculateWindDownTime({
    required int alarmHour,
    required int alarmMinute,
    int targetSleepHours = 8,
    int windDownLeadMinutes = 30,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    var alarmDate = DateTime(now.year, now.month, now.day, alarmHour, alarmMinute);
    if (alarmDate.isBefore(now)) {
      alarmDate = alarmDate.add(const Duration(days: 1));
    }

    final totalLeadMinutes = (targetSleepHours * 60) + windDownLeadMinutes;
    return alarmDate.subtract(Duration(minutes: totalLeadMinutes));
  }

  /// Computes normalized Wake Score (0-100)
  static WakeScoreResult computeWakeScore({
    required int ringToDismissSeconds,
    int snoozeCount = 0,
    bool escapeHatchUsed = false,
    int? minutesToFirstAction,
  }) {
    // 1. Promptness Score (up to 40 pts)
    int promptnessScore = 40;
    final ringMinutes = ringToDismissSeconds / 60.0;
    if (ringMinutes <= 2.0) {
      promptnessScore = 40;
    } else if (ringMinutes <= 5.0) {
      promptnessScore = 30;
    } else if (ringMinutes <= 10.0) {
      promptnessScore = 15;
    } else {
      promptnessScore = 5;
    }

    // 2. Snooze & Escape Penalties
    final snoozePenalty = snoozeCount * 15;
    final escapePenalty = escapeHatchUsed ? 30 : 0;

    // 3. First Action Momentum (up to 30 pts)
    int momentumScore = 15; // default if not recorded
    if (minutesToFirstAction != null) {
      if (minutesToFirstAction <= 15) {
        momentumScore = 30;
      } else if (minutesToFirstAction <= 30) {
        momentumScore = 20;
      } else {
        momentumScore = 10;
      }
    }

    // 4. Base Consistency (30 pts)
    const baseConsistency = 30;

    int totalScore = (baseConsistency + promptnessScore + momentumScore) - (snoozePenalty + escapePenalty);
    totalScore = totalScore.clamp(0, 100);

    final breakdownBangla = 'দ্রুততা: $promptnessScore/৪০, কর্মতৎপরতা: $momentumScore/৩০'
        '${snoozeCount > 0 ? ', স্নুজ কর্তন: -$snoozePenalty' : ''}'
        '${escapeHatchUsed ? ', ইমার্জেন্সি কর্তন: -$escapePenalty' : ''}';

    final breakdownEnglish = 'Promptness: $promptnessScore/40, Action Velocity: $momentumScore/30'
        '${snoozeCount > 0 ? ', Snooze penalty: -$snoozePenalty' : ''}'
        '${escapeHatchUsed ? ', Emergency penalty: -$escapePenalty' : ''}';

    return WakeScoreResult(
      score: totalScore,
      ringToDismissSeconds: ringToDismissSeconds,
      snoozeCount: snoozeCount,
      escapeHatchUsed: escapeHatchUsed,
      minutesToFirstAction: minutesToFirstAction,
      breakdownBangla: breakdownBangla,
      breakdownEnglish: breakdownEnglish,
    );
  }

  void _seedRealisticWeek() {
    final now = DateTime.now();
    for (int i = 1; i <= 6; i++) {
      final day = now.subtract(Duration(days: i));
      // Sleep roughly 11:30 PM to 6:45 AM
      final bedtime = DateTime(day.year, day.month, day.day, 23, 30);
      final wakeTime = DateTime(day.year, day.month, day.day + 1, 6, 45 + (i % 20));
      _logs.add(
        SleepLog(
          id: 'sleep_seed_$i',
          bedtime: bedtime,
          wakeTime: wakeTime,
          qualityRating: 4 + (i % 2 == 0 ? 1 : 0),
          notes: i % 2 == 0 ? 'Felt refreshed and deep sleep' : 'Light restlessness around 4 AM',
        ),
      );
    }
  }
}
