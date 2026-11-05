import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/challenges/wake_challenge.dart';
import '../../domain/models/alarm_item.dart';
import '../../domain/services/wake_quest_engine.dart';

class WakeQuestScreen extends StatefulWidget {
  final AlarmItem alarm;
  final bool isBangla;
  final VoidCallback onDismissed;
  final Function(String intention)? onIntentionCaptured;
  final WakeQuestEngine? customEngine;

  const WakeQuestScreen({
    super.key,
    required this.alarm,
    this.isBangla = false,
    required this.onDismissed,
    this.onIntentionCaptured,
    this.customEngine,
  });

  @override
  State<WakeQuestScreen> createState() => _WakeQuestScreenState();
}

class _WakeQuestScreenState extends State<WakeQuestScreen> {
  late final WakeQuestEngine _engine;
  final TextEditingController _inputController = TextEditingController();
  Timer? _ticker;
  double _escapeHoldProgress = 0.0;
  Timer? _holdTimer;
  String? _challengeErrorMessage;
  bool _isReplayingSimon = false;

  @override
  void initState() {
    super.initState();
    _engine = widget.customEngine ??
        WakeQuestEngine(
          alarm: widget.alarm,
          isBangla: widget.isBangla,
        );

    // 1-second UI refresh timer for clock and sunrise glow
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _holdTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _submitInput(dynamic input) {
    setState(() => _challengeErrorMessage = null);
    final result = _engine.submitChallengeInput(input);

    if (result.isSuccess) {
      _inputController.clear();
      if (_engine.isChainComplete) {
        // Check if intention was captured
        for (final ch in _engine.challengeChain) {
          if (ch is IntentionLineChallenge && ch.capturedIntention != null) {
            widget.onIntentionCaptured?.call(ch.capturedIntention!);
          }
        }
      }
    } else {
      setState(() {
        _challengeErrorMessage = widget.isBangla ? result.errorMessageBangla : result.errorMessageEnglish;
      });

      if (result.requiresReplay) {
        _triggerSimonReplay();
      }
    }
  }

  void _triggerSimonReplay() {
    setState(() => _isReplayingSimon = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isReplayingSimon = false);
    });
  }

  void _startEmergencyHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() {
        _escapeHoldProgress += 0.02; // 5 seconds = 50 ticks of 100ms
        if (_escapeHoldProgress >= 1.0) {
          t.cancel();
          _engine.emergencySafeDismiss();
        }
      });
    });
  }

  void _cancelEmergencyHold() {
    _holdTimer?.cancel();
    setState(() => _escapeHoldProgress = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final glow = _engine.getSunriseGlowFactor();
    final isEscaped = _engine.isEscapeHatchUnlocked();

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          // Dynamic Sunrise Ambient Glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    AppTokens.accentLime.withValues(alpha: 0.18 * glow),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _engine.isChainComplete ? _buildSuccessView() : _buildActiveQuestView(timeStr, isEscaped),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuestView(String timeStr, bool isEscaped) {
    final challenge = _engine.currentChallenge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Alarm Header & Live Clock
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alarm, color: AppTokens.accentLime, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      widget.alarm.label,
                      style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  widget.isBangla
                      ? 'ধাপ ${_engine.currentChallengeIndex + 1}/${_engine.totalChallenges}: ${challenge.titleBangla}'
                      : 'Stage ${_engine.currentChallengeIndex + 1}/${_engine.totalChallenges}: ${challenge.titleEnglish}',
                  style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.surface2,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: AppTokens.border),
              ),
              child: Text(
                timeStr,
                style: const TextStyle(
                  color: AppTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Challenge Instruction Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTokens.surface1,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isBangla ? challenge.titleBangla : challenge.titleEnglish,
                style: const TextStyle(color: AppTokens.accentLime, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isBangla ? challenge.instructionsBangla : challenge.instructionsEnglish,
                style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13),
              ),
              if (_challengeErrorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTokens.errorRed, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _challengeErrorMessage!,
                        style: const TextStyle(color: AppTokens.errorRed, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Challenge Renderer Body
        Expanded(
          child: SingleChildScrollView(
            child: _buildChallengeSpecificContent(challenge),
          ),
        ),

        // Safety Escape Hatch
        if (isEscaped) _buildEscapeHatchWidget(),
      ],
    );
  }

  Widget _buildChallengeSpecificContent(WakeChallenge challenge) {
    if (challenge is MathChallenge) {
      return _buildMathView(challenge);
    } else if (challenge is MemorySequenceChallenge) {
      return _buildSimonView(challenge);
    } else if (challenge is MovementChallenge) {
      return _buildMovementView(challenge);
    } else if (challenge is TypingChallenge) {
      return _buildTypingView(challenge);
    } else if (challenge is VoicePhraseChallenge) {
      return _buildVoiceView(challenge);
    } else if (challenge is IntentionLineChallenge) {
      return _buildIntentionView(challenge);
    } else if (challenge is QrScanChallenge) {
      return _buildQrView(challenge);
    } else if (challenge is AiVisionChallenge) {
      return _buildAiVisionView(challenge);
    }

    return const SizedBox.shrink();
  }

  Widget _buildMathView(MathChallenge ch) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppTokens.border),
          ),
          child: Text(
            '${ch.currentProblem.question} = ?',
            style: const TextStyle(color: AppTokens.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _inputController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 20),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: widget.isBangla ? 'উত্তর লিখুন' : 'Enter Answer',
            hintStyle: const TextStyle(color: AppTokens.textSecondary),
            filled: true,
            fillColor: AppTokens.surface1,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTokens.border)),
          ),
          onSubmitted: (val) => _submitInput(val),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.accentLime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _submitInput(_inputController.text),
            child: Text(
              widget.isBangla ? 'উত্তর যাচাই করুন' : 'Submit Calculation',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimonView(MemorySequenceChallenge ch) {
    return Column(
      children: [
        if (_isReplayingSimon)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTokens.errorRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.isBangla ? 'ভুল হয়েছে! সিকোয়েন্সটি আবার দেখুন...' : 'Mistake! Replaying sequence...',
              style: const TextStyle(color: AppTokens.errorRed, fontWeight: FontWeight.bold),
            ),
          ),
        AspectRatio(
          aspectRatio: 1.0,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (ctx, index) {
              final isTapped = ch.userSequence.contains(index);
              return GestureDetector(
                onTap: () => _submitInput(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isTapped ? AppTokens.accentLime : AppTokens.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTapped ? AppTokens.accentLime : AppTokens.border,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isTapped ? Colors.black : AppTokens.textSecondary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovementView(MovementChallenge ch) {
    final progress = (ch.currentSteps / ch.targetSteps).clamp(0.0, 1.0);

    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: AppTokens.surface2,
                color: AppTokens.accentLime,
              ),
            ),
            Column(
              children: [
                const Icon(Icons.directions_walk, color: AppTokens.accentLime, size: 36),
                const SizedBox(height: 4),
                Text(
                  '${ch.currentSteps} / ${ch.targetSteps}',
                  style: const TextStyle(color: AppTokens.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.isBangla ? 'কদম' : 'Steps',
                  style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTokens.surface2,
            foregroundColor: AppTokens.accentLime,
            side: const BorderSide(color: AppTokens.accentLime),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.vibration),
          label: Text(widget.isBangla ? 'পদক্ষেপ অনুকরণ (সিমুলেট +১)' : 'Simulate 1 Step'),
          onPressed: () => _submitInput(1),
        ),
      ],
    );
  }

  Widget _buildTypingView(TypingChallenge ch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTokens.accentLime.withValues(alpha: 0.5)),
          ),
          child: Text(
            ch.targetPhrase,
            style: const TextStyle(color: AppTokens.accentLime, fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _inputController,
          maxLines: 2,
          style: const TextStyle(color: AppTokens.textPrimary),
          decoration: InputDecoration(
            hintText: widget.isBangla ? 'বাক্যটি হুবহু টাইপ করুন...' : 'Type sentence accurately...',
            hintStyle: const TextStyle(color: AppTokens.textSecondary),
            filled: true,
            fillColor: AppTokens.surface1,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.accentLime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _submitInput(_inputController.text),
            child: Text(widget.isBangla ? 'যাচাই করুন' : 'Verify Text', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceView(VoicePhraseChallenge ch) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTokens.border),
          ),
          child: Text(
            '"${ch.expectedPhrase}"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTokens.accentLime, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        IconButton(
          iconSize: 64,
          icon: const Icon(Icons.mic, color: AppTokens.accentLime),
          onPressed: () => _submitInput(ch.expectedPhrase), // Simulates speech recognition match
        ),
        Text(
          widget.isBangla ? 'কণ্ঠ যাচাই করতে চাপুন' : 'Tap to test voice match',
          style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIntentionView(IntentionLineChallenge ch) {
    return Column(
      children: [
        TextField(
          controller: _inputController,
          style: const TextStyle(color: AppTokens.textPrimary),
          decoration: InputDecoration(
            hintText: widget.isBangla ? 'যেমন: ৩টি গুরুত্বপূর্ণ টাস্ক সম্পন্ন করা' : 'e.g. Finish Core Engine & Push',
            hintStyle: const TextStyle(color: AppTokens.textSecondary),
            filled: true,
            fillColor: AppTokens.surface1,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.accentLime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              widget.isBangla ? 'দিনটি শুরু করুন' : 'Lock In & Rise',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _submitInput(_inputController.text),
          ),
        ),
      ],
    );
  }

  Widget _buildQrView(QrScanChallenge ch) {
    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTokens.accentLime.withValues(alpha: 0.5)),
          ),
          child: const Center(
            child: Icon(Icons.qr_code_scanner, color: AppTokens.accentLime, size: 64),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _inputController,
          style: const TextStyle(color: AppTokens.textPrimary),
          decoration: InputDecoration(
            hintText: widget.isBangla ? 'কিউআর কোড মান লিখুন (টেস্ট)' : 'Enter Scanned Value (Test)',
            hintStyle: const TextStyle(color: AppTokens.textSecondary),
            filled: true,
            fillColor: AppTokens.surface1,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.accentLime,
              foregroundColor: Colors.black,
            ),
            onPressed: () => _submitInput(_inputController.text),
            child: Text(widget.isBangla ? 'স্ক্যান সম্পন্ন' : 'Simulate Scan'),
          ),
        ),
      ],
    );
  }

  Widget _buildAiVisionView(AiVisionChallenge ch) {
    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTokens.accentLime),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, color: AppTokens.accentLime, size: 48),
                const SizedBox(height: 8),
                Text(
                  'TARGET: ${ch.targetLabel.toUpperCase()}',
                  style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTokens.accentLime,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            // Emulates frame detection with motion anti-spoofing
            _submitInput(
              AiVisionFrameResult(
                label: ch.targetLabel,
                confidence: 0.88,
                cameraGyroDelta: 0.08,
              ),
            );
          },
          child: Text(widget.isBangla ? 'ফ্রেম সনাক্তকরণ টেস্ট' : 'Detect Frame With Motion'),
        ),
      ],
    );
  }

  Widget _buildEscapeHatchWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.errorRed),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTokens.errorRed, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.isBangla ? 'জরুরি এস্কেপ হ্যাচ সক্রিয়' : 'Safety Escape Hatch Active',
                style: const TextStyle(color: AppTokens.errorRed, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTapDown: (_) => _startEmergencyHold(),
            onTapUp: (_) => _cancelEmergencyHold(),
            onTapCancel: () => _cancelEmergencyHold(),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTokens.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTokens.errorRed),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _escapeHoldProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTokens.errorRed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.isBangla ? 'জরুরি বন্ধ করতে ৫ সেকেন্ড চেপে রাখুন' : 'Hold 5s to Emergency Dismiss',
                      style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wb_sunny, color: AppTokens.accentLime, size: 64),
        const SizedBox(height: 16),
        Text(
          widget.isBangla ? 'শুভ সকাল!' : 'Good Morning!',
          style: const TextStyle(color: AppTokens.accentLime, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _engine.generateTtsGreeting(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTokens.textPrimary, fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.accentLime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: widget.onDismissed,
            child: Text(
              widget.isBangla ? 'আজকের পেজে যান' : 'Proceed to Day Page',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
