import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/enums/core_enums.dart';

class ChallengeResult {
  final bool isSuccess;
  final String? errorMessageBangla;
  final String? errorMessageEnglish;
  final bool requiresReplay;

  const ChallengeResult({
    required this.isSuccess,
    this.errorMessageBangla,
    this.errorMessageEnglish,
    this.requiresReplay = false,
  });

  static const success = ChallengeResult(isSuccess: true);
}

abstract class WakeChallenge {
  AlarmChallengeType get type;
  ChallengeDifficulty get difficulty;
  bool get isCompleted;

  String get titleBangla;
  String get titleEnglish;
  String get instructionsBangla;
  String get instructionsEnglish;

  ChallengeResult verify(dynamic input);
  void reset();
}

// -----------------------------------------------------------------------------
// 1. Math Challenge
// -----------------------------------------------------------------------------
class MathProblem {
  final String question;
  final int answer;

  const MathProblem({required this.question, required this.answer});
}

class MathChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  late final List<MathProblem> problems;
  int _currentProblemIndex = 0;
  bool _isCompleted = false;

  MathChallenge({this.difficulty = ChallengeDifficulty.medium, List<MathProblem>? pregenerated}) {
    problems = pregenerated ?? _generateProblems();
  }

  @override
  AlarmChallengeType get type => AlarmChallengeType.math;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'গণিত ধাঁধা';

  @override
  String get titleEnglish => 'Math Awakening';

  @override
  String get instructionsBangla => 'অ্যালার্ম বন্ধ করতে সঠিক উত্তর দিন (${_currentProblemIndex + 1}/${problems.length})';

  @override
  String get instructionsEnglish => 'Solve correctly to dismiss (${_currentProblemIndex + 1}/${problems.length})';

  MathProblem get currentProblem => problems[_currentProblemIndex];

  int get totalProblems => problems.length;
  int get currentProblemIndex => _currentProblemIndex;

  List<MathProblem> _generateProblems() {
    final count = difficulty.mathRounds;
    final list = <MathProblem>[];

    for (int i = 0; i < count; i++) {
      switch (difficulty) {
        case ChallengeDifficulty.easy:
          final a = 15 + ((i * 17) % 70);
          final b = 12 + ((i * 13) % 40);
          list.add(MathProblem(question: '$a + $b', answer: a + b));
          break;
        case ChallengeDifficulty.medium:
          final a = 4 + ((i * 3) % 9);
          final b = 6 + ((i * 7) % 8);
          final c = 10 + (i * 5);
          list.add(MathProblem(question: '($a × $b) + $c', answer: (a * b) + c));
          break;
        case ChallengeDifficulty.hard:
          final a = 7 + ((i * 5) % 11);
          final b = 6 + ((i * 4) % 9);
          final c = 14 + (i * 8);
          final d = 5 + (i * 2);
          list.add(MathProblem(question: '($a × $b) - ($c + $d)', answer: (a * b) - (c + d)));
          break;
      }
    }
    return list;
  }

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;
    final int? parsedAnswer = input is int ? input : int.tryParse(input.toString().trim());

    if (parsedAnswer == null) {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'অনুগ্রহ করে সঠিক সংখ্যা লিখুন।',
        errorMessageEnglish: 'Please enter a valid numeric value.',
      );
    }

    if (parsedAnswer == currentProblem.answer) {
      _currentProblemIndex++;
      if (_currentProblemIndex >= problems.length) {
        _isCompleted = true;
      }
      return ChallengeResult.success;
    } else {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'ভুল উত্তর! আবার চেষ্টা করুন।',
        errorMessageEnglish: 'Incorrect answer! Calculate carefully.',
      );
    }
  }

  @override
  void reset() {
    _currentProblemIndex = 0;
    _isCompleted = false;
  }
}

// -----------------------------------------------------------------------------
// 2. Simon 3x3 Memory Sequence Challenge
// -----------------------------------------------------------------------------
class MemorySequenceChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  late final List<int> targetSequence; // grid indexes 0..8
  final List<int> _userSequence = [];
  bool _isCompleted = false;

  MemorySequenceChallenge({
    this.difficulty = ChallengeDifficulty.medium,
    List<int>? pregeneratedSequence,
  }) {
    targetSequence = pregeneratedSequence ?? _generateSequence();
  }

  @override
  AlarmChallengeType get type => AlarmChallengeType.memorySequence;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'মেমোরি সিকোয়েন্স (৩x৩)';

  @override
  String get titleEnglish => 'Simon 3x3 Memory';

  @override
  String get instructionsBangla => 'প্যাটার্নটি লক্ষ্য করুন এবং হুবহু পুনরাবৃত্তি করুন (${targetSequence.length} ধাপ)';

  @override
  String get instructionsEnglish => 'Observe the pattern and reproduce it exactly (${targetSequence.length} steps)';

  List<int> get userSequence => List.unmodifiable(_userSequence);

  List<int> _generateSequence() {
    final len = difficulty.memorySequenceLength;
    final list = <int>[];
    // Deterministic pseudo-random sequence across 3x3 grid (0..8)
    int seed = 4;
    for (int i = 0; i < len; i++) {
      seed = (seed * 7 + 3) % 9;
      list.add(seed);
    }
    return list;
  }

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;
    final int? tappedIndex = input is int ? input : int.tryParse(input.toString());

    if (tappedIndex == null || tappedIndex < 0 || tappedIndex > 8) {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'অবৈধ গ্রিড বোতাম!',
        errorMessageEnglish: 'Invalid grid button!',
      );
    }

    final expectedIndex = targetSequence[_userSequence.length];
    if (tappedIndex == expectedIndex) {
      _userSequence.add(tappedIndex);
      if (_userSequence.length == targetSequence.length) {
        _isCompleted = true;
      }
      return ChallengeResult.success;
    } else {
      // Mistake! Reset user attempts and trigger replay
      _userSequence.clear();
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'ভুল সিকোয়েন্স! প্যাটার্নটি পুনরায় প্রদর্শিত হচ্ছে...',
        errorMessageEnglish: 'Wrong step! Replaying the pattern...',
        requiresReplay: true,
      );
    }
  }

  @override
  void reset() {
    _userSequence.clear();
    _isCompleted = false;
  }
}

// -----------------------------------------------------------------------------
// 3. Movement (Step Detector & Accelerometer Fallback) Challenge
// -----------------------------------------------------------------------------
class MovementChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  late final int targetSteps;
  int _currentSteps = 0;
  bool _isCompleted = false;

  MovementChallenge({this.difficulty = ChallengeDifficulty.medium, int? customTargetSteps}) {
    targetSteps = customTargetSteps ?? difficulty.requiredSteps;
  }

  @override
  AlarmChallengeType get type => AlarmChallengeType.movement;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'হাঁটুন এবং জেগে উঠুন';

  @override
  String get titleEnglish => 'Step Awakening';

  @override
  String get instructionsBangla => 'ফোনটি হাতে নিয়ে হাঁটুন ($targetSteps কদম বাকি: ${targetSteps - _currentSteps})';

  @override
  String get instructionsEnglish => 'Walk with phone in hand ($targetSteps steps total, $_currentSteps/$targetSteps)';

  int get currentSteps => _currentSteps;

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;

    // Accepts either step increment or raw accelerometer magnitude
    if (input is int) {
      _currentSteps += input;
    } else if (input is double) {
      // Fallback accelerometer peak detection: magnitude > 12.0 m/s^2 indicates step
      if (input >= 12.0) {
        _currentSteps += 1;
      }
    }

    if (_currentSteps >= targetSteps) {
      _isCompleted = true;
      return ChallengeResult.success;
    }

    return ChallengeResult.success;
  }

  @override
  void reset() {
    _currentSteps = 0;
    _isCompleted = false;
  }
}

// -----------------------------------------------------------------------------
// 4. QR / Barcode Scan Challenge
// -----------------------------------------------------------------------------
class QrScanChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  final String expectedHash; // SHA-256 of target code
  bool _isCompleted = false;

  QrScanChallenge({
    required this.expectedHash,
    this.difficulty = ChallengeDifficulty.medium,
  });

  @override
  AlarmChallengeType get type => AlarmChallengeType.qrScan;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'কিউআর কোড স্ক্যান';

  @override
  String get titleEnglish => 'QR Code Verification';

  @override
  String get instructionsBangla => 'আপনার নিবন্ধিত কিউআর বা বারকোড স্ক্যান করুন (যেমন: টুথপেস্ট বা রান্নাঘর)';

  @override
  String get instructionsEnglish => 'Scan your registered QR or barcode (e.g. bathroom or coffee maker)';

  static String hashValue(String raw) {
    return sha256.convert(utf8.encode(raw.trim())).toString();
  }

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;
    final scannedRaw = input?.toString() ?? '';
    final scannedHash = hashValue(scannedRaw);

    if (scannedHash.toLowerCase() == expectedHash.toLowerCase()) {
      _isCompleted = true;
      return ChallengeResult.success;
    } else {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'ভুল কিউআর কোড! নিবন্ধিত কোডটি স্ক্যান করুন।',
        errorMessageEnglish: 'Code mismatch! Scan the registered target barcode.',
      );
    }
  }

  @override
  void reset() {
    _isCompleted = false;
  }
}

// -----------------------------------------------------------------------------
// 5. On-Device AI Camera Vision Challenge (Spoof-Resistant)
// -----------------------------------------------------------------------------
class AiVisionFrameResult {
  final String label;
  final double confidence;
  final double cameraGyroDelta; // Motion vector magnitude to reject static screens/photos

  const AiVisionFrameResult({
    required this.label,
    required this.confidence,
    required this.cameraGyroDelta,
  });
}

class AiVisionChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  final String targetLabel; // e.g. "coffee mug", "toothbrush", "sink", "book"
  final int requiredConsecutiveFrames;
  final double confidenceThreshold;

  int _consecutiveValidFrames = 0;
  bool _hasMotionConfirmed = false;
  bool _isCompleted = false;

  AiVisionChallenge({
    required this.targetLabel,
    this.difficulty = ChallengeDifficulty.medium,
    this.requiredConsecutiveFrames = 3,
    this.confidenceThreshold = 0.70,
  });

  @override
  AlarmChallengeType get type => AlarmChallengeType.aiScan;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'এআই ক্যামেরা দৃষ্টি';

  @override
  String get titleEnglish => 'AI Object Vision';

  @override
  String get instructionsBangla => 'ক্যামেরাটি "$targetLabel" এর দিকে ধরুন এবং সামান্য নাড়াচাড়া করুন';

  @override
  String get instructionsEnglish => 'Point camera at "$targetLabel" and move slightly (Anti-spoofing)';

  int get confirmedFrames => _consecutiveValidFrames;

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;

    if (input is! AiVisionFrameResult) {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'ক্যামেরা ফ্রেম বিশ্লেষণ ব্যর্থ।',
        errorMessageEnglish: 'Camera frame processing failed.',
      );
    }

    final isLabelMatch = input.label.toLowerCase().contains(targetLabel.toLowerCase());
    final isConfidenceHigh = input.confidence >= confidenceThreshold;
    final hasMotion = input.cameraGyroDelta >= 0.04;

    if (hasMotion) {
      _hasMotionConfirmed = true;
    }

    if (isLabelMatch && isConfidenceHigh) {
      _consecutiveValidFrames++;
      if (_consecutiveValidFrames >= requiredConsecutiveFrames && _hasMotionConfirmed) {
        _isCompleted = true;
        return ChallengeResult.success;
      }
    } else {
      _consecutiveValidFrames = 0; // Reset consecutive requirement
    }

    return ChallengeResult.success;
  }

  @override
  void reset() {
    _consecutiveValidFrames = 0;
    _hasMotionConfirmed = false;
    _isCompleted = false;
  }
}

// -----------------------------------------------------------------------------
// 6. Typing Affirmation Challenge
// -----------------------------------------------------------------------------
class TypingChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  final bool isBangla;
  late final String targetPhrase;
  bool _isCompleted = false;

  TypingChallenge({
    this.difficulty = ChallengeDifficulty.medium,
    this.isBangla = true,
    String? customPhrase,
  }) {
    targetPhrase = customPhrase ??
        (isBangla
            ? 'আজকের দিনটি নতুন সুযোগ এবং আমি সম্পূর্ণ প্রস্তুত।'
            : 'Today is a brand new opportunity and I am fully prepared.');
  }

  @override
  AlarmChallengeType get type => AlarmChallengeType.typing;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'টাইপিং চ্যালেঞ্জ';

  @override
  String get titleEnglish => 'Typing Affirmation';

  @override
  String get instructionsBangla => 'নিচের বাক্যটি হুবহু টাইপ করুন:';

  @override
  String get instructionsEnglish => 'Type the following affirmation accurately:';

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;
    final text = input?.toString().trim() ?? '';

    if (text == targetPhrase.trim()) {
      _isCompleted = true;
      return ChallengeResult.success;
    } else {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'বানান বা বিরামচিহ্ন মেলেনি! সতর্কভাবে টাইপ করুন।',
        errorMessageEnglish: 'Text does not match! Verify spelling and punctuation.',
      );
    }
  }

  @override
  void reset() {
    _isCompleted = false;
  }
}

// -----------------------------------------------------------------------------
// 7. Voice Phrase Challenge (Speech Recognition with Typed Fallback)
// -----------------------------------------------------------------------------
class VoicePhraseChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  final bool isBangla;
  late final String expectedPhrase;
  bool _isCompleted = false;

  VoicePhraseChallenge({
    this.difficulty = ChallengeDifficulty.medium,
    this.isBangla = true,
    String? customPhrase,
  }) {
    expectedPhrase = customPhrase ??
        (isBangla ? 'আমি পুরোপুরি জেগে উঠেছি' : 'I am awake and focused');
  }

  @override
  AlarmChallengeType get type => AlarmChallengeType.voicePhrase;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'কণ্ঠস্বর বাক্য চ্যালেঞ্জ';

  @override
  String get titleEnglish => 'Voice Wake Phrase';

  @override
  String get instructionsBangla => 'মাইক্রোফোনে স্পষ্ট করে বলুন: "$expectedPhrase"';

  @override
  String get instructionsEnglish => 'Speak clearly into microphone: "$expectedPhrase"';

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;
    final text = input?.toString().toLowerCase().trim() ?? '';

    // Check matching ratio
    final wordsExpected = expectedPhrase.toLowerCase().split(' ');
    final matchedWords = wordsExpected.where((w) => text.contains(w)).length;
    final matchScore = matchedWords / wordsExpected.length;

    if (matchScore >= 0.70 || text == expectedPhrase.toLowerCase().trim()) {
      _isCompleted = true;
      return ChallengeResult.success;
    } else {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'কণ্ঠস্বর স্পষ্টভাবে সনাক্ত করা যায়নি। প্রয়োজনে টাইপ করুন।',
        errorMessageEnglish: 'Voice not recognized clearly. You may type to verify.',
      );
    }
  }

  @override
  void reset() {
    _isCompleted = false;
  }
}

// -----------------------------------------------------------------------------
// 8. Daily Intention Line Challenge (Writes directly to Day Page!)
// -----------------------------------------------------------------------------
class IntentionLineChallenge implements WakeChallenge {
  @override
  final ChallengeDifficulty difficulty;
  final bool isBangla;
  String? capturedIntention;
  bool _isCompleted = false;

  IntentionLineChallenge({
    this.difficulty = ChallengeDifficulty.medium,
    this.isBangla = true,
  });

  @override
  AlarmChallengeType get type => AlarmChallengeType.intentionLine;

  @override
  bool get isCompleted => _isCompleted;

  @override
  String get titleBangla => 'আজকের মূল সংকল্প (Intention)';

  @override
  String get titleEnglish => 'Daily Focus Intention';

  @override
  String get instructionsBangla => 'আজকের প্রধান লক্ষ্য বা ফোকাস কী? লিখে দিন:';

  @override
  String get instructionsEnglish => 'What is your single most important priority today? Write it down:';

  @override
  ChallengeResult verify(dynamic input) {
    if (_isCompleted) return ChallengeResult.success;
    final text = input?.toString().trim() ?? '';

    if (text.length >= 4) {
      capturedIntention = text;
      _isCompleted = true;
      return ChallengeResult.success;
    } else {
      return const ChallengeResult(
        isSuccess: false,
        errorMessageBangla: 'কমপক্ষে ৪ অক্ষরের সংকল্প লিখুন।',
        errorMessageEnglish: 'Write at least 4 characters for your focus.',
      );
    }
  }

  @override
  void reset() {
    capturedIntention = null;
    _isCompleted = false;
  }
}
