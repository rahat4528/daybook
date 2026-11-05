import 'dart:math' as math;
import '../../core/enums/core_enums.dart';

class SkyCalculator {
  /// Computes the astronomical sky phase based on local time and solar bounds
  static SkyPhase calculatePhase(
    DateTime time, {
    int sunriseMinutes = 6 * 60, // 6:00 AM
    int sunsetMinutes = 18 * 60, // 6:00 PM
  }) {
    final currentMinutes = time.hour * 60 + time.minute;

    // Dawn: 45m before sunrise to 30m after sunrise
    final dawnStart = sunriseMinutes - 45;
    final dawnEnd = sunriseMinutes + 30;

    // Golden Hour: 60m before sunset to sunset
    final goldenStart = sunsetMinutes - 60;

    // Dusk: sunset to 45m after sunset
    final duskEnd = sunsetMinutes + 45;

    if (currentMinutes >= dawnStart && currentMinutes < dawnEnd) {
      return SkyPhase.dawn;
    } else if (currentMinutes >= dawnEnd && currentMinutes < goldenStart) {
      return SkyPhase.morning; // daytime active phase
    } else if (currentMinutes >= goldenStart && currentMinutes < sunsetMinutes) {
      return SkyPhase.goldenHour;
    } else if (currentMinutes >= sunsetMinutes && currentMinutes < duskEnd) {
      return SkyPhase.dusk;
    } else {
      return SkyPhase.night;
    }
  }

  /// Calculates percentage (0.0 to 100.0) of waking day elapsed
  static double calculateWakingDayElapsed(
    DateTime time, {
    int wakeHour = 7,
    int wakeMinute = 0,
    int sleepHour = 23,
    int sleepMinute = 0,
  }) {
    final currentMinutes = time.hour * 60 + time.minute;
    final wakeMinutes = wakeHour * 60 + wakeMinute;
    final sleepMinutes = sleepHour * 60 + sleepMinute;

    if (currentMinutes <= wakeMinutes) return 0.0;
    if (currentMinutes >= sleepMinutes) return 100.0;

    final wakingSpan = sleepMinutes - wakeMinutes;
    if (wakingSpan <= 0) return 0.0;

    final elapsed = currentMinutes - wakeMinutes;
    return ((elapsed / wakingSpan) * 100.0).clamp(0.0, 100.0);
  }

  /// Calculates normalized celestial arc position (X: 0.0 to 1.0, Y: 0.0 to 1.0)
  static math.Point<double> getCelestialPosition(
    DateTime time, {
    int sunriseMinutes = 6 * 60,
    int sunsetMinutes = 18 * 60,
  }) {
    final currentMinutes = time.hour * 60 + time.minute;
    final isDay = currentMinutes >= sunriseMinutes && currentMinutes < sunsetMinutes;

    if (isDay) {
      final dayDuration = sunsetMinutes - sunriseMinutes;
      final progress = (currentMinutes - sunriseMinutes) / dayDuration; // 0.0 to 1.0
      // Arc formula: y = 4 * progress * (1 - progress)
      final x = progress.clamp(0.05, 0.95);
      final y = 4.0 * progress * (1.0 - progress);
      return math.Point(x, y.clamp(0.1, 1.0));
    } else {
      // Night celestial tracking for Moon
      final nightDuration = (1440 - sunsetMinutes) + sunriseMinutes;
      int nightElapsed;
      if (currentMinutes >= sunsetMinutes) {
        nightElapsed = currentMinutes - sunsetMinutes;
      } else {
        nightElapsed = (1440 - sunsetMinutes) + currentMinutes;
      }
      final progress = nightElapsed / nightDuration;
      final x = progress.clamp(0.05, 0.95);
      final y = 4.0 * progress * (1.0 - progress);
      return math.Point(x, y.clamp(0.1, 1.0));
    }
  }
}
