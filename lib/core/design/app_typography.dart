import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppTypography {
  static const TextStyle screenTitle = TextStyle(
    color: AppColors.accentLime,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    color: AppColors.accentLime,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 1.5, // Mandatory for Bangla diacritics
  );

  static const TextStyle bodySecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.4,
  );

  static const TextStyle tabularNumber = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle keyMetricLime = TextStyle(
    color: AppColors.accentLime,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle headingMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headingSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyMedium = body;
  static const TextStyle bodySmall = bodySecondary;

  static const TextStyle caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    height: 1.3,
  );

  static const TextStyle buttonText = TextStyle(
    color: AppColors.textOnLime,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
  );

  /// Converts markdown bold segments (**text**) into signature Lime Bold text spans.
  static List<TextSpan> parseLimeBold(String rawText, {TextStyle? defaultStyle}) {
    final style = defaultStyle ?? body;
    final limeStyle = style.copyWith(
      color: AppColors.accentLime,
      fontWeight: FontWeight.bold,
    );

    final List<TextSpan> spans = [];
    final pattern = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(rawText)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: rawText.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: limeStyle,
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(lastMatchEnd),
        style: style,
      ));
    }

    return spans;
  }
}

