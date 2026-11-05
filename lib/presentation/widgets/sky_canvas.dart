import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/enums/core_enums.dart';
import '../../domain/services/weather_scene_engine.dart';

class WeatherSkyBackground extends StatefulWidget {
  final SkyPhase phase;
  final WeatherType condition;
  final Widget? child;
  final double height;
  final bool isAnimated;

  const WeatherSkyBackground({
    super.key,
    required this.phase,
    required this.condition,
    this.child,
    this.height = 240,
    this.isAnimated = true,
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
      duration: const Duration(seconds: 12),
    );
    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WeatherSkyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
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

    return RepaintBoundary(
      child: AnimatedBuilder(
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
      ),
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
    // 1. True OLED Black Background with subtle horizon blend
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: theme.gradientColors,
    );
    final bgPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Stars for Night / Dusk (White Dots)
    if (theme.starOpacity > 0.05) {
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: theme.starOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final rand = Random(1337);
      for (int i = 0; i < 30; i++) {
        final x = rand.nextDouble() * size.width;
        final y = rand.nextDouble() * (size.height * 0.70);
        final radius = (rand.nextDouble() * 1.2) + 0.6;
        final twinkle = (sin((animationValue * 2 * pi) + i) + 1.0) / 2.0;
        starPaint.color = Colors.white.withValues(
          alpha: (theme.starOpacity * (0.35 + (0.65 * twinkle))).clamp(0.0, 1.0),
        );
        canvas.drawCircle(Offset(x, y), radius, starPaint);
      }
    }

    // 3. Celestial Body: Lime Sun with thin radiating rays OR White Moon
    final celestialX = theme.celestialX * size.width;
    final celestialY = theme.celestialY * size.height;
    final center = Offset(celestialX, celestialY);

    if (theme.isMoon) {
      // White Line-Art Moon with subtle crescent cutout
      final moonPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, 16, moonPaint);

      // Inner crescent shadow line
      final shadowPath = Path()
        ..addArc(Rect.fromCircle(center: center.translate(5, -2), radius: 13), -pi / 2, pi);
      canvas.drawPath(shadowPath, moonPaint);
    } else {
      // Lime Sun (#B6FF00) solid core with soft glow
      final glowPaint = Paint()
        ..color = AppTokens.accentLime.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(center, 28, glowPaint);

      final sunPaint = Paint()
        ..color = AppTokens.accentLime
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 14, sunPaint);

      // Thin radiating rays in line art
      final rayPaint = Paint()
        ..color = AppTokens.accentLime.withValues(alpha: 0.75)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = (i * (pi / 4)) + (animationValue * pi * 0.25);
        final p1 = Offset(center.dx + cos(angle) * 19, center.dy + sin(angle) * 19);
        final p2 = Offset(center.dx + cos(angle) * 27, center.dy + sin(angle) * 27);
        canvas.drawLine(p1, p2, rayPaint);
      }
    }

    // 4. White Line-Art Cloud Outlines
    if (theme.cloudDensity > 0.1) {
      final cloudPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      for (int c = 0; c < 3; c++) {
        final shift = (animationValue * size.width * 0.25 + (c * 140)) % (size.width + 120) - 60;
        final cy = size.height * (0.35 + (c * 0.16));

        final path = Path()
          ..moveTo(shift, cy)
          ..cubicTo(shift + 10, cy - 14, shift + 35, cy - 14, shift + 45, cy)
          ..cubicTo(shift + 55, cy - 8, shift + 70, cy + 5, shift + 65, cy + 14)
          ..lineTo(shift - 5, cy + 14)
          ..close();

        canvas.drawPath(path, cloudPaint);
      }
    }

    // 5. Rain Streaks (slanted thin lime or white strokes)
    if (theme.rainParticleCount > 0) {
      final rainPaint = Paint()
        ..color = AppTokens.accentLime.withValues(alpha: 0.7)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      final rand = Random(42);
      for (int r = 0; r < theme.rainParticleCount; r++) {
        final rx = (rand.nextDouble() * size.width + (animationValue * -15)) % size.width;
        final ry = (rand.nextDouble() * size.height + (animationValue * size.height * 2.5)) % size.height;
        canvas.drawLine(
          Offset(rx, ry),
          Offset(rx - 3, ry + 11),
          rainPaint,
        );
      }
    }

    // 6. Thunder Lightning Bolt
    if (theme.hasThunder && (animationValue * 10).floor() % 4 == 0) {
      final boltPaint = Paint()
        ..color = AppTokens.accentLime
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final boltPath = Path()
        ..moveTo(size.width * 0.65, size.height * 0.15)
        ..lineTo(size.width * 0.61, size.height * 0.42)
        ..lineTo(size.width * 0.66, size.height * 0.46)
        ..lineTo(size.width * 0.58, size.height * 0.80);

      canvas.drawPath(boltPath, boltPaint);
    }

    // 7. Fog: Stacked Fading Horizontal Lines
    if (theme.isFoggy) {
      final fogPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1.0;

      for (int i = 0; i < 5; i++) {
        final fy = size.height * (0.50 + (i * 0.08));
        canvas.drawLine(
          Offset(size.width * 0.10, fy),
          Offset(size.width * 0.90, fy),
          fogPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkyCanvasPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.theme != theme;
  }
}
