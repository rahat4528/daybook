import 'package:flutter/foundation.dart';

enum HabitFrequency {
  daily,
  weekdays,
  customDays,
  weeklyTarget,
}

extension HabitFrequencyExtension on HabitFrequency {
  String label({bool isBangla = false}) {
    switch (this) {
      case HabitFrequency.daily:
        return isBangla ? 'প্রতিদিন' : 'Daily';
      case HabitFrequency.weekdays:
        return isBangla ? 'কাজের দিন (সোম-শুক্র)' : 'Weekdays';
      case HabitFrequency.customDays:
        return isBangla ? 'নির্দিষ্ট দিন' : 'Custom Days';
      case HabitFrequency.weeklyTarget:
        return isBangla ? 'সাপ্তাহিক লক্ষ্য' : 'Weekly Target';
    }
  }
}

@immutable
class HabitItem {
  final String id;
  final String name;
  final String nameBn;
  final String glyph;
  final int targetValue; // e.g. 2000 ml, 10 pages, 1 time
  final String unit; // 'ml', 'pages', 'times', 'mins'
  final HabitFrequency frequency;
  final List<int> customDays; // 1 = Mon ... 7 = Sun
  final int currentStreak;
  final int longestStreak;
  final int freezeTokens; // 0, 1, or max 2
  final String? lastCompletedDayKey;
  final DateTime createdAt;

  const HabitItem({
    required this.id,
    required this.name,
    required this.nameBn,
    this.glyph = '⚡',
    this.targetValue = 1,
    this.unit = 'times',
    this.frequency = HabitFrequency.daily,
    this.customDays = const [1, 2, 3, 4, 5, 6, 7],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.freezeTokens = 0,
    this.lastCompletedDayKey,
    required this.createdAt,
  });

  bool get hasFreezeToken => freezeTokens > 0;

  HabitItem copyWith({
    String? id,
    String? name,
    String? nameBn,
    String? glyph,
    int? targetValue,
    String? unit,
    HabitFrequency? frequency,
    List<int>? customDays,
    int? currentStreak,
    int? longestStreak,
    int? freezeTokens,
    String? lastCompletedDayKey,
    DateTime? createdAt,
  }) {
    return HabitItem(
      id: id ?? this.id,
      name: name ?? this.name,
      nameBn: nameBn ?? this.nameBn,
      glyph: glyph ?? this.glyph,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      freezeTokens: freezeTokens ?? this.freezeTokens,
      lastCompletedDayKey: lastCompletedDayKey ?? this.lastCompletedDayKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameBn': nameBn,
        'glyph': glyph,
        'targetValue': targetValue,
        'unit': unit,
        'frequency': frequency.name,
        'customDays': customDays,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'freezeTokens': freezeTokens,
        'lastCompletedDayKey': lastCompletedDayKey,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    return HabitItem(
      id: json['id'] as String,
      name: json['name'] as String,
      nameBn: json['nameBn'] as String? ?? json['name'] as String,
      glyph: json['glyph'] as String? ?? '⚡',
      targetValue: json['targetValue'] as int? ?? 1,
      unit: json['unit'] as String? ?? 'times',
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      customDays: (json['customDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [1, 2, 3, 4, 5, 6, 7],
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      freezeTokens: json['freezeTokens'] as int? ?? 0,
      lastCompletedDayKey: json['lastCompletedDayKey'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

@immutable
class HabitLog {
  final String id;
  final String habitId;
  final String dayKey;
  final int value;
  final bool isFreezeConsumed;
  final DateTime timestamp;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.dayKey,
    required this.value,
    this.isFreezeConsumed = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'dayKey': dayKey,
        'value': value,
        'isFreezeConsumed': isFreezeConsumed,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      dayKey: json['dayKey'] as String,
      value: json['value'] as int? ?? 1,
      isFreezeConsumed: json['isFreezeConsumed'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
