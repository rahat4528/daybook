import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/dhar_record.dart';
import '../../domain/models/money_transaction.dart';
import '../../domain/services/dhar_service.dart';
import '../../domain/services/money_service.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/database/local_storage_service.dart';

class MoneyScreen extends StatefulWidget {
  final MoneyService moneyService;
  final DharService dharService;
  final EntriesRepository entriesRepo;
  final bool isBangla;

  const MoneyScreen({
    super.key,
    required this.moneyService,
    required this.dharService,
    required this.entriesRepo,
    this.isBangla = false,
  });

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTransactionModal() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    TransactionType txType = TransactionType.expense;
    ExpenseCategory category = ExpenseCategory.food;
    AccountLabel account = AccountLabel.bkash;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isBangla ? 'নতুন লেনদেন' : 'Add Transaction',
                        style: AppTypography.screenTitle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Income / Expense Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text(widget.isBangla ? 'খরচ (Expense)' : 'Expense'),
                          selected: txType == TransactionType.expense,
                          selectedColor: AppColors.accentLime,
                          backgroundColor: AppColors.surface2,
                          labelStyle: TextStyle(
                            color: txType == TransactionType.expense ? AppColors.bg : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => txType = TransactionType.expense);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: Text(widget.isBangla ? 'আয় (Income)' : 'Income'),
                          selected: txType == TransactionType.income,
                          selectedColor: AppColors.accentLime,
                          backgroundColor: AppColors.surface2,
                          labelStyle: TextStyle(
                            color: txType == TransactionType.income ? AppColors.bg : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => txType = TransactionType.income);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount in BDT
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.tabularNumber.copyWith(fontSize: 24, color: AppColors.accentLime),
                    decoration: InputDecoration(
                      prefixText: '৳ ',
                      prefixStyle: const TextStyle(color: AppColors.accentLime, fontSize: 24),
                      hintText: '0.00',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Account Selector
                  DropdownButtonFormField<AccountLabel>(
                    value: account,
                    dropdownColor: AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'অ্যাকাউন্ট' : 'Account',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: AccountLabel.values.map((a) {
                      return DropdownMenuItem(value: a, child: Text(a.label(isBangla: widget.isBangla), style: const TextStyle(color: AppColors.textPrimary)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => account = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  DropdownButtonFormField<ExpenseCategory>(
                    value: category,
                    dropdownColor: AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'ক্যাটাগরি' : 'Category',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ExpenseCategory.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.label(isBangla: widget.isBangla), style: const TextStyle(color: AppColors.textPrimary)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextField(
                    controller: notesController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: widget.isBangla ? 'বিবরণ (ঐচ্ছিক)' : 'Notes / Merchant (optional)',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      ),
                      onPressed: () {
                        final raw = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (raw > 0) {
                          final paisa = (raw * 100).round();
                          widget.moneyService.recordTransaction(
                            amountPaisa: paisa,
                            type: txType,
                            category: category,
                            account: account,
                            notes: notesController.text.trim(),
                            entriesRepo: widget.entriesRepo,
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                        }
                      },
                      child: Text(
                        widget.isBangla ? 'সংরক্ষণ করুন' : 'Save Transaction',
                        style: AppTypography.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDharModal() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DharDirection direction = DharDirection.theyOweMe;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isBangla ? 'নতুন ধার এন্ট্রি' : 'New Dhar (Loan) Record',
                    style: AppTypography.screenTitle,
                  ),
                  const SizedBox(height: 16),

                  // Direction Segmented Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text(widget.isBangla ? 'টাকা পাবো (Lent)' : 'They Owe Me'),
                          selected: direction == DharDirection.theyOweMe,
                          selectedColor: AppColors.accentLime,
                          backgroundColor: AppColors.surface2,
                          labelStyle: TextStyle(
                            color: direction == DharDirection.theyOweMe ? AppColors.bg : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => direction = DharDirection.theyOweMe);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text(widget.isBangla ? 'টাকা দিতে হবে' : 'I Owe Them'),
                          selected: direction == DharDirection.iOweThem,
                          selectedColor: AppColors.errorRed,
                          backgroundColor: AppColors.surface2,
                          labelStyle: TextStyle(
                            color: direction == DharDirection.iOweThem ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => direction = DharDirection.iOweThem);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'ব্যক্তির নাম' : 'Person Name',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.tabularNumber.copyWith(fontSize: 22, color: AppColors.accentLime),
                    decoration: InputDecoration(
                      prefixText: '৳ ',
                      labelText: widget.isBangla ? 'পরিমাণ (টাকা)' : 'Amount (BDT)',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: notesController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'বিবরণ / কারণ' : 'Notes / Reason',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      ),
                      onPressed: () {
                        final raw = double.tryParse(amountController.text.trim()) ?? 0.0;
                        final name = nameController.text.trim();
                        if (raw > 0 && name.isNotEmpty) {
                          final paisa = (raw * 100).round();
                          widget.dharService.addRecord(
                            personId: 'per_${DateTime.now().microsecondsSinceEpoch}',
                            personName: name,
                            amountPaisa: paisa,
                            direction: direction,
                            notes: notesController.text.trim(),
                            entriesRepo: widget.entriesRepo,
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                        }
                      },
                      child: Text(
                        widget.isBangla ? 'ধার সংরক্ষণ' : 'Record Loan',
                        style: AppTypography.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRepaymentModal(DharRecord record) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          widget.isBangla ? 'কিস্তি / আংশিক পরিশোধ' : 'Record Partial Repayment',
          style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Person: ${record.personName} • Remaining: ৳${record.remainingBdt.toStringAsFixed(2)}",
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.tabularNumber.copyWith(color: AppColors.accentLime),
              decoration: InputDecoration(
                prefixText: '৳ ',
                hintText: 'Repayment amount',
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.isBangla ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: AppColors.bg,
            ),
            onPressed: () {
              final val = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (val > 0) {
                final paisa = (val * 100).round();
                final ok = widget.dharService.addRepayment(
                  dharId: record.id,
                  amountPaisa: paisa,
                  entriesRepo: widget.entriesRepo,
                );
                if (ok) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              }
            },
            child: Text(widget.isBangla ? 'পরিশোধ নিশ্চিত' : 'Confirm Repayment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceBdt = widget.moneyService.netBalanceBdt;
    final incomeBdt = widget.moneyService.totalIncomeBdt;
    final expenseBdt = widget.moneyService.totalExpenseBdt;
    final transactions = widget.moneyService.transactions;
    final receivables = widget.dharService.activeReceivables;
    final payables = widget.dharService.activePayables;
    final summaries = widget.moneyService.getCategorySummaries();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text(
          widget.isBangla ? 'টাকা ও ধার (Money)' : 'Money & Ledger',
          style: AppTypography.screenTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.accentLime),
            tooltip: 'Export CSV',
            onPressed: () async {
              final csv = widget.moneyService.exportToCsv();
              final rowCount = csv.split('\n').where((l) => l.trim().isNotEmpty).length - 1;
              await LocalStorageService.shareTextFile(
                fileName: 'daybook_transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
                content: csv,
                mimeType: 'text/csv',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('CSV Exported ($rowCount rows) & Ready to Share'),
                    backgroundColor: AppColors.accentLime,
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentLime,
          labelColor: AppColors.accentLime,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: widget.isBangla ? 'খতিয়ান (Ledger)' : 'Ledger'),
            Tab(text: widget.isBangla ? 'ধার (Dhar)' : 'Dhar Tracker'),
            Tab(text: widget.isBangla ? 'হিসাব (Summary)' : 'Summary'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.bg,
        onPressed: _tabController.index == 1 ? _showAddDharModal : _showAddTransactionModal,
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          // Balance Overview Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isBangla ? 'মোট ব্যালেন্স' : 'NET BALANCE',
                  style: AppTypography.caption.copyWith(letterSpacing: 1.0, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  '৳${balanceBdt.toStringAsFixed(2)}',
                  style: AppTypography.keyMetricLime,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.isBangla ? 'মোট আয়' : 'Total Income', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text('৳${incomeBdt.toStringAsFixed(2)}', style: AppTypography.tabularNumber),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.isBangla ? 'মোট খরচ' : 'Total Expense', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text('৳${expenseBdt.toStringAsFixed(2)}', style: AppTypography.tabularNumber.copyWith(color: AppColors.errorRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Ledger List
                transactions.isEmpty
                    ? Center(
                        child: Text(
                          widget.isBangla ? 'কোনো লেনদেন রেকর্ড নেই।' : 'No transactions recorded yet.',
                          style: AppTypography.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (ctx, i) {
                          final tx = transactions[i];
                          final isExpense = tx.type == TransactionType.expense;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Icon(
                                    isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                                    color: isExpense ? AppColors.errorRed : AppColors.accentLime,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.notes.isNotEmpty ? tx.notes : tx.category.label(isBangla: widget.isBangla),
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${tx.account.label(isBangla: widget.isBangla)} • ${tx.dayKey}',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isExpense ? '-' : '+'}৳${tx.amountBdt.toStringAsFixed(2)}',
                                  style: AppTypography.tabularNumber.copyWith(
                                    color: isExpense ? AppColors.textPrimary : AppColors.accentLime,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                // Tab 2: Dhar Tracker (Who owes whom)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary pills
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              border: Border.all(color: AppColors.accentLime),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.isBangla ? 'পাবো (Receivable)' : 'They Owe Me', style: AppTypography.caption),
                                const SizedBox(height: 4),
                                Text('৳${widget.dharService.totalReceivableBdt.toStringAsFixed(2)}', style: AppTypography.tabularNumber.copyWith(color: AppColors.accentLime)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              border: Border.all(color: AppColors.errorRed),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.isBangla ? 'দিতে হবে (Payable)' : 'I Owe Them', style: AppTypography.caption),
                                const SizedBox(height: 4),
                                Text('৳${widget.dharService.totalPayableBdt.toStringAsFixed(2)}', style: AppTypography.tabularNumber.copyWith(color: AppColors.errorRed)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (receivables.isEmpty && payables.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            widget.isBangla ? 'বর্তমানে কোনো সক্রিয় ধার নেই।' : 'No active debts recorded.',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ),

                    // Receivables
                    ...receivables.map((r) => _buildDharCard(r)),
                    // Payables
                    ...payables.map((r) => _buildDharCard(r)),
                  ],
                ),

                // Tab 3: Summary & Category Bars
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.isBangla ? 'ক্যাটাগরি অনুযায়ী খরচ' : 'Expense by Category',
                      style: AppTypography.sectionHeader,
                    ),
                    const SizedBox(height: 16),
                    ...summaries.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s.category.label(isBangla: widget.isBangla), style: AppTypography.bodyMedium),
                                Text('৳${s.totalBdt.toStringAsFixed(2)} (${s.percentage.toStringAsFixed(1)}%)', style: AppTypography.tabularNumber),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.percentage / 100.0,
                                minHeight: 8,
                                backgroundColor: AppColors.surface2,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentLime),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Mandatory Disclaimer Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  widget.isBangla
                      ? 'ব্যক্তিগত হিসাব লগ — কোনো আর্থিক পরামর্শ নয়।'
                      : 'Personal ledger log only — not financial advice.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDharCard(DharRecord r) {
    final isLent = r.direction == DharDirection.theyOweMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: isLent ? AppColors.accentLime : AppColors.errorRed),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.personName, style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
              Text(
                '৳${r.remainingBdt.toStringAsFixed(2)}',
                style: AppTypography.tabularNumber.copyWith(
                  color: isLent ? AppColors.accentLime : AppColors.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isLent
                ? (widget.isBangla ? 'টাকা ধার দেওয়া হয়েছে' : 'Lent money')
                : (widget.isBangla ? 'টাকা ধার নেওয়া হয়েছে' : 'Borrowed money'),
            style: AppTypography.caption,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Initial: ৳${r.initialBdt.toStringAsFixed(2)} • Repaid: ৳${r.totalRepaidBdt.toStringAsFixed(2)}',
                style: AppTypography.caption,
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentLime,
                  side: const BorderSide(color: AppColors.accentLime),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showRepaymentModal(r),
                child: Text(widget.isBangla ? 'পরিশোধ' : 'Repay'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
