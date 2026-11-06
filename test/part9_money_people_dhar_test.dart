import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/domain/models/money_transaction.dart';
import 'package:daybook/domain/models/dhar_record.dart';
import 'package:daybook/domain/models/person_item.dart';
import 'package:daybook/domain/services/money_service.dart';
import 'package:daybook/domain/services/dhar_service.dart';
import 'package:daybook/domain/services/people_service.dart';
import 'package:daybook/data/repositories/entries_repository.dart';
import 'package:daybook/presentation/screens/money_screen.dart';
import 'package:daybook/presentation/screens/people_screen.dart';

void main() {
  group('Part 9: MoneyService Integer Paisa Precision', () {
    late MoneyService moneyService;
    late EntriesRepository entriesRepo;

    setUp(() {
      moneyService = MoneyService();
      entriesRepo = EntriesRepository();
    });

    test('Strict integer paisa math avoids IEEE 754 floating point drift', () {
      // 100.50 BDT = 10050 paisa
      //  50.25 BDT =  5025 paisa
      // -20.75 BDT =  2075 paisa
      // Net should be exactly 130.00 BDT = 13000 paisa
      moneyService.recordTransaction(
        amountPaisa: 10050,
        type: TransactionType.income,
        category: ExpenseCategory.salary,
        notes: 'Deposit 1',
        entriesRepo: entriesRepo,
      );
      moneyService.recordTransaction(
        amountPaisa: 5025,
        type: TransactionType.income,
        category: ExpenseCategory.other,
        notes: 'Deposit 2',
        entriesRepo: entriesRepo,
      );
      moneyService.recordTransaction(
        amountPaisa: 2075,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        notes: 'Lunch',
        entriesRepo: entriesRepo,
      );

      expect(moneyService.totalIncomePaisa, equals(15075));
      expect(moneyService.totalExpensePaisa, equals(2075));
      expect(moneyService.netBalancePaisa, equals(13000));
      expect(moneyService.netBalanceBdt, equals(130.00));
      expect(moneyService.formatBdt(moneyService.netBalancePaisa), equals('৳130.00'));
    });

    test('Zero or negative amounts throw ArgumentError', () {
      expect(
        () => moneyService.recordTransaction(
          amountPaisa: 0,
          type: TransactionType.income,
          category: ExpenseCategory.salary,
        ),
        throwsArgumentError,
      );
      expect(
        () => moneyService.recordTransaction(
          amountPaisa: -500,
          type: TransactionType.expense,
          category: ExpenseCategory.food,
        ),
        throwsArgumentError,
      );
    });

    test('Category summaries and budget limits calculate correctly', () {
      moneyService.recordTransaction(
        amountPaisa: 300000, // ৳3,000 on food
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        entriesRepo: entriesRepo,
      );
      moneyService.recordTransaction(
        amountPaisa: 100000, // ৳1,000 on transport
        type: TransactionType.expense,
        category: ExpenseCategory.transport,
        entriesRepo: entriesRepo,
      );

      final breakdown = moneyService.getMonthlyBreakdown();
      expect(breakdown.length, equals(2));
      expect(breakdown.first.category, equals(ExpenseCategory.food));
      expect(breakdown.first.totalPaisa, equals(300000));
      expect(breakdown.first.percentage, closeTo(75.0, 0.01));

      // Test budget limit
      moneyService.setMonthlyBudget(ExpenseCategory.food, 500000); // ৳5,000 budget
      final remainingPaisa = moneyService.getRemainingBudgetPaisa(ExpenseCategory.food);
      expect(remainingPaisa, equals(200000)); // ৳2,000 remaining
      expect(moneyService.getBudgetUsagePercentage(ExpenseCategory.food), closeTo(60.0, 0.01));
    });

    test('RFC 4180 CSV Export generates valid tabular format', () {
      moneyService.recordTransaction(
        amountPaisa: 250000,
        type: TransactionType.income,
        category: ExpenseCategory.salary,
        account: AccountLabel.bank,
        notes: 'Monthly bonus, "Special project"',
      );

      final csv = moneyService.exportToCsv();
      expect(csv, contains('ID,Date,DayKey,Type,Category,Account,Amount_Paisa,Amount_BDT,Notes'));
      expect(csv, contains('income,salary,bank,250000,2500.00'));
      expect(csv, contains('"Monthly bonus, ""Special project"""'));
    });
  });

  group('Part 9: DharService (ধার) Debt & Partial Repayments', () {
    late DharService dharService;
    late EntriesRepository entriesRepo;

    setUp(() {
      dharService = DharService();
      entriesRepo = EntriesRepository();
    });

    test('Records receivable debt and supports multiple micro-repayments until settled', () {
      final now = DateTime.now();
      final loan = dharService.addRecord(
        personId: 'per_1',
        personName: 'Tanvir Ahmed',
        amountPaisa: 500000, // ৳5,000 lent
        direction: DharDirection.theyOweMe,
        dueDate: now.add(const Duration(days: 14)),
        notes: 'Laptop repair loan',
        entriesRepo: entriesRepo,
      );

      expect(loan.initialPaisa, equals(500000));
      expect(loan.remainingPaisa, equals(500000));
      expect(loan.isSettled, isFalse);
      expect(dharService.totalReceivablePaisa, equals(500000));

      // 1st partial repayment: ৳2,000
      final rep1 = dharService.recordRepayment(
        recordId: loan.id,
        amountPaisa: 200000,
        note: 'Partial via bKash',
        entriesRepo: entriesRepo,
      );
      expect(rep1.remainingPaisa, equals(300000));
      expect(rep1.isSettled, isFalse);
      expect(dharService.totalReceivablePaisa, equals(300000));

      // 2nd partial repayment: remaining ৳3,000
      final rep2 = dharService.recordRepayment(
        recordId: loan.id,
        amountPaisa: 300000,
        note: 'Final installment via cash',
        entriesRepo: entriesRepo,
      );
      expect(rep2.remainingPaisa, equals(0));
      expect(rep2.isSettled, isTrue);
      expect(dharService.totalReceivablePaisa, equals(0));
      expect(dharService.settledRecords.length, equals(1));
    });

    test('Repayment exceeding remaining amount throws ArgumentError', () {
      final loan = dharService.addRecord(
        personId: 'per_2',
        personName: 'Uncle Rahim',
        amountPaisa: 100000, // ৳1,000
        direction: DharDirection.theyOweMe,
      );

      expect(
        () => dharService.recordRepayment(
          recordId: loan.id,
          amountPaisa: 150000, // ৳1,500 exceeds ৳1,000
        ),
        throwsArgumentError,
      );
    });

    test('Payable debt (I owe them) tracks liabilities correctly', () {
      dharService.addRecord(
        personId: 'per_3',
        personName: 'Uncle Karim',
        amountPaisa: 250000, // ৳2,500 borrowed
        direction: DharDirection.iOweThem,
      );

      expect(dharService.totalPayablePaisa, equals(250000));
      expect(dharService.totalPayableBdt, equals(2500.0));
      expect(dharService.activePayables.length, equals(1));
    });
  });

  group('Part 9: PeopleService & Keep-in-Touch Cadence', () {
    late PeopleService peopleService;

    setUp(() {
      peopleService = PeopleService();
    });

    test('Calculates contact cadence health: fresh, dueSoon, and overdue', () {
      final now = DateTime.now();

      // Person 1: 7-day cadence, contacted today -> fresh
      final p1 = peopleService.addPerson(
        name: 'Ammu',
        relationship: PersonRelationship.family,
        cadenceDays: 7,
        lastContactedAt: now,
      );
      expect(p1.cadenceHealth, equals(CadenceHealth.fresh));

      // Person 2: 7-day cadence, contacted 6 days ago -> dueSoon
      final p2 = peopleService.addPerson(
        name: 'Tanvir',
        relationship: PersonRelationship.friend,
        cadenceDays: 7,
        lastContactedAt: now.subtract(const Duration(days: 6)),
      );
      expect(p2.cadenceHealth, equals(CadenceHealth.dueSoon));

      // Person 3: 14-day cadence, contacted 20 days ago -> overdue
      final p3 = peopleService.addPerson(
        name: 'Dr. Hasan',
        relationship: PersonRelationship.mentor,
        cadenceDays: 14,
        lastContactedAt: now.subtract(const Duration(days: 20)),
      );
      expect(p3.cadenceHealth, equals(CadenceHealth.overdue));

      expect(peopleService.overduePeople.map((p) => p.name), contains('Dr. Hasan'));
    });

    test('Upcoming birthday within next 7 days detected', () {
      final now = DateTime.now();
      final upcomingDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 4));

      final person = peopleService.addPerson(
        name: 'Sarah',
        relationship: PersonRelationship.friend,
        birthday: upcomingDate,
      );

      expect(person.isBirthdaySoon, isTrue);
      expect(peopleService.upcomingBirthdays.map((p) => p.name), contains('Sarah'));
    });

    test('markContacted updates lastContactedAt and logs interaction', () {
      final now = DateTime.now();
      final p = peopleService.addPerson(
        name: 'Zahid',
        cadenceDays: 5,
        lastContactedAt: now.subtract(const Duration(days: 10)),
      );
      expect(p.cadenceHealth, equals(CadenceHealth.overdue));

      final updated = peopleService.markContacted(
        p.id,
        note: 'Had a long phone conversation about career plans',
      );
      expect(updated.cadenceHealth, equals(CadenceHealth.fresh));
      expect(updated.interactionLogs.length, equals(1));
    });
  });

  group('Part 9: Widget Smoke Tests', () {
    late MoneyService moneyService;
    late DharService dharService;
    late PeopleService peopleService;
    late EntriesRepository entriesRepo;

    setUp(() {
      moneyService = MoneyService();
      dharService = DharService();
      peopleService = PeopleService();
      entriesRepo = EntriesRepository();

      // Seed realistic data
      moneyService.recordTransaction(
        amountPaisa: 1500000, // ৳15,000
        type: TransactionType.income,
        category: ExpenseCategory.salary,
        notes: 'Consulting fee',
      );
      moneyService.recordTransaction(
        amountPaisa: 250000, // ৳2,500
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        notes: 'Monthly pantry groceries',
      );

      dharService.addRecord(
        personId: 'per_smoke',
        personName: 'Shakil Khan',
        amountPaisa: 300000,
        direction: DharDirection.theyOweMe,
      );

      peopleService.addPerson(
        name: 'Nusrat Jahan',
        relationship: PersonRelationship.colleague,
        cadenceDays: 14,
        lastContactedAt: DateTime.now().subtract(const Duration(days: 2)),
      );
    });

    testWidgets('MoneyScreen renders ledger, balance card, and disclaimer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyScreen(
            isBangla: false,
            moneyService: moneyService,
            dharService: dharService,
            entriesRepo: entriesRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Money & Ledger'), findsOneWidget);
      expect(find.text('NET BALANCE'), findsOneWidget);
      expect(find.text('৳12500.00'), findsOneWidget);
      expect(find.text('Consulting fee'), findsOneWidget);
      expect(find.text('Monthly pantry groceries'), findsOneWidget);
      expect(find.text('Personal ledger log only — not financial advice.'), findsOneWidget);
    });

    testWidgets('PeopleScreen renders directory, chips, and add button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PeopleScreen(
            isBangla: false,
            peopleService: peopleService,
            entriesRepo: entriesRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('People & Connections'), findsOneWidget);
      expect(find.text('Nusrat Jahan'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
