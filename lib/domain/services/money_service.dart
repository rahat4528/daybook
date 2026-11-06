import 'package:flutter/foundation.dart';
import '../models/day_page.dart';
import '../models/journal_entry.dart';
import '../models/money_transaction.dart';
import '../../data/repositories/entries_repository.dart';

class CategorySummary {
  final ExpenseCategory category;
  final int totalPaisa;
  final double percentage;

  const CategorySummary({
    required this.category,
    required this.totalPaisa,
    required this.percentage,
  });

  double get totalBdt => totalPaisa / 100.0;
}

class MoneyService extends ChangeNotifier {
  static int _txCounter = 0;
  final Map<String, MoneyTransaction> _transactions = {};
  final Map<ExpenseCategory, int> _monthlyBudgetsPaisa = {};

  List<MoneyTransaction> get transactions {
    final list = _transactions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // --- CRUD TRANSACTIONS ---

  MoneyTransaction recordTransaction({
    required int amountPaisa,
    required TransactionType type,
    required ExpenseCategory category,
    AccountLabel account = AccountLabel.cash,
    String notes = '',
    DateTime? date,
    String? linkedPersonId,
    EntriesRepository? entriesRepo,
  }) {
    if (amountPaisa <= 0) {
      throw ArgumentError('Transaction amount must be strictly greater than zero paisa.');
    }

    final txDate = date ?? DateTime.now();
    final dayKey = DayPageModel.formatDayKey(txDate);
    final id = 'tx_${txDate.microsecondsSinceEpoch}_${++_txCounter}';

    final tx = MoneyTransaction(
      id: id,
      amountPaisa: amountPaisa,
      type: type,
      category: category,
      account: account,
      notes: notes,
      date: txDate,
      dayKey: dayKey,
      linkedPersonId: linkedPersonId,
    );

    _transactions[id] = tx;

    // Write to Single Event Log
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_money_$id',
      type: EntryType.expenseLogged,
      ts: txDate,
      dayKey: dayKey,
      payload: {
        'txId': id,
        'amountPaisa': amountPaisa,
        'type': type.name,
        'category': category.name,
        'account': account.name,
        'notes': notes,
        'amountBdt': tx.amountBdt,
      },
    ));

    notifyListeners();
    return tx;
  }

  bool deleteTransaction(String id) {
    final removed = _transactions.remove(id);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- FINANCIAL RECONCILIATION TO THE PAISA ---

  int get totalIncomePaisa {
    return _transactions.values
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amountPaisa);
  }

  int get totalExpensePaisa {
    return _transactions.values
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amountPaisa);
  }

  int get netBalancePaisa => totalIncomePaisa - totalExpensePaisa;

  double get totalIncomeBdt => totalIncomePaisa / 100.0;
  double get totalExpenseBdt => totalExpensePaisa / 100.0;
  double get netBalanceBdt => netBalancePaisa / 100.0;

  // --- CATEGORY BREAKDOWN ---

  List<CategorySummary> getCategorySummaries({TransactionType type = TransactionType.expense}) {
    final filtered = _transactions.values.where((t) => t.type == type).toList();
    final total = filtered.fold(0, (sum, t) => sum + t.amountPaisa);
    if (total == 0) return [];

    final Map<ExpenseCategory, int> catMap = {};
    for (final t in filtered) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amountPaisa;
    }

    final summaries = catMap.entries.map((e) {
      final percentage = (e.value / total) * 100.0;
      return CategorySummary(
        category: e.key,
        totalPaisa: e.value,
        percentage: percentage,
      );
    }).toList();

    summaries.sort((a, b) => b.totalPaisa.compareTo(a.totalPaisa));
    return summaries;
  }

  // --- BUDGETS & ALERTS ---

  void setCategoryBudget(ExpenseCategory category, int budgetPaisa) {
    _monthlyBudgetsPaisa[category] = budgetPaisa;
    notifyListeners();
  }

  void setMonthlyBudget(ExpenseCategory category, int budgetPaisa) =>
      setCategoryBudget(category, budgetPaisa);

  int? getCategoryBudget(ExpenseCategory category) => _monthlyBudgetsPaisa[category];

  int getSpentForCategoryPaisa(ExpenseCategory category) {
    return _transactions.values
        .where((t) => t.type == TransactionType.expense && t.category == category)
        .fold(0, (sum, t) => sum + t.amountPaisa);
  }

  int getRemainingBudgetPaisa(ExpenseCategory category) {
    final budget = _monthlyBudgetsPaisa[category] ?? 0;
    final spent = getSpentForCategoryPaisa(category);
    return budget - spent;
  }

  double getBudgetUsagePercentage(ExpenseCategory category) {
    final budget = _monthlyBudgetsPaisa[category] ?? 0;
    if (budget <= 0) return 0.0;
    final spent = getSpentForCategoryPaisa(category);
    return (spent / budget) * 100.0;
  }

  bool isCategoryOverBudget(ExpenseCategory category) {
    final budget = _monthlyBudgetsPaisa[category];
    if (budget == null || budget <= 0) return false;
    return getSpentForCategoryPaisa(category) > budget;
  }

  List<CategorySummary> getMonthlyBreakdown({TransactionType type = TransactionType.expense}) =>
      getCategorySummaries(type: type);

  String formatBdt(int paisa) => '৳${(paisa / 100.0).toStringAsFixed(2)}';

  // --- RFC 4180 CSV EXPORT ---

  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,DayKey,Type,Category,Account,Amount_Paisa,Amount_BDT,Notes');

    for (final tx in transactions) {
      final cleanNotes = tx.notes.replaceAll('"', '""');
      buffer.writeln(
        '${tx.id},${tx.date.toIso8601String()},${tx.dayKey},${tx.type.name},${tx.category.name},${tx.account.name},${tx.amountPaisa},${tx.amountBdt.toStringAsFixed(2)},"$cleanNotes"',
      );
    }
    return buffer.toString();
  }
}
