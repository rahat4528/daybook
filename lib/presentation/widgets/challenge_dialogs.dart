import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/enums/core_enums.dart';
import '../../domain/services/alarm_challenge_engine.dart';

class ChallengeSimulator {
  /// Opens the appropriate interactive challenge modal for the given alarm challenge.
  static Future<bool> launchChallenge({
    required BuildContext context,
    required AlarmChallengeType type,
    required ChallengeDifficulty difficulty,
    String? qrHash,
  }) async {
    switch (type) {
      case AlarmChallengeType.math:
        return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => _MathChallengeDialog(difficulty: difficulty),
            ) ??
            false;

      case AlarmChallengeType.memorySequence:
        return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => _MemorySequenceDialog(difficulty: difficulty),
            ) ??
            false;

      case AlarmChallengeType.movement:
        return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => _MovementChallengeDialog(difficulty: difficulty),
            ) ??
            false;

      case AlarmChallengeType.qrScan:
      case AlarmChallengeType.aiScan:
        return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => _QrScanChallengeDialog(expectedHash: qrHash ?? 'demo_target'),
            ) ??
            false;
    }
  }
}

class _MathChallengeDialog extends StatefulWidget {
  final ChallengeDifficulty difficulty;

  const _MathChallengeDialog({required this.difficulty});

  @override
  State<_MathChallengeDialog> createState() => _MathChallengeDialogState();
}

class _MathChallengeDialogState extends State<_MathChallengeDialog> {
  final _engine = AlarmChallengeEngine();
  final _controller = TextEditingController();
  late int _remainingRounds;
  late MathEquation _currentEquation;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _remainingRounds = widget.difficulty.mathRounds;
    _nextProblem();
  }

  void _nextProblem() {
    setState(() {
      _currentEquation = _engine.generateMathEquation(widget.difficulty);
      _controller.clear();
      _errorMessage = '';
    });
  }

  void _checkAnswer() {
    final input = int.tryParse(_controller.text.trim());
    if (input == _currentEquation.answer) {
      if (_remainingRounds <= 1) {
        Navigator.of(context).pop(true); // Solved!
      } else {
        setState(() {
          _remainingRounds--;
          _nextProblem();
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Incorrect! Try again.';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.calculate, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text('Math Challenge ($_remainingRounds left)'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentEquation.question,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Your answer',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _checkAnswer(),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Answer'),
        ),
      ],
    );
  }
}

class _MemorySequenceDialog extends StatefulWidget {
  final ChallengeDifficulty difficulty;

  const _MemorySequenceDialog({required this.difficulty});

  @override
  State<_MemorySequenceDialog> createState() => _MemorySequenceDialogState();
}

class _MemorySequenceDialogState extends State<_MemorySequenceDialog> {
  final _engine = AlarmChallengeEngine();
  late List<int> _targetSequence;
  final List<int> _userInput = [];
  int _activeFlashTile = -1;
  bool _isPlayingPattern = true;

  @override
  void initState() {
    super.initState();
    _targetSequence = _engine.generateMemorySequence(widget.difficulty);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playSequence());
  }

  Future<void> _playSequence() async {
    setState(() {
      _isPlayingPattern = true;
      _userInput.clear();
    });

    await Future.delayed(const Duration(milliseconds: 500));
    for (final tile in _targetSequence) {
      if (!mounted) return;
      setState(() => _activeFlashTile = tile);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _activeFlashTile = -1);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (mounted) {
      setState(() => _isPlayingPattern = false);
    }
  }

  void _onTileTapped(int index) {
    if (_isPlayingPattern) return;

    setState(() {
      _userInput.add(index);
    });

    // Check progress
    final currentPos = _userInput.length - 1;
    if (_userInput[currentPos] != _targetSequence[currentPos]) {
      // Mistake! Replay
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong pattern! Replaying sequence...'),
          duration: Duration(seconds: 1),
        ),
      );
      _playSequence();
      return;
    }

    if (_userInput.length == _targetSequence.length) {
      Navigator.of(context).pop(true); // Completed successfully!
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Repeat the Sequence'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isPlayingPattern ? 'Watch closely...' : 'Your turn! Tap the sequence.',
            style: TextStyle(
              color: _isPlayingPattern ? Colors.amber.shade700 : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            height: 220,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (ctx, idx) {
                final isFlashing = _activeFlashTile == idx;
                return GestureDetector(
                  onTap: () => _onTileTapped(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isFlashing
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isFlashing
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withOpacity(0.6),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        if (!_isPlayingPattern)
          TextButton(
            onPressed: _playSequence,
            child: const Text('Replay Pattern'),
          ),
      ],
    );
  }
}

class _MovementChallengeDialog extends StatefulWidget {
  final ChallengeDifficulty difficulty;

  const _MovementChallengeDialog({required this.difficulty});

  @override
  State<_MovementChallengeDialog> createState() => _MovementChallengeDialogState();
}

class _MovementChallengeDialogState extends State<_MovementChallengeDialog> {
  late int _targetSteps;
  int _currentSteps = 0;

  @override
  void initState() {
    super.initState();
    _targetSteps = widget.difficulty.requiredSteps;
  }

  void _simulateStep() {
    setState(() {
      _currentSteps++;
      if (_currentSteps >= _targetSteps) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentSteps / _targetSteps).clamp(0.0, 1.0);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.directions_walk, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Walk to Dismiss'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_currentSteps / $_targetSteps Steps',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, minHeight: 8),
          const SizedBox(height: 16),
          const Text(
            'Keep walking with your phone to wake up your body!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: _simulateStep,
          icon: const Icon(Icons.add),
          label: const Text('Simulate Step (+1)'),
        ),
      ],
    );
  }
}

class _QrScanChallengeDialog extends StatefulWidget {
  final String expectedHash;

  const _QrScanChallengeDialog({required this.expectedHash});

  @override
  State<_QrScanChallengeDialog> createState() => _QrScanChallengeDialogState();
}

class _QrScanChallengeDialogState extends State<_QrScanChallengeDialog> {
  final _engine = AlarmChallengeEngine();

  void _simulateScan() {
    final success = _engine.verifyQrCode(widget.expectedHash, widget.expectedHash);
    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner, color: Color(0xFF8B5CF6)),
          SizedBox(width: 8),
          Text('Scan Target Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.black12,
            ),
            child: const Center(
              child: Icon(Icons.qr_code, size: 80, color: Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan the QR code in your bathroom or kitchen to shut off the alarm.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _simulateScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Verify & Stop Alarm'),
        ),
      ],
    );
  }
}
