import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/main.dart';

void main() {
  testWidgets('DaybookRootApp smoke test and navigation flow', (WidgetTester tester) async {
    await tester.pumpWidget(const DaybookRootApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Dashboard shows Daybook title & Daily Trajectory
    expect(find.text('Daybook'), findsWidgets);
    expect(find.text('Daily Trajectory'), findsOneWidget);
    expect(find.text('Eisenhower Mission Tasks'), findsOneWidget);

    // Switch to Tasks Tab
    await tester.tap(find.byIcon(Icons.checklist_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Task Command Center'), findsOneWidget);

    // Switch to Planner Tab
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Daily Time-Block Planner'), findsOneWidget);

    // Switch to Alarms Tab
    await tester.tap(find.byIcon(Icons.alarm_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Smart Alarms & Challenges'), findsOneWidget);

    // Switch to Assistant Tab
    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Daybook Assistant'), findsOneWidget);
  });
}
