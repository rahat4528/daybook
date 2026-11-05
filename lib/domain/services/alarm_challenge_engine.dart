import 'dart:math';
import '../../core/enums/core_enums.dart';

class MathEquation {
  final String question;
  final int answer;

  const MathEquation({required this.question, required this.answer});
}

class AlarmChallengeEngine {
  final Random _random;

  AlarmChallengeEngine([Random? random]) : _random = random ?? Random();

  /// Generates a math equation based on difficulty.
  MathEquation generateMathEquation(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        final a = _random.nextInt(35) + 10;
        final b = _random.nextInt(35) + 5;
        final isAdd = _random.nextBool();
        return isAdd
            ? MathEquation(question: '$a + $b', answer: a + b)
            : MathEquation(question: '$a - $b', answer: a - b);

      case ChallengeDifficulty.medium:
        final a = _random.nextInt(11) + 4; // 4 to 14
        final b = _random.nextInt(12) + 3; // 3 to 14
        final c = _random.nextInt(25) + 5;
        return MathEquation(question: '($a × $b) + $c', answer: (a * b) + c);

      case ChallengeDifficulty.hard:
        final a = _random.nextInt(15) + 6;
        final b = _random.nextInt(12) + 4;
        final c = _random.nextInt(30) + 10;
        final d = _random.nextInt(20) + 2;
        return MathEquation(
          question: '($a × $b) - ($c + $d)',
          answer: (a * b) - (c + d),
        );
    }
  }

  /// Generates a randomized Simon sequence for 3x3 grid (cells 0 to 8).
  List<int> generateMemorySequence(ChallengeDifficulty difficulty) {
    final length = difficulty.memorySequenceLength;
    final List<int> sequence = [];
    int last = -1;

    for (int i = 0; i < length; i++) {
      int next;
      do {
        next = _random.nextInt(9);
      } while (next == last && length > 2); // Avoid consecutive repeats for variety
      sequence.add(next);
      last = next;
    }
    return sequence;
  }

  /// Verifies memory sequence user input.
  bool verifyMemorySequence(List<int> expected, List<int> actual) {
    if (expected.length != actual.length) return false;
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] != actual[i]) return false;
    }
    return true;
  }

  /// Verifies scanned QR code payload against stored hash.
  bool verifyQrCode(String scannedValue, String expectedHash) {
    final normalizedScanned = scannedValue.trim().toLowerCase();
    final normalizedExpected = expectedHash.trim().toLowerCase();
    return normalizedScanned == normalizedExpected ||
        normalizedScanned.hashCode.toString() == normalizedExpected;
  }

  /// Calculates progressive volume ramp (20% to 100% over 60 seconds).
  double computeVolumeRamp(int secondsElapsed) {
    if (secondsElapsed <= 0) return 0.2;
    if (secondsElapsed >= 60) return 1.0;
    return 0.2 + (0.8 * (secondsElapsed / 60.0));
  }

  /// Checks if alarm has reached maximum safety cutoff (15 minutes).
  bool hasExceededMaxRing(DateTime firedAt, [DateTime? now]) {
    final current = now ?? DateTime.now();
    return current.difference(firedAt).inMinutes >= 15;
  }
}

