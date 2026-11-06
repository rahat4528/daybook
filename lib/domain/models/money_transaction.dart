enum TransactionType {
  income,
  expense,
}

enum AccountLabel {
  cash,
  bkash,
  nagad,
  bank,
  other;

  String label({bool isBangla = false}) {
    switch (this) {
      case AccountLabel.cash:
        return isBangla ? 'ক্যাশ (Cash)' : 'Cash';
      case AccountLabel.bkash:
        return 'bKash';
      case AccountLabel.nagad:
        return 'Nagad';
      case AccountLabel.bank:
        return isBangla ? 'ব্যাংক' : 'Bank';
      case AccountLabel.other:
        return isBangla ? 'অন্যান্য' : 'Other';
    }
  }
}

enum ExpenseCategory {
  food,
  transport,
  utilities,
  rent,
  health,
  education,
  shopping,
  salary,
  freelance,
  other;

  String label({bool isBangla = false}) {
    switch (this) {
      case ExpenseCategory.food:
        return isBangla ? 'খাবার' : 'Food';
      case ExpenseCategory.transport:
        return isBangla ? 'যাতায়াত' : 'Transport';
      case ExpenseCategory.utilities:
        return isBangla ? 'বিল ও ইউটিলিটি' : 'Utilities';
      case ExpenseCategory.rent:
        return isBangla ? 'ভাড়া' : 'Rent';
      case ExpenseCategory.health:
        return isBangla ? 'চিকিৎসা' : 'Health';
      case ExpenseCategory.education:
        return isBangla ? 'শিক্ষা' : 'Education';
      case ExpenseCategory.shopping:
        return isBangla ? 'কেনাকাটা' : 'Shopping';
      case ExpenseCategory.salary:
        return isBangla ? 'বেতন' : 'Salary';
      case ExpenseCategory.freelance:
        return isBangla ? 'ফ্রিল্যান্স' : 'Freelance';
      case ExpenseCategory.other:
        return isBangla ? 'অন্যান্য' : 'Other';
    }
  }
}

class MoneyTransaction {
  final String id;
  final int amountPaisa; // 1 BDT = 100 Paisa to guarantee zero rounding errors
  final TransactionType type;
  final ExpenseCategory category;
  final AccountLabel account;
  final String notes;
  final DateTime date;
  final String dayKey;
  final String? linkedPersonId;

  const MoneyTransaction({
    required this.id,
    required this.amountPaisa,
    required this.type,
    required this.category,
    this.account = AccountLabel.cash,
    this.notes = '',
    required this.date,
    required this.dayKey,
    this.linkedPersonId,
  });

  double get amountBdt => amountPaisa / 100.0;

  String formatBdt({bool isBangla = false}) {
    final formatted = amountBdt.toStringAsFixed(2);
    if (isBangla) {
      return '৳$formatted';
    }
    return 'BDT $formatted';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountPaisa': amountPaisa,
        'type': type.name,
        'category': category.name,
        'account': account.name,
        'notes': notes,
        'date': date.toIso8601String(),
        'dayKey': dayKey,
        'linkedPersonId': linkedPersonId,
      };

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) => MoneyTransaction(
        id: json['id'] as String,
        amountPaisa: json['amountPaisa'] as int,
        type: TransactionType.values.firstWhere((e) => e.name == json['type']),
        category: ExpenseCategory.values.firstWhere((e) => e.name == json['category']),
        account: AccountLabel.values.firstWhere((e) => e.name == json['account'], orElse: () => AccountLabel.cash),
        notes: json['notes'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        dayKey: json['dayKey'] as String,
        linkedPersonId: json['linkedPersonId'] as String?,
      );
}
