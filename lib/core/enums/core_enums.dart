enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  bool get isCompleted => this == TaskStatus.completed;
  bool get isActive => this == TaskStatus.pending || this == TaskStatus.inProgress;
}

enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekly,
  monthly,
  customDays,
  afterCompletion;

  bool get isRepeating => this != RecurrenceType.none;
}

enum AlarmChallengeType {
  math,
  memorySequence,
  movement,
  qrScan,
  aiScan;

  String get displayName {
    switch (this) {
      case AlarmChallengeType.math:
        return 'Math Equations';
      case AlarmChallengeType.memorySequence:
        return 'Memory Sequence';
      case AlarmChallengeType.movement:
        return 'Movement (Walk)';
      case AlarmChallengeType.qrScan:
        return 'QR Code Scan';
      case AlarmChallengeType.aiScan:
        return 'AI Camera Vision';
    }
  }

  String get iconName {
    switch (this) {
      case AlarmChallengeType.math:
        return 'calculate';
      case AlarmChallengeType.memorySequence:
        return 'grid_view';
      case AlarmChallengeType.movement:
        return 'directions_walk';
      case AlarmChallengeType.qrScan:
        return 'qr_code_scanner';
      case AlarmChallengeType.aiScan:
        return 'camera_alt';
    }
  }
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard;

  int get mathRounds {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 2;
      case ChallengeDifficulty.medium:
        return 3;
      case ChallengeDifficulty.hard:
        return 5;
    }
  }

  int get memorySequenceLength {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 4;
      case ChallengeDifficulty.medium:
        return 6;
      case ChallengeDifficulty.hard:
        return 8;
    }
  }

  int get requiredSteps {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 15;
      case ChallengeDifficulty.medium:
        return 30;
      case ChallengeDifficulty.hard:
        return 50;
    }
  }
}

enum MemoryKind {
  fact,
  preference,
  episodicSummary;

  String get label {
    switch (this) {
      case MemoryKind.fact:
        return 'Fact';
      case MemoryKind.preference:
        return 'Preference';
      case MemoryKind.episodicSummary:
        return 'Daily Reflection';
    }
  }
}

enum SkyPhase {
  dawn,
  morning,
  afternoon,
  goldenHour,
  dusk,
  night;

  bool get isDark => this == SkyPhase.night || this == SkyPhase.dusk;
}

enum WeatherType {
  clear,
  partlyCloudy,
  overcast,
  rain,
  thunderstorm,
  foggy;

  String get label {
    switch (this) {
      case WeatherType.clear:
        return 'Clear Sky';
      case WeatherType.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherType.overcast:
        return 'Overcast';
      case WeatherType.rain:
        return 'Rain & Showers';
      case WeatherType.thunderstorm:
        return 'Thunderstorm';
      case WeatherType.foggy:
        return 'Misty / Foggy';
    }
  }
}

