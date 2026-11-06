enum DharDirection {
  theyOweMe, // I lent money to someone (টাকা পাবো)
  iOweThem,  // I borrowed money from someone (টাকা দিতে হবে)
}

class DharRepayment {
  final String id;
  final int amountPaisa;
  final DateTime date;
  final String notes;

  const DharRepayment({
    required this.id,
    required this.amountPaisa,
    required this.date,
    this.notes = '',
  });

  double get amountBdt => amountPaisa / 100.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountPaisa': amountPaisa,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory DharRepayment.fromJson(Map<String, dynamic> json) => DharRepayment(
        id: json['id'] as String,
        amountPaisa: json['amountPaisa'] as int,
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String? ?? '',
      );
}

class DharRecord {
  final String id;
  final String personId;
  final String personName;
  final int initialAmountPaisa;
  final DharDirection direction;
  final List<DharRepayment> repayments;
  final DateTime? dueDate;
  final String notes;
  final DateTime createdAt;

  const DharRecord({
    required this.id,
    required this.personId,
    required this.personName,
    required this.initialAmountPaisa,
    required this.direction,
    this.repayments = const [],
    this.dueDate,
    this.notes = '',
    required this.createdAt,
  });

  int get totalRepaidPaisa =>
      repayments.fold(0, (sum, r) => sum + r.amountPaisa);

  int get remainingPaisa =>
      (initialAmountPaisa - totalRepaidPaisa).clamp(0, initialAmountPaisa);

  bool get isSettled => remainingPaisa <= 0;

  double get initialBdt => initialAmountPaisa / 100.0;
  double get remainingBdt => remainingPaisa / 100.0;
  double get totalRepaidBdt => totalRepaidPaisa / 100.0;
  int get initialPaisa => initialAmountPaisa;

  DharRecord copyWith({
    String? id,
    String? personId,
    String? personName,
    int? initialAmountPaisa,
    DharDirection? direction,
    List<DharRepayment>? repayments,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return DharRecord(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      initialAmountPaisa: initialAmountPaisa ?? this.initialAmountPaisa,
      direction: direction ?? this.direction,
      repayments: repayments ?? this.repayments,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'personName': personName,
        'initialAmountPaisa': initialAmountPaisa,
        'direction': direction.name,
        'repayments': repayments.map((r) => r.toJson()).toList(),
        'dueDate': dueDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DharRecord.fromJson(Map<String, dynamic> json) => DharRecord(
        id: json['id'] as String,
        personId: json['personId'] as String,
        personName: json['personName'] as String,
        initialAmountPaisa: json['initialAmountPaisa'] as int,
        direction: DharDirection.values.firstWhere((e) => e.name == json['direction']),
        repayments: (json['repayments'] as List<dynamic>? ?? [])
            .map((r) => DharRepayment.fromJson(r as Map<String, dynamic>))
            .toList(),
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
