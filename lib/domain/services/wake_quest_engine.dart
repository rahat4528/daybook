import '../challenges/wake_challenge.dart';
import '../models/alarm_item.dart';
import '../../core/enums/core_enums.dart';

class WakeQuestEngine {
  final AlarmItem alarm;
  final bool isBangla;
  final DateTime startTime;

  late final List<WakeChallenge> challengeChain;
  int _currentChallengeIndex = 0;
  int _totalAttempts = 0;
  int _failedAttempts = 0;
  bool _isAlarmRinging = true;
  bool _isChainComplete = false;
  bool _escapeHatchUsed = false;
  DateTime? _dismissedTime;

  static const int maxFailedAttemptsBeforeEscape = 5;
  static const int maxMinutesBeforeEscape = 15;

  WakeQuestEngine({
    required this.alarm,
    this.isBangla = false,
    DateTime? simulatedStartTime,
    List<WakeChallenge>? customChain,
  }) : startTime = simulatedStartTime ?? DateTime.now() {
    challengeChain = customChain ?? _buildChallengeChain();
  }

  List<WakeChallenge> _buildChallengeChain() {
    final types = alarm.effectiveChallengeChain;
    final list = <WakeChallenge>[];

    for (final type in types) {
      switch (type) {
        case AlarmChallengeType.math:
          list.add(MathChallenge(difficulty: alarm.difficulty));
          break;
        case AlarmChallengeType.memorySequence:
          list.add(MemorySequenceChallenge(difficulty: alarm.difficulty));
          break;
        case AlarmChallengeType.movement:
          list.add(MovementChallenge(difficulty: alarm.difficulty, customTargetSteps: alarm.minSteps));
          break;
        case AlarmChallengeType.qrScan:
          list.add(QrScanChallenge(expectedHash: alarm.qrHash ?? QrScanChallenge.hashValue('DAYBOOK_DEFAULT_KEY')));
          break;
        case AlarmChallengeType.aiScan:
          list.add(AiVisionChallenge(targetLabel: alarm.aiTargetLabel ?? 'coffee mug', difficulty: alarm.difficulty));
          break;
        case AlarmChallengeType.typing:
          list.add(TypingChallenge(difficulty: alarm.difficulty, isBangla: isBangla));
          break;
        case AlarmChallengeType.voicePhrase:
          list.add(VoicePhraseChallenge(difficulty: alarm.difficulty, isBangla: isBangla));
          break;
        case AlarmChallengeType.intentionLine:
          list.add(IntentionLineChallenge(difficulty: alarm.difficulty, isBangla: isBangla));
          break;
      }
    }

    if (list.isEmpty) {
      list.add(MathChallenge(difficulty: alarm.difficulty));
    }
    return list;
  }

  // Getters
  int get currentChallengeIndex => _currentChallengeIndex;
  int get totalChallenges => challengeChain.length;
  WakeChallenge get currentChallenge => challengeChain[_currentChallengeIndex];
  bool get isAlarmRinging => _isAlarmRinging;
  bool get isChainComplete => _isChainComplete;
  bool get escapeHatchUsed => _escapeHatchUsed;
  int get totalAttempts => _totalAttempts;
  int get failedAttempts => _failedAttempts;
  DateTime? get dismissedTime => _dismissedTime;

  /// Returns whether the safety escape hatch is currently unlocked
  bool isEscapeHatchUnlocked([DateTime? referenceTime]) {
    if (_isChainComplete) return false;
    final now = referenceTime ?? DateTime.now();
    final elapsedMinutes = now.difference(startTime).inMinutes;

    return _failedAttempts >= maxFailedAttemptsBeforeEscape || elapsedMinutes >= maxMinutesBeforeEscape;
  }

  /// Calculates dynamic sunrise glow factor (0.0 to 1.0)
  double getSunriseGlowFactor([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    final elapsedSeconds = now.difference(startTime).inSeconds;
    // Ramps over 60 seconds
    return (elapsedSeconds / 60.0).clamp(0.0, 1.0);
  }

  /// Verifies current challenge input
  ChallengeResult submitChallengeInput(dynamic input, [DateTime? completionTime]) {
    if (_isChainComplete) return ChallengeResult.success;

    _totalAttempts++;
    final result = currentChallenge.verify(input);

    if (result.isSuccess && currentChallenge.isCompleted) {
      // Step passed! Check if chain has more challenges
      if (_currentChallengeIndex < challengeChain.length - 1) {
        _currentChallengeIndex++;
        return ChallengeResult.success;
      } else {
        // Entire chain finished!
        _isChainComplete = true;
        _isAlarmRinging = false;
        _dismissedTime = completionTime ?? DateTime.now();
        return ChallengeResult.success;
      }
    } else if (!result.isSuccess) {
      _failedAttempts++;
    }

    return result;
  }

  /// Emergency safe dismiss (Requires escape hatch unlock)
  bool emergencySafeDismiss([DateTime? dismissTime]) {
    final now = dismissTime ?? DateTime.now();
    if (!isEscapeHatchUnlocked(now)) {
      return false;
    }

    _escapeHatchUsed = true;
    _isAlarmRinging = false;
    _isChainComplete = true;
    _dismissedTime = now;
    return true;
  }

  /// Personalized Text-to-Speech Greeting
  String generateTtsGreeting() {
    if (isBangla) {
      return 'শুভ সকাল! আপনার ওয়েক কোয়েস্ট সফলভাবে সমাপ্ত হয়েছে। আজকের দিনটি নতুন সম্ভাবনায় ভরে উঠুক।';
    } else {
      return 'Good morning! Wake Quest successfully conquered. You are wide awake and ready to seize today.';
    }
  }

  /// Exports history event for analytical audit
  AlarmHistoryEvent toHistoryEvent() {
    return AlarmHistoryEvent(
      id: 'evt_${DateTime.now().microsecondsSinceEpoch}',
      alarmId: alarm.id,
      firedAt: startTime,
      dismissedAt: _dismissedTime,
      challengeType: currentChallenge.type,
      isDismissed: _isChainComplete,
      attemptCount: _totalAttempts,
      escapeHatchUsed: _escapeHatchUsed,
    );
  }
}
