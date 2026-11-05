import 'package:flutter/material.dart';

/// DayBook Core Design Tokens: True-Black, White, and Lime Bold.
class AppColors {
  // Pure Black Background (OLED)
  static const Color bg = Color(0xFF000000);

  // Surfaces & Borders
  static const Color surface1 = Color(0xFF0A0A0A);
  static const Color surface2 = Color(0xFF141414);
  static const Color border = Color(0xFF262626);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);

  // Signature Accent: Lime Bold
  static const Color accentLime = Color(0xFFB6FF00);
  static const Color limePressed = Color(0xFF9ED900);
  static const Color limeDisabled = Color(0xFF597314);
  static const Color textOnLime = Color(0xFF000000);

  // Error (The single allowed exception outside the palette)
  static const Color errorRed = Color(0xFFFF4D4D);
  static const Color errorSurface = Color(0xFF260A0A);

  // Heatmap Opacity Tiers (Lime on Black)
  static const Color heatmapTier0 = Color(0xFF141414); // 0%
  static final Color heatmapTier1 = accentLime.withValues(alpha: 0.25);
  static final Color heatmapTier2 = accentLime.withValues(alpha: 0.50);
  static final Color heatmapTier3 = accentLime.withValues(alpha: 0.75);
  static const Color heatmapTier4 = accentLime; // 100%
}

class AppRadius {
  static const double card = 18.0;
  static const double sheet = 24.0;
  static const double chip = 8.0;
  static const double button = 14.0;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}
