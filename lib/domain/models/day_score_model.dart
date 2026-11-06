import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';

class DayScoreBreakdown {
  final String dayKey;
  final int totalScore;
  final double taskScore;       // Max 30
  final double wakeScore;       // Max 20
  final double focusScore;      // Max 25
  final double habitScore;      // Max 15
  final double reflectionScore; // Max 10
  final int tasksCompleted;
  final int tasksTotal;
  final int focusMinutes;
  final int habitsDone;
  final int habitsTotal;
  final bool hasEveningReview;

  const DayScoreBreakdown({
    required this.dayKey,
    required this.totalScore,
    required this.taskScore,
    required this.wakeScore,
    required this.focusScore,
    required this.habitScore,
    required this.reflectionScore,
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.focusMinutes,
    required this.habitsDone,
    required this.habitsTotal,
    required this.hasEveningReview,
  });

  String gradeLabel({bool isBangla = false}) {
    if (totalScore >= 85) {
      return isBangla ? 'অসাধারণ দিন (Mastery)' : 'Mastery Day';
    } else if (totalScore >= 70) {
      return isBangla ? 'ফলপ্রসূ দিন (Productive)' : 'Solid Productive';
    } else if (totalScore >= 50) {
      return isBangla ? 'মাঝারি দিন (Steady)' : 'Steady Progress';
    } else {
      return isBangla ? 'বিশ্রাম ও প্রস্তুতি (Reset)' : 'Rest & Reset';
    }
  }

  Color get gradeColor {
    if (totalScore >= 70) return AppColors.accentLime;
    if (totalScore >= 50) return const Color(0xFFF59E0B);
    return AppColors.errorRed;
  }

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'totalScore': totalScore,
        'taskScore': taskScore,
        'wakeScore': wakeScore,
        'focusScore': focusScore,
        'habitScore': habitScore,
        'reflectionScore': reflectionScore,
        'tasksCompleted': tasksCompleted,
        'tasksTotal': tasksTotal,
        'focusMinutes': focusMinutes,
        'habitsDone': habitsDone,
        'habitsTotal': habitsTotal,
        'hasEveningReview': hasEveningReview,
      };

  factory DayScoreBreakdown.fromJson(Map<String, dynamic> json) => DayScoreBreakdown(
        dayKey: json['dayKey'] as String,
        totalScore: json['totalScore'] as int,
        taskScore: (json['taskScore'] as num).toDouble(),
        wakeScore: (json['wakeScore'] as num).toDouble(),
        focusScore: (json['focusScore'] as num).toDouble(),
        habitScore: (json['habitScore'] as num).toDouble(),
        reflectionScore: (json['reflectionScore'] as num).toDouble(),
        tasksCompleted: json['tasksCompleted'] as int? ?? 0,
        tasksTotal: json['tasksTotal'] as int? ?? 0,
        focusMinutes: json['focusMinutes'] as int? ?? 0,
        habitsDone: json['habitsDone'] as int? ?? 0,
        habitsTotal: json['habitsTotal'] as int? ?? 0,
        hasEveningReview: json['hasEveningReview'] as bool? ?? false,
      );
}

class WeeklyInsights {
  final List<DayScoreBreakdown> dailyScores;
  final double averageScore;
  final int totalFocusMinutes;
  final int totalTasksCompleted;
  final int totalHabitsCompleted;
  final String peakEnergyPeriod;
  final int bestDayScore;
  final String bestDayKey;

  const WeeklyInsights({
    required this.dailyScores,
    required this.averageScore,
    required this.totalFocusMinutes,
    required this.totalTasksCompleted,
    required this.totalHabitsCompleted,
    required this.peakEnergyPeriod,
    required this.bestDayScore,
    required this.bestDayKey,
  });
}
