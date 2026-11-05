import 'package:flutter/foundation.dart';

@immutable
class MoodLog {
  final String id;
  final int moodScore; // 1 (Rough) to 5 (Radiant)
  final int energyScore; // 1 (Depleted) to 5 (Electric)
  final List<String> tags; // 'Sleep', 'Work', 'Family', 'Weather', 'Health', etc.
  final String? reflection;
  final String dayKey;
  final DateTime timestamp;

  const MoodLog({
    required this.id,
    required this.moodScore,
    required this.energyScore,
    this.tags = const [],
    this.reflection,
    required this.dayKey,
    required this.timestamp,
  });

  String moodLabel({bool isBangla = false}) {
    switch (moodScore) {
      case 5:
        return isBangla ? 'অসাধারণ (৫/৫)' : 'Radiant (5/5)';
      case 4:
        return isBangla ? 'ভালো (৪/৫)' : 'Good (4/5)';
      case 3:
        return isBangla ? 'স্বাভাবিক (৩/৫)' : 'Neutral (3/5)';
      case 2:
        return isBangla ? 'খারাপ (২/৫)' : 'Low (2/5)';
      case 1:
      default:
        return isBangla ? 'কঠিন (১/৫)' : 'Rough (1/5)';
    }
  }

  String energyLabel({bool isBangla = false}) {
    switch (energyScore) {
      case 5:
        return isBangla ? 'উচ্চ শক্তি (৫/৫)' : 'Electric (5/5)';
      case 4:
        return isBangla ? 'সতেজ (৪/৫)' : 'Energized (4/5)';
      case 3:
        return isBangla ? 'পরিমিত (৩/৫)' : 'Steady (3/5)';
      case 2:
        return isBangla ? 'ক্লান্ত (২/৫)' : 'Drained (2/5)';
      case 1:
      default:
        return isBangla ? 'ক্লান্ত-অবসন্ন (১/৫)' : 'Depleted (1/5)';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'moodScore': moodScore,
        'energyScore': energyScore,
        'tags': tags,
        'reflection': reflection,
        'dayKey': dayKey,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    return MoodLog(
      id: json['id'] as String,
      moodScore: json['moodScore'] as int? ?? 3,
      energyScore: json['energyScore'] as int? ?? 3,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      reflection: json['reflection'] as String?,
      dayKey: json['dayKey'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
