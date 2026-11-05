import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/design/app_tokens.dart';
import 'package:daybook/core/design/app_typography.dart';
import 'package:daybook/core/design/component_gallery.dart';
import 'package:daybook/data/database/tables.dart';

double _luminance(Color c) {
  double linear(double val) {
    return val <= 0.03928 ? val / 12.92 : pow((val + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linear(c.r);
  final g = linear(c.g);
  final b = linear(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _luminance(c1);
  final l2 = _luminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Part 1 Design Tokens & WCAG Contrast Tests', () {
    test('Token values match Part 1 strict specifications', () {
      expect(AppColors.bg, const Color(0xFF000000));
      expect(AppColors.surface1, const Color(0xFF0A0A0A));
      expect(AppColors.surface2, const Color(0xFF141414));
      expect(AppColors.border, const Color(0xFF262626));
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.textSecondary, const Color(0xFFA3A3A3));
      expect(AppColors.accentLime, const Color(0xFFB6FF00));
      expect(AppColors.textOnLime, const Color(0xFF000000));
      expect(AppColors.errorRed, const Color(0xFFFF4D4D));
    });

    test('WCAG AA and AAA Contrast Compliance', () {
      // 1. Text Primary (White) on OLED Black (Requires >= 7.0:1 for AAA)
      final whiteOnBlack = _contrastRatio(AppColors.textPrimary, AppColors.bg);
      expect(whiteOnBlack, greaterThan(15.0));

      // 2. Signature Lime (#B6FF00) on OLED Black (Requires >= 7.0:1 for AAA)
      final limeOnBlack = _contrastRatio(AppColors.accentLime, AppColors.bg);
      expect(limeOnBlack, greaterThan(15.0));

      // 3. Black Text on Primary Lime Button (Requires >= 7.0:1 for AAA)
      final blackOnLime = _contrastRatio(AppColors.textOnLime, AppColors.accentLime);
      expect(blackOnLime, greaterThan(15.0));

      // 4. Text Secondary (#A3A3A3) on Surface-1 (Requires >= 4.5:1 for AA)
      final secondaryOnSurface = _contrastRatio(AppColors.textSecondary, AppColors.surface1);
      expect(secondaryOnSurface, greaterThanOrEqualTo(4.5));
    });

    test('Rich text parser correctly isolates lime bold spans', () {
      const input = 'Today is a **crucial** milestone for **DayBook**.';
      final spans = AppTypography.parseLimeBold(input);

      expect(spans.length, 5);
      expect(spans[0].text, 'Today is a ');
      expect(spans[1].text, 'crucial');
      expect(spans[1].style?.color, AppColors.accentLime);
      expect(spans[1].style?.fontWeight, FontWeight.bold);
      expect(spans[2].text, ' milestone for ');
      expect(spans[3].text, 'DayBook');
      expect(spans[3].style?.color, AppColors.accentLime);
      expect(spans[4].text, '.');
    });
  });

  group('Part 0 Schema Registry Tests', () {
    test('Schema includes single event log entries and all domain tables', () {
      final tableNames = DayBookSchemaRegistry.allTables.map((t) => t.tableName).toList();

      expect(tableNames.contains('entries'), isTrue);
      expect(tableNames.contains('tasks'), isTrue);
      expect(tableNames.contains('alarms'), isTrue);
      expect(tableNames.contains('alarm_events'), isTrue);
      expect(tableNames.contains('habits'), isTrue);
      expect(tableNames.contains('focus_sessions'), isTrue);
      expect(tableNames.contains('expenses'), isTrue);
      expect(tableNames.contains('debts'), isTrue);
      expect(tableNames.contains('cards'), isTrue);
      expect(tableNames.contains('memories'), isTrue);
      expect(tableNames.contains('chat_messages'), isTrue);
      expect(tableNames.contains('tool_call_log'), isTrue);
      expect(tableNames.contains('day_scores'), isTrue);

      final entriesTable = DayBookSchemaRegistry.allTables.firstWhere((t) => t.tableName == 'entries');
      expect(entriesTable.columns.any((c) => c.contains('day_key')), isTrue);
      expect(entriesTable.columns.any((c) => c.contains('payload_json')), isTrue);
    });
  });

  testWidgets('ComponentGalleryScreen renders all sections without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ComponentGalleryScreen(),
      ),
    );

    expect(find.text('Design System Gallery'), findsOneWidget);
    expect(find.text('1. Surface Cards & Borders'), findsOneWidget);
    expect(find.text('2. Habit Heatmap Tiers (5 Opacities)'), findsOneWidget);
    expect(find.text('3. Primary, Secondary & Destructive Buttons'), findsOneWidget);
    expect(find.text('PRIMARY ACTION'), findsOneWidget);
    expect(find.text('4. Tabular Figures & Alarm Displays'), findsOneWidget);
  });
}

