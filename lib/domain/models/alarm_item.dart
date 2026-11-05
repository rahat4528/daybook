import '../../core/enums/core_enums.dart';

class AlarmItem {
  final String id;
  final int hour; // 0-23
  final int minute; // 0-59
  final String label;
  final bool isEnabled;
  final List<int> repeatDays; // 1=Mon ... 7=Sun, empty = once
  final AlarmChallengeType challengeType;
  final ChallengeDifficulty difficulty;
  final String ringtone;
  final bool vibrate;
  final String? qrHash;
  final String? aiTargetLabel;
  final int minSteps;
  final bool snoozeAllowed;

  const AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = 'Alarm',
    this.isEnabled = true,
    this.repeatDays = const [],
    this.challengeType = AlarmChallengeType.math,
    this.difficulty = ChallengeDifficulty.medium,
    this.ringtone = 'Sunrise Symphony',
    this.vibrate = true,
    this.qrHash,
    this.aiTargetLabel,
    this.minSteps = 20,
    this.snoozeAllowed = true,
  });

  String get timeFormatted {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// Calculates the next DateTime when this alarm will trigger.
  DateTime getNextTrigger([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);

    if (repeatDays.isEmpty) {
      if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    // Alarm repeats on specific weekdays
    for (int i = 0; i < 8; i++) {
      final testDate = DateTime(now.year, now.month, now.day + i, hour, minute);
      final weekday = testDate.weekday; // 1=Mon, 7=Sun
      if (repeatDays.contains(weekday)) {
        if (testDate.isAfter(now)) {
          return testDate;
        }
      }
    }

    return candidate.add(const Duration(days: 7));
  }

  AlarmItem copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
    AlarmChallengeType? challengeType,
    ChallengeDifficulty? difficulty,
    String? ringtone,
    bool? vibrate,
    String? qrHash,
    String? aiTargetLabel,
    int? minSteps,
    bool? snoozeAllowed,
  }) {
    return AlarmItem(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      challengeType: challengeType ?? this.challengeType,
      difficulty: difficulty ?? this.difficulty,
      ringtone: ringtone ?? this.ringtone,
      vibrate: vibrate ?? this.vibrate,
      qrHash: qrHash ?? this.qrHash,
      aiTargetLabel: aiTargetLabel ?? this.aiTargetLabel,
      minSteps: minSteps ?? this.minSteps,
      snoozeAllowed: snoozeAllowed ?? this.snoozeAllowed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'isEnabled': isEnabled,
        'repeatDays': repeatDays,
        'challengeType': challengeType.index,
        'difficulty': difficulty.index,
        'ringtone': ringtone,
        'vibrate': vibrate,
        'qrHash': qrHash,
        'aiTargetLabel': aiTargetLabel,
        'minSteps': minSteps,
        'snoozeAllowed': snoozeAllowed,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) => AlarmItem(
        id: json['id'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        label: json['label'] as String? ?? 'Alarm',
        isEnabled: json['isEnabled'] as bool? ?? true,
        repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
        challengeType: AlarmChallengeType.values[json['challengeType'] as int? ?? 0],
        difficulty: ChallengeDifficulty.values[json['difficulty'] as int? ?? 1],
        ringtone: json['ringtone'] as String? ?? 'Sunrise Symphony',
        vibrate: json['vibrate'] as bool? ?? true,
        qrHash: json['qrHash'] as String?,
        aiTargetLabel: json['aiTargetLabel'] as String?,
        minSteps: json['minSteps'] as int? ?? 20,
        snoozeAllowed: json['snoozeAllowed'] as bool? ?? true,
      );
}

class AlarmHistoryEvent {
  final String id;
  final String alarmId;
  final DateTime firedAt;
  final DateTime? dismissedAt;
  final AlarmChallengeType challengeType;
  final bool isDismissed;
  final int attemptCount;

  const AlarmHistoryEvent({
    required this.id,
    required this.alarmId,
    required this.firedAt,
    this.dismissedAt,
    required this.challengeType,
    this.isDismissed = false,
    this.attemptCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'alarmId': alarmId,
        'firedAt': firedAt.toIso8601String(),
        'dismissedAt': dismissedAt?.toIso8601String(),
        'challengeType': challengeType.index,
        'isDismissed': isDismissed,
        'attemptCount': attemptCount,
      };

  factory AlarmHistoryEvent.fromJson(Map<String, dynamic> json) =>
      AlarmHistoryEvent(
        id: json['id'] as String,
        alarmId: json['alarmId'] as String,
        firedAt: DateTime.parse(json['firedAt'] as String),
        dismissedAt: json['dismissedAt'] != null
            ? DateTime.parse(json['dismissedAt'] as String)
            : null,
        challengeType: AlarmChallengeType.values[json['challengeType'] as int? ?? 0],
        isDismissed: json['isDismissed'] as bool? ?? false,
        attemptCount: json['attemptCount'] as int? ?? 1,
      );
}

