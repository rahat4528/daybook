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
  aiScan,
  typing,
  voicePhrase,
  intentionLine;

  String get displayName {
    switch (this) {
      case AlarmChallengeType.math:
        return 'Math Equations';
      case AlarmChallengeType.memorySequence:
        return 'Memory Sequence (Simon)';
      case AlarmChallengeType.movement:
        return 'Movement (Walk)';
      case AlarmChallengeType.qrScan:
        return 'QR Code Scan';
      case AlarmChallengeType.aiScan:
        return 'AI Camera Vision';
      case AlarmChallengeType.typing:
        return 'Typing Affirmation';
      case AlarmChallengeType.voicePhrase:
        return 'Voice Affirmation';
      case AlarmChallengeType.intentionLine:
        return 'Daily Intention Line';
    }
  }

  String get banglaDisplayName {
    switch (this) {
      case AlarmChallengeType.math:
        return 'গণিত ধাঁধা';
      case AlarmChallengeType.memorySequence:
        return 'মেমোরি সিকোয়েন্স (সাইমন)';
      case AlarmChallengeType.movement:
        return 'হাঁটাচলা (কদম গণনা)';
      case AlarmChallengeType.qrScan:
        return 'কিউআর কোড স্ক্যান';
      case AlarmChallengeType.aiScan:
        return 'এআই ক্যামেরা দৃষ্টি';
      case AlarmChallengeType.typing:
        return 'টাইপিং চ্যালেঞ্জ';
      case AlarmChallengeType.voicePhrase:
        return 'কণ্ঠস্বর বাক্য চ্যালেঞ্জ';
      case AlarmChallengeType.intentionLine:
        return 'দৈনিক সংকল্প বা ফোকাস';
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
      case AlarmChallengeType.typing:
        return 'keyboard';
      case AlarmChallengeType.voicePhrase:
        return 'record_voice_over';
      case AlarmChallengeType.intentionLine:
        return 'edit_note';
    }
  }
}

enum SoundPack {
  classicBell,
  cosmicWaves,
  bengaliFlute,
  gentleHarp,
  roaringThunder;

  String get displayName {
    switch (this) {
      case SoundPack.classicBell:
        return 'Classic Bell';
      case SoundPack.cosmicWaves:
        return 'Cosmic Waves';
      case SoundPack.bengaliFlute:
        return 'Bengali Bamboo Flute';
      case SoundPack.gentleHarp:
        return 'Gentle Harp';
      case SoundPack.roaringThunder:
        return 'Roaring Thunder';
    }
  }

  String get banglaDisplayName {
    switch (this) {
      case SoundPack.classicBell:
        return 'ক্লাসিক ঘণ্টা';
      case SoundPack.cosmicWaves:
        return 'কসমিক তরঙ্গ';
      case SoundPack.bengaliFlute:
        return 'বাংলার বাঁশি';
      case SoundPack.gentleHarp:
        return 'শান্ত হার্প';
      case SoundPack.roaringThunder:
        return 'গর্জনশীল মেঘ';
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

