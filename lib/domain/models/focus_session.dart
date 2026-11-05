import 'package:flutter/foundation.dart';

enum FocusSoundscape {
  silence,
  rainOnTinRoof,
  whiteNoise,
  binauralBeats,
  monochromeStatic,
}

extension FocusSoundscapeExtension on FocusSoundscape {
  String label({bool isBangla = false}) {
    switch (this) {
      case FocusSoundscape.silence:
        return isBangla ? 'নিস্তব্ধতা' : 'Deep Silence';
      case FocusSoundscape.rainOnTinRoof:
        return isBangla ? 'টিনের চালে বৃষ্টি' : 'Rain on Tin Roof';
      case FocusSoundscape.whiteNoise:
        return isBangla ? 'হোয়াইট নয়েজ' : 'White Noise';
      case FocusSoundscape.binauralBeats:
        return isBangla ? 'বাইনোরাল ফোকাস (৪০ হার্টজ)' : 'Binaural 40Hz Tone';
      case FocusSoundscape.monochromeStatic:
        return isBangla ? 'মনোক্রোম স্ট্যাটিক' : 'Monochrome Static';
    }
  }

  String get glyph {
    switch (this) {
      case FocusSoundscape.silence:
        return '🔇';
      case FocusSoundscape.rainOnTinRoof:
        return '🌧️';
      case FocusSoundscape.whiteNoise:
        return '〰️';
      case FocusSoundscape.binauralBeats:
        return '🎧';
      case FocusSoundscape.monochromeStatic:
        return '▦';
    }
  }
}

enum FocusState {
  idle,
  running,
  paused,
  breakTime,
  completed,
}

@immutable
class FocusSession {
  final String id;
  final String? taskId;
  final String taskTitle;
  final int targetMinutes;
  final int actualMinutes;
  final int interruptions;
  final FocusSoundscape soundscape;
  final bool wasCompleted;
  final String dayKey;
  final DateTime startedAt;
  final DateTime? endedAt;

  const FocusSession({
    required this.id,
    this.taskId,
    required this.taskTitle,
    required this.targetMinutes,
    this.actualMinutes = 0,
    this.interruptions = 0,
    this.soundscape = FocusSoundscape.silence,
    this.wasCompleted = false,
    required this.dayKey,
    required this.startedAt,
    this.endedAt,
  });

  /// Quality score from 0.0 to 1.0 (penalized by interruptions)
  double get qualityScore {
    if (!wasCompleted && actualMinutes == 0) return 0.0;
    final score = 1.0 - (interruptions * 0.15);
    return score.clamp(0.2, 1.0);
  }

  FocusSession copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    int? targetMinutes,
    int? actualMinutes,
    int? interruptions,
    FocusSoundscape? soundscape,
    bool? wasCompleted,
    String? dayKey,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      interruptions: interruptions ?? this.interruptions,
      soundscape: soundscape ?? this.soundscape,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      dayKey: dayKey ?? this.dayKey,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'targetMinutes': targetMinutes,
        'actualMinutes': actualMinutes,
        'interruptions': interruptions,
        'soundscape': soundscape.name,
        'wasCompleted': wasCompleted,
        'dayKey': dayKey,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle'] as String? ?? 'General Deep Work',
      targetMinutes: json['targetMinutes'] as int? ?? 25,
      actualMinutes: json['actualMinutes'] as int? ?? 0,
      interruptions: json['interruptions'] as int? ?? 0,
      soundscape: FocusSoundscape.values.firstWhere(
        (e) => e.name == json['soundscape'],
        orElse: () => FocusSoundscape.silence,
      ),
      wasCompleted: json['wasCompleted'] as bool? ?? false,
      dayKey: json['dayKey'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
    );
  }
}
