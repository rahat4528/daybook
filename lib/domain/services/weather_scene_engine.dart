import 'package:flutter/material.dart';
import '../../core/enums/core_enums.dart';

class SkyVisualTheme {
  final List<Color> gradientColors;
  final Color celestialColor; // Sun or Moon
  final double celestialX; // 0.0 (left) to 1.0 (right)
  final double celestialY; // 0.0 (top) to 1.0 (horizon)
  final bool isMoon;
  final double starOpacity;
  final double cloudDensity;
  final int rainParticleCount;
  final Color ambientTextColor;

  const SkyVisualTheme({
    required this.gradientColors,
    required this.celestialColor,
    required this.celestialX,
    required this.celestialY,
    required this.isMoon,
    this.starOpacity = 0.0,
    this.cloudDensity = 0.2,
    this.rainParticleCount = 0,
    this.ambientTextColor = Colors.white,
  });
}

class WeatherSceneEngine {
  /// Maps Open-Meteo WMO weather code to domain WeatherType.
  static WeatherType mapWmoCode(int wmoCode) {
    if (wmoCode == 0) return WeatherType.clear;
    if (wmoCode >= 1 && wmoCode <= 3) return WeatherType.partlyCloudy;
    if (wmoCode == 45 || wmoCode == 48) return WeatherType.foggy;
    if ((wmoCode >= 51 && wmoCode <= 67) || (wmoCode >= 80 && wmoCode <= 82)) {
      return WeatherType.rain;
    }
    if (wmoCode >= 95 && wmoCode <= 99) return WeatherType.thunderstorm;
    return WeatherType.overcast;
  }

  /// Computes complete visual theme for dynamic CustomPainter.
  static SkyVisualTheme computeTheme({
    required SkyPhase phase,
    required WeatherType condition,
    required int hour,
    required int minute,
  }) {
    final timePercent = (hour * 60 + minute) / 1440.0;

    List<Color> gradient;
    Color celestial;
    bool isMoon = false;
    double starOpacity = 0.0;
    double cloudDensity = 0.2;
    int rainCount = 0;
    double celestialY = 0.3;
    Color ambientText = Colors.white;

    switch (phase) {
      case SkyPhase.dawn:
        gradient = [
          const Color(0xFF1E1B4B), // Deep indigo
          const Color(0xFF4C1D95), // Violet
          const Color(0xFFF59E0B), // Sunrise Amber
          const Color(0xFFFED7AA), // Peach horizon
        ];
        celestial = const Color(0xFFFDE68A);
        celestialY = 0.65;
        starOpacity = 0.3;
        break;

      case SkyPhase.morning:
        gradient = [
          const Color(0xFF0284C7), // Morning sky blue
          const Color(0xFF38BDF8),
          const Color(0xFFBAE6FD),
        ];
        celestial = const Color(0xFFFEF08A);
        celestialY = 0.25;
        ambientText = const Color(0xFF0F172A);
        break;

      case SkyPhase.afternoon:
        gradient = [
          const Color(0xFF0369A1), // Vibrant azure
          const Color(0xFF0EA5E9),
          const Color(0xFF7DD3FC),
        ];
        celestial = const Color(0xFFFDE047);
        celestialY = 0.18;
        ambientText = const Color(0xFF0F172A);
        break;

      case SkyPhase.goldenHour:
        gradient = [
          const Color(0xFF312E81), // Dusk twilight
          const Color(0xFFC026D3), // Magenta glow
          const Color(0xFFF97316), // Blazing orange
          const Color(0xFFFDE047), // Gold horizon
        ];
        celestial = const Color(0xFFF97316);
        celestialY = 0.6;
        break;

      case SkyPhase.dusk:
        gradient = [
          const Color(0xFF0F172A),
          const Color(0xFF311042),
          const Color(0xFF581C87),
          const Color(0xFF9A3412),
        ];
        celestial = const Color(0xFFCBD5E1);
        celestialY = 0.75;
        starOpacity = 0.5;
        break;

      case SkyPhase.night:
        gradient = [
          const Color(0xFF020617), // Midnight void
          const Color(0xFF0B1120),
          const Color(0xFF172554),
        ];
        celestial = const Color(0xFFF1F5F9); // Pearly moon
        isMoon = true;
        starOpacity = 0.95;
        celestialY = 0.22;
        break;
    }

    // Weather condition modifiers
    switch (condition) {
      case WeatherType.partlyCloudy:
        cloudDensity = 0.5;
        break;
      case WeatherType.overcast:
        cloudDensity = 0.85;
        gradient = gradient.map((c) => Color.lerp(c, const Color(0xFF475569), 0.4)!).toList();
        break;
      case WeatherType.rain:
        cloudDensity = 0.9;
        rainCount = 45;
        gradient = gradient.map((c) => Color.lerp(c, const Color(0xFF334155), 0.5)!).toList();
        break;
      case WeatherType.thunderstorm:
        cloudDensity = 0.95;
        rainCount = 75;
        gradient = [
          const Color(0xFF090D16),
          const Color(0xFF1E1B4B),
          const Color(0xFF1E293B),
        ];
        break;
      case WeatherType.foggy:
        cloudDensity = 0.7;
        gradient = gradient.map((c) => Color.lerp(c, const Color(0xFFCBD5E1), 0.55)!).toList();
        break;
      case WeatherType.clear:
        cloudDensity = 0.15;
        break;
    }

    // Position of sun / moon across horizontal axis (0.15 to 0.85)
    final celestialX = (0.15 + (timePercent * 0.7)).clamp(0.15, 0.85);

    return SkyVisualTheme(
      gradientColors: gradient,
      celestialColor: celestial,
      celestialX: celestialX,
      celestialY: celestialY,
      isMoon: isMoon,
      starOpacity: starOpacity,
      cloudDensity: cloudDensity,
      rainParticleCount: rainCount,
      ambientTextColor: ambientText,
    );
  }
}

