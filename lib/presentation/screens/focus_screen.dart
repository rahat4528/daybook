import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/models/focus_session.dart';
import '../../domain/services/focus_service.dart';
import '../../data/repositories/entries_repository.dart';

class FocusScreen extends StatefulWidget {
  final bool isBangla;
  final FocusService focusService;
  final EntriesRepository entriesRepo;

  const FocusScreen({
    super.key,
    this.isBangla = false,
    required this.focusService,
    required this.entriesRepo,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  @override
  void initState() {
    super.initState();
    widget.focusService.addListener(_onServiceUpdated);
  }

  void _onServiceUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusService.removeListener(_onServiceUpdated);
    super.dispose();
  }

  void _showSoundscapePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isBangla ? 'শব্দধারা নির্বাচন করুন' : 'SELECT SOUNDSCAPE',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.accentLime,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            ...FocusSoundscape.values.map((sound) {
              final isSelected = widget.focusService.soundscape == sound;
              return ListTile(
                leading: Text(sound.glyph, style: const TextStyle(fontSize: 20)),
                title: Text(
                  sound.label(isBangla: widget.isBangla),
                  style: TextStyle(
                    color: isSelected ? AppColors.accentLime : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.accentLime) : null,
                onTap: () {
                  widget.focusService.setSoundscape(sound);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focus = widget.focusService;
    final isRunning = focus.state == FocusState.running;
    final isPaused = focus.state == FocusState.paused;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          widget.isBangla ? 'গভীর ফোকাস জোন' : 'FOCUS ZONE',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          IconButton(
            icon: Text(focus.soundscape.glyph, style: const TextStyle(fontSize: 18)),
            tooltip: 'Soundscape',
            onPressed: _showSoundscapePicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Target Task Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: AppColors.accentLime, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isBangla ? 'বর্তমান ফোকাস কাজ' : 'TARGET TASK',
                            style: const TextStyle(
                              color: AppColors.accentLime,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            focus.currentTaskTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Circular Pomodoro Progress Dial
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: focus.progressFraction,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surface2,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentLime),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        focus.timeFormatted,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRunning
                            ? (widget.isBangla ? 'ফোকাস চলমান' : 'DEEP FOCUSING')
                            : (isPaused
                                ? (widget.isBangla ? 'বিরতি নেওয়া হয়েছে' : 'PAUSED')
                                : (widget.isBangla ? 'প্রস্তুত' : 'READY')),
                        style: TextStyle(
                          color: isRunning ? AppColors.accentLime : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (focus.interruptions > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.isBangla
                              ? '${focus.interruptions} বার বিঘ্ন'
                              : '${focus.interruptions} interruptions',
                          style: const TextStyle(color: AppColors.errorRed, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Flip-to-Focus Indicator & Test Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focus.isFaceDown ? AppColors.accentLime : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      focus.isFaceDown ? Icons.screen_lock_portrait : Icons.stay_current_portrait,
                      color: focus.isFaceDown ? AppColors.accentLime : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isBangla
                            ? 'উল্টে রেখে ফোকাস (Flip-to-Focus): ${focus.isFaceDown ? "সক্রিয়" : "অপেক্ষা"}'
                            : 'Flip-to-Focus: ${focus.isFaceDown ? "Active (Face Down)" : "Idle"}',
                        style: TextStyle(
                          color: focus.isFaceDown ? AppColors.accentLime : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Toggle simulated accelerometer coordinate for test and simulator
                        if (focus.isFaceDown) {
                          focus.evaluateAccelerometer(x: 0, y: 0, z: 9.8); // Picked up
                        } else {
                          focus.evaluateAccelerometer(x: 0, y: 0, z: -9.8); // Face down
                        }
                      },
                      child: Text(
                        focus.isFaceDown ? 'Flip Up' : 'Flip Down',
                        style: const TextStyle(color: AppColors.accentLime, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              // Primary Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRunning && !isPaused)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => focus.start(),
                      child: Text(
                        widget.isBangla ? 'ফোকাস শুরু করুন' : 'START FOCUS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),

                  if (isRunning) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface2,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () => focus.pause(),
                      child: Text(
                        widget.isBangla ? 'বিরতি' : 'PAUSE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final session = focus.completeSession(entriesRepo: widget.entriesRepo);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface2,
                            content: Text(
                              'Focus session logged (${session.actualMinutes}m)! Quality: ${(session.qualityScore * 100).toInt()}%',
                              style: const TextStyle(color: AppColors.accentLime),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        widget.isBangla ? 'সম্পন্ন' : 'COMPLETE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],

                  if (isPaused) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => focus.resume(),
                      child: Text(
                        widget.isBangla ? 'চালিয়ে যান' : 'RESUME',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () => focus.reset(),
                      child: Text(widget.isBangla ? 'রিসেট' : 'RESET'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
