import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/enums/core_enums.dart';
import '../../domain/services/weather_scene_engine.dart';

class WeatherSkyBackground extends StatefulWidget {
  final SkyPhase phase;
  final WeatherType condition;
  final Widget? child;
  final double height;

  const WeatherSkyBackground({
    super.key,
    required this.phase,
    required this.condition,
    this.child,
    this.height = 240,
  });

  @override
  State<WeatherSkyBackground> createState() => _WeatherSkyBackgroundState();
}

class _WeatherSkyBackgroundState extends State<WeatherSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = WeatherSceneEngine.computeTheme(
      phase: widget.phase,
      condition: widget.condition,
      hour: now.hour,
      minute: now.minute,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: SkyCanvasPainter(
            theme: theme,
            animationValue: _controller.value,
          ),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class SkyCanvasPainter extends CustomPainter {
  final SkyVisualTheme theme;
  final double animationValue;

  SkyCanvasPainter({
    required this.theme,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky Gradient Background
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: theme.gradientColors,
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // 2. Stars for Night / Dusk
    if (theme.starOpacity > 0.05) {
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(theme.starOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      // Seeded deterministic star coordinates
      final rand = Random(1337);
      for (int i = 0; i < 35; i++) {
        final x = rand.nextDouble() * size.width;
        final y = rand.nextDouble() * (size.height * 0.7);
        final radius = (rand.nextDouble() * 1.5) + 0.5;
        final twinkle = (sin((animationValue * 2 * pi) + i) + 1.0) / 2.0;
        starPaint.color = Colors.white.withOpacity(
          (theme.starOpacity * (0.4 + (0.6 * twinkle))).clamp(0.0, 1.0),
        );
        canvas.drawCircle(Offset(x, y), radius, starPaint);
      }
    }

    // 3. Celestial Orb (Sun or Moon)
    final celestialX = theme.celestialX * size.width;
    final celestialY = theme.celestialY * size.height;
    final center = Offset(celestialX, celestialY);

    if (theme.isMoon) {
      // Lunar soft halo
      final glowPaint = Paint()
        ..color = const Color(0xFFE2E8F0).withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(center, 30, glowPaint);

      // Moon body
      final moonPaint = Paint()..color = theme.celestialColor;
      canvas.drawCircle(center, 18, moonPaint);

      // Subtle shadow crater
      final shadowPaint = Paint()..color = const Color(0xFF0F172A).withOpacity(0.35);
      canvas.drawCircle(center.translate(6, -3), 14, shadowPaint);
    } else {
      // Solar coronal glow
      final coronaPaint = Paint()
        ..color = theme.celestialColor.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      canvas.drawCircle(center, 38, coronaPaint);

      // Sun Core
      final sunPaint = Paint()..color = theme.celestialColor;
      canvas.drawCircle(center, 20, sunPaint);
    }

    // 4. Drifting Clouds
    if (theme.cloudDensity > 0.1) {
      final cloudPaint = Paint()
        ..color = (theme.isMoon ? Colors.white10 : Colors.white24)
        ..style = PaintingStyle.fill;

      for (int c = 0; c < 3; c++) {
        final cloudShift = (animationValue * size.width * 0.35 + (c * 130)) % (size.width + 100) - 50;
        final cloudY = size.height * (0.35 + (c * 0.18));

        canvas.drawCircle(Offset(cloudShift, cloudY), 26, cloudPaint);
        canvas.drawCircle(Offset(cloudShift + 22, cloudY - 8), 34, cloudPaint);
        canvas.drawCircle(Offset(cloudShift + 48, cloudY + 2), 24, cloudPaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cloudShift - 10, cloudY, 68, 20),
            const Radius.circular(10),
          ),
          cloudPaint,
        );
      }
    }

    // 5. Rain Streaks
    if (theme.rainParticleCount > 0) {
      final rainPaint = Paint()
        ..color = const Color(0xFF93C5FD).withOpacity(0.4)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      final rand = Random(42);
      for (int r = 0; r < theme.rainParticleCount; r++) {
        final rx = (rand.nextDouble() * size.width + (animationValue * -15)) % size.width;
        final ry = (rand.nextDouble() * size.height + (animationValue * size.height * 2.5)) % size.height;
        canvas.drawLine(
          Offset(rx, ry),
          Offset(rx - 3, ry + 12),
          rainPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkyCanvasPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.theme != theme;
  }
}
