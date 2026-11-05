import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/enums/core_enums.dart';

class SkyVisualTheme {
  final List<Color> gradientColors;
  final Color celestialColor; // Sun (#B6FF00) or Moon (#FFFFFF)
  final double celestialX; // 0.0 (left) to 1.0 (right)
  final double celestialY; // 0.0 (top) to 1.0 (horizon)
  final bool isMoon;
  final double starOpacity;
  final double cloudDensity;
  final int rainParticleCount;
  final bool hasThunder;
  final bool isFoggy;
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
    this.hasThunder = false,
    this.isFoggy = false,
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

  /// Computes complete visual theme strictly following DayBook OLED Monochrome + Lime rules
  static SkyVisualTheme computeTheme({
    required SkyPhase phase,
    required WeatherType condition,
    required int hour,
    required int minute,
  }) {
    final timePercent = (hour * 60 + minute) / 1440.0;

    // Strict OLED black (#000000) base with soft ambient horizon gradient
    List<Color> gradient = [AppTokens.bg, AppTokens.surface1];
    Color celestial = AppTokens.accentLime;
    bool isMoon = false;
    double starOpacity = 0.0;
    double cloudDensity = 0.2;
    int rainCount = 0;
    bool hasThunder = false;
    bool isFoggy = false;
    double celestialY = 0.3;

    switch (phase) {
      case SkyPhase.dawn:
        gradient = [
          AppTokens.bg,
          AppTokens.surface1,
          AppTokens.accentLime.withValues(alpha: 0.08),
        ];
        celestial = AppTokens.accentLime;
        celestialY = 0.60;
        starOpacity = 0.25;
        break;

      case SkyPhase.morning:
        gradient = [AppTokens.bg, AppTokens.surface1];
        celestial = AppTokens.accentLime;
        celestialY = 0.25;
        break;

      case SkyPhase.afternoon:
        gradient = [AppTokens.bg, AppTokens.surface1];
        celestial = AppTokens.accentLime;
        celestialY = 0.20;
        break;

      case SkyPhase.goldenHour:
        gradient = [
          AppTokens.bg,
          AppTokens.surface1,
          AppTokens.accentLime.withValues(alpha: 0.12),
        ];
        celestial = AppTokens.accentLime;
        celestialY = 0.55;
        break;

      case SkyPhase.dusk:
        gradient = [AppTokens.bg, AppTokens.surface1];
        celestial = Colors.white70;
        celestialY = 0.70;
        starOpacity = 0.45;
        break;

      case SkyPhase.night:
        gradient = [AppTokens.bg, AppTokens.surface1];
        celestial = Colors.white;
        isMoon = true;
        starOpacity = 0.90;
        celestialY = 0.25;
        break;
    }

    // Weather condition modifiers
    switch (condition) {
      case WeatherType.partlyCloudy:
        cloudDensity = 0.45;
        break;
      case WeatherType.overcast:
        cloudDensity = 0.85;
        break;
      case WeatherType.rain:
        cloudDensity = 0.85;
        rainCount = 20; // Hard-capped at 20-25 particles for battery conservation
        break;
      case WeatherType.thunderstorm:
        cloudDensity = 0.90;
        rainCount = 25;
        hasThunder = true;
        break;
      case WeatherType.foggy:
        cloudDensity = 0.60;
        isFoggy = true;
        break;
      case WeatherType.clear:
        cloudDensity = 0.10;
        break;
    }

    // Horizontal celestial trajectory across width
    final celestialX = (0.15 + (timePercent * 0.70)).clamp(0.15, 0.85);

    return SkyVisualTheme(
      gradientColors: gradient,
      celestialColor: celestial,
      celestialX: celestialX,
      celestialY: celestialY,
      isMoon: isMoon,
      starOpacity: starOpacity,
      cloudDensity: cloudDensity,
      rainParticleCount: rainCount,
      hasThunder: hasThunder,
      isFoggy: isFoggy,
      ambientTextColor: Colors.white,
    );
  }
}
