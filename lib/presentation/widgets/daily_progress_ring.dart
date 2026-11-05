import 'dart:math';
import 'package:flutter/material.dart';

class DailyProgressRing extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final int wakeHour;
  final int wakeMinute;
  final int sleepHour;
  final int sleepMinute;
  final int currentStreakDays;

  const DailyProgressRing({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    this.wakeHour = 6,
    this.wakeMinute = 30,
    this.sleepHour = 23,
    this.sleepMinute = 0,
    this.currentStreakDays = 5,
  });

  double get taskProgress => totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;

  double get dayElapsedProgress {
    final now = DateTime.now();
    final wakeM = wakeHour * 60 + wakeMinute;
    final sleepM = sleepHour * 60 + sleepMinute;
    final nowM = now.hour * 60 + now.minute;

    if (nowM <= wakeM) return 0.0;
    if (nowM >= sleepM) return 1.0;
    return ((nowM - wakeM) / (sleepM - wakeM)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dual Progress Rings
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _DualRingPainter(
                taskProgress: taskProgress,
                dayProgress: dayElapsedProgress,
                taskColor: const Color(0xFF10B981), // Emerald
                dayColor: const Color(0xFF6366F1), // Indigo
                trackColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completedTasks/$totalTasks',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Progress Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Trajectory',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 2),
                          Text(
                            '$currentStreakDays Day Streak',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _StatBar(
                  label: 'Tasks Completed',
                  percent: (taskProgress * 100).toInt(),
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 6),
                _StatBar(
                  label: 'Waking Hours Elapsed',
                  percent: (dayElapsedProgress * 100).toInt(),
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const _StatBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              '$percent%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 5,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _DualRingPainter extends CustomPainter {
  final double taskProgress;
  final double dayProgress;
  final Color taskColor;
  final Color dayColor;
  final Color trackColor;

  _DualRingPainter({
    required this.taskProgress,
    required this.dayProgress,
    required this.taskColor,
    required this.dayColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -pi / 2;

    // Outer Ring: Task Progress
    final outerRadius = (size.width / 2) - 4;
    final outerTrackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, outerRadius, outerTrackPaint);

    final outerProgressPaint = Paint()
      ..color = taskColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      2 * pi * taskProgress,
      false,
      outerProgressPaint,
    );

    // Inner Ring: Day Elapsed
    final innerRadius = outerRadius - 9;
    final innerTrackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, innerRadius, innerTrackPaint);

    final innerProgressPaint = Paint()
      ..color = dayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      2 * pi * dayProgress,
      false,
      innerProgressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DualRingPainter oldDelegate) {
    return oldDelegate.taskProgress != taskProgress ||
        oldDelegate.dayProgress != dayProgress;
  }
}
