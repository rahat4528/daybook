// NFC Routine Automation Domain Model for DayBook (Page 04)
// Maps physical NFC tags (NTAG213/215/216) to daily rituals and routines.

enum NfcRoutineCategory {
  plant('Desk Plant', '🌱', 'Water Desk Plants'),
  keys('Keys at Home', '🔑', 'Keys Placed at Home'),
  medication('Vitamins / Medicine', '💊', 'Take Daily Vitamins'),
  coffee('Morning Coffee', '☕', 'Morning Coffee Started'),
  desk('Deep Work', '💻', 'Arrived at Desk / Work Ritual'),
  custom('Custom Routine', '✨', 'Custom Physical Routine');

  final String label;
  final String icon;
  final String defaultTitle;
  const NfcRoutineCategory(this.label, this.icon, this.defaultTitle);
}

class NfcTagItem {
  final String id;
  final String tagUid; // 13.56 MHz NFC hardware UID
  final String label;
  final String routineId;
  final DateTime registeredAt;

  NfcTagItem({
    required this.id,
    required this.tagUid,
    required this.label,
    required this.routineId,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'tagUid': tagUid,
        'label': label,
        'routineId': routineId,
        'registeredAt': registeredAt.toIso8601String(),
      };

  factory NfcTagItem.fromJson(Map<String, dynamic> json) => NfcTagItem(
        id: json['id'] as String,
        tagUid: json['tagUid'] as String,
        label: json['label'] as String,
        routineId: json['routineId'] as String,
        registeredAt: DateTime.parse(json['registeredAt'] as String),
      );
}

class NfcRoutineItem {
  final String id;
  final String name;
  final NfcRoutineCategory category;
  final int recurrenceDays;
  final String? pairedTagUid;
  final DateTime? lastTriggeredAt;
  final int totalCompletions;
  final DateTime createdAt;

  NfcRoutineItem({
    required this.id,
    required this.name,
    this.category = NfcRoutineCategory.custom,
    this.recurrenceDays = 1,
    this.pairedTagUid,
    this.lastTriggeredAt,
    this.totalCompletions = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompletedToday {
    if (lastTriggeredAt == null) return false;
    final now = DateTime.now();
    return lastTriggeredAt!.year == now.year &&
        lastTriggeredAt!.month == now.month &&
        lastTriggeredAt!.day == now.day;
  }

  DateTime? get nextDueDate {
    if (lastTriggeredAt == null) return DateTime.now();
    return lastTriggeredAt!.add(Duration(days: recurrenceDays));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'recurrenceDays': recurrenceDays,
        'pairedTagUid': pairedTagUid,
        'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
        'totalCompletions': totalCompletions,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NfcRoutineItem.fromJson(Map<String, dynamic> json) => NfcRoutineItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: NfcRoutineCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => NfcRoutineCategory.custom,
        ),
        recurrenceDays: json['recurrenceDays'] as int? ?? 1,
        pairedTagUid: json['pairedTagUid'] as String?,
        lastTriggeredAt: json['lastTriggeredAt'] != null
            ? DateTime.parse(json['lastTriggeredAt'] as String)
            : null,
        totalCompletions: json['totalCompletions'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  NfcRoutineItem copyWith({
    String? id,
    String? name,
    NfcRoutineCategory? category,
    int? recurrenceDays,
    String? pairedTagUid,
    DateTime? lastTriggeredAt,
    int? totalCompletions,
  }) =>
      NfcRoutineItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        recurrenceDays: recurrenceDays ?? this.recurrenceDays,
        pairedTagUid: pairedTagUid ?? this.pairedTagUid,
        lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
        totalCompletions: totalCompletions ?? this.totalCompletions,
        createdAt: createdAt,
      );
}

class NfcEventLogItem {
  final String id;
  final String routineId;
  final String routineName;
  final String tagUid;
  final DateTime occurredAt;
  final String? note;

  NfcEventLogItem({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.tagUid,
    DateTime? occurredAt,
    this.note,
  }) : occurredAt = occurredAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'routineName': routineName,
        'tagUid': tagUid,
        'occurredAt': occurredAt.toIso8601String(),
        'note': note,
      };

  factory NfcEventLogItem.fromJson(Map<String, dynamic> json) => NfcEventLogItem(
        id: json['id'] as String,
        routineId: json['routineId'] as String,
        routineName: json['routineName'] as String,
        tagUid: json['tagUid'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        note: json['note'] as String?,
      );
}
