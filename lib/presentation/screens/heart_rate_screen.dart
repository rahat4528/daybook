// Bluetooth Heart Rate Monitor Screen (Page 05)
// Real-time BPM display, 60fps pulsating cardiac ring, 5 training zones, and workout session tracker.

import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/heart_rate_session.dart';
import '../../domain/services/heart_rate_service.dart';

class HeartRateScreen extends StatefulWidget {
  final HeartRateService hrService;
  final bool isBangla;

  const HeartRateScreen({
    super.key,
    required this.hrService,
    this.isBangla = false,
  });

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.hrService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.hrService.removeListener(_onServiceUpdate);
    _pulseController.dispose();
    super.dispose();
  }

  void _showDeviceScanModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth_searching, color: AppColors.accentLime),
                const SizedBox(width: 8),
                Text(
                  widget.isBangla ? 'কাছাকাছি ব্লুটুথ চেস্ট স্ট্র্যাপ' : 'NEARBY BLE HEART RATE SENSORS',
                  style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...['Polar H10 82A1', 'Garmin HRM-Pro Plus', 'Wahoo TICKR X'].map((device) {
              return ListTile(
                leading: const Icon(Icons.favorite, color: AppColors.accentLime),
                title: Text(device, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('GATT Service: 0x180D • RSSI: -64 dBm', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLime,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    widget.hrService.connectToDevice(device);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.hrService.connectionStatus;
    final isConnected = status == BleConnectionStatus.connected;
    final bpm = widget.hrService.currentBpm;
    final zone = widget.hrService.currentZone;
    final samples = widget.hrService.rollingSamples;
    final isWorkoutActive = widget.hrService.isWorkoutActive;
    final pastWorkouts = widget.hrService.pastWorkouts;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          widget.isBangla ? 'ব্লুটুথ হার্ট রেট মনিটর' : 'HEART RATE TELEMETRY',
          style: AppTypography.screenTitle,
        ),
        backgroundColor: AppColors.surface1,
        elevation: 0,
        actions: [
          if (isConnected)
            TextButton.icon(
              icon: const Icon(Icons.bluetooth_connected, color: AppColors.accentLime, size: 18),
              label: Text(
                widget.hrService.connectedDeviceName ?? 'Connected',
                style: const TextStyle(color: AppColors.accentLime, fontSize: 12),
              ),
              onPressed: widget.hrService.disconnectDevice,
            )
          else
            IconButton(
              icon: const Icon(Icons.bluetooth, color: AppColors.accentLime),
              tooltip: 'Scan BLE Straps',
              onPressed: _showDeviceScanModal,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Connection Status Banner
            if (!isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth_disabled, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isBangla ? 'চেস্ট স্ট্র্যাপ সংযুক্ত নেই' : 'No BLE Strap Connected',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.isBangla ? 'Polar H10 বা Garmin ডিভাইস স্ক্যান করুন।' : 'Pair a BLE chest strap (Polar/Garmin/Wahoo).',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _showDeviceScanModal,
                      child: const Text('Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Live BPM Cardiac HUD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.7), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentLime.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Animated Pulsating Heart Icon
                  ScaleTransition(
                    scale: isConnected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentLime.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.favorite, color: AppColors.accentLime, size: 36),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Giant BPM Number
                  Text(
                    isConnected ? '$bpm' : '--',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentLime,
                      fontFamily: 'monospace',
                      letterSpacing: -1.0,
                    ),
                  ),
                  const Text('BEATS PER MINUTE (BPM)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.0)),
                  const SizedBox(height: 16),

                  // Training Zone Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.accentLime),
                    ),
                    child: Text(
                      '${zone.label.toUpperCase()} • ${zone.title.toUpperCase()} (${zone.description})',
                      style: const TextStyle(
                        color: AppColors.accentLime,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live 60-second Rolling Waveform Chart
            Container(
              width: double.infinity,
              height: 140,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('60-SECOND ROLLING TELEMETRY', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 0.5)),
                      Text('${samples.length} Samples', style: const TextStyle(color: AppColors.accentLime, fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: CustomPaint(
                      painter: _HeartRateSparklinePainter(samples: samples),
                      child: Container(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Workout Session Controls
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isWorkoutActive ? 'WORKOUT IN PROGRESS' : 'WORKOUT SESSION TRACKER',
                        style: TextStyle(
                          color: isWorkoutActive ? AppColors.accentLime : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (isWorkoutActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Text('RECORDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isWorkoutActive)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentLime,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                        ),
                        onPressed: isConnected ? widget.hrService.startWorkout : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('START WORKOUT SESSION', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            onPressed: widget.hrService.isWorkoutPaused
                                ? widget.hrService.resumeWorkout
                                : widget.hrService.pauseWorkout,
                            icon: Icon(widget.hrService.isWorkoutPaused ? Icons.play_arrow : Icons.pause),
                            label: Text(widget.hrService.isWorkoutPaused ? 'Resume' : 'Pause'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final record = widget.hrService.finishWorkout();
                              if (record != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ Workout Saved! Avg: ${record.avgBpm} BPM | Max: ${record.maxBpm} BPM'),
                                    backgroundColor: AppColors.accentLime,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('End & Save', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Past Workouts History
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.isBangla ? 'অতীত ওয়ার্কআউট ইতিহাস' : 'WORKOUT HISTORY & TIME IN ZONES',
                style: AppTypography.sectionHeader,
              ),
            ),
            const SizedBox(height: 8),
            ...pastWorkouts.map((w) => _buildWorkoutCard(w)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutSessionRecord workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(workout.deviceName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('${workout.durationSeconds ~/ 60}m ${workout.durationSeconds % 60}s', style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Avg: ${workout.avgBpm} BPM', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace')),
              Text('Peak: ${workout.maxBpm} BPM', style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'monospace')),
              Text('Min: ${workout.minBpm} BPM', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 13, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeartRateSparklinePainter extends CustomPainter {
  final List<BpmSample> samples;

  _HeartRateSparklinePainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final paint = Paint()
      ..color = AppColors.accentLime
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    const minBpm = 50.0;
    const maxBpm = 200.0;

    final dx = size.width / (samples.length - 1);

    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final normY = (sample.bpm - minBpm) / (maxBpm - minBpm);
      final y = size.height - (normY.clamp(0.0, 1.0) * size.height);
      final x = i * dx;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartRateSparklinePainter oldDelegate) => true;
}
