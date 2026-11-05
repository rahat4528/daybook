import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/main.dart';

void main() {
  testWidgets('DayBookApp smoke test and navigation flow', (WidgetTester tester) async {
    await tester.pumpWidget(const DayBookApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Dashboard shows DAYBOOK header & Daily Trajectory
    expect(find.text('DAYBOOK'), findsOneWidget);
    expect(find.text('Daily Trajectory'), findsOneWidget);
    expect(find.text('TODAY\'S PRIORITIES'), findsOneWidget);

    // Switch to Plan Tab
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Daily Time-Block Planner'), findsOneWidget);

    // Switch to Ask Tab
    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('DayBook Assistant'), findsOneWidget);
  });
}
