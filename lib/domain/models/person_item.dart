enum PersonRelationship {
  family,
  friend,
  colleague,
  mentor,
  other;

  String label({bool isBangla = false}) {
    switch (this) {
      case PersonRelationship.family:
        return isBangla ? 'পরিবার' : 'Family';
      case PersonRelationship.friend:
        return isBangla ? 'বন্ধু' : 'Friend';
      case PersonRelationship.colleague:
        return isBangla ? 'সহকর্মী' : 'Colleague';
      case PersonRelationship.mentor:
        return isBangla ? 'পরামর্শক / শিক্ষক' : 'Mentor';
      case PersonRelationship.other:
        return isBangla ? 'অন্যান্য' : 'Other';
    }
  }
}

enum CadenceHealth {
  fresh,    // Contacted recently (within schedule)
  dueSoon,  // Due within 48 hours
  overdue,  // Missed cadence
  none,     // No cadence set
}

class PersonItem {
  final String id;
  final String name;
  final PersonRelationship relationship;
  final String phone;
  final DateTime? birthday;
  final int? cadenceDays; // Target interaction interval in days
  final DateTime? lastContactedAt;
  final List<String> giftIdeas;
  final String notes;
  final List<String> interactionLogs;

  const PersonItem({
    required this.id,
    required this.name,
    this.relationship = PersonRelationship.friend,
    this.phone = '',
    this.birthday,
    this.cadenceDays,
    this.lastContactedAt,
    this.giftIdeas = const [],
    this.notes = '',
    this.interactionLogs = const [],
  });

  int? get daysSinceLastContact {
    if (lastContactedAt == null) return null;
    return DateTime.now().difference(lastContactedAt!).inDays;
  }

  CadenceHealth get cadenceHealth {
    if (cadenceDays == null || cadenceDays! <= 0) return CadenceHealth.none;
    if (lastContactedAt == null) return CadenceHealth.overdue;

    final elapsed = daysSinceLastContact!;
    if (elapsed > cadenceDays!) return CadenceHealth.overdue;
    if (cadenceDays! - elapsed <= 2) return CadenceHealth.dueSoon;
    return CadenceHealth.fresh;
  }

  bool get isBirthdaySoon {
    if (birthday == null) return false;
    final now = DateTime.now();
    final thisYearBday = DateTime(now.year, birthday!.month, birthday!.day);
    final diff = thisYearBday.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff >= 0 && diff <= 7;
  }

  PersonItem copyWith({
    String? id,
    String? name,
    PersonRelationship? relationship,
    String? phone,
    DateTime? birthday,
    int? cadenceDays,
    DateTime? lastContactedAt,
    List<String>? giftIdeas,
    String? notes,
    List<String>? interactionLogs,
  }) {
    return PersonItem(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      cadenceDays: cadenceDays ?? this.cadenceDays,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      giftIdeas: giftIdeas ?? this.giftIdeas,
      notes: notes ?? this.notes,
      interactionLogs: interactionLogs ?? this.interactionLogs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship.name,
        'phone': phone,
        'birthday': birthday?.toIso8601String(),
        'cadenceDays': cadenceDays,
        'lastContactedAt': lastContactedAt?.toIso8601String(),
        'giftIdeas': giftIdeas,
        'notes': notes,
        'interactionLogs': interactionLogs,
      };

  factory PersonItem.fromJson(Map<String, dynamic> json) => PersonItem(
        id: json['id'] as String,
        name: json['name'] as String,
        relationship: PersonRelationship.values.firstWhere((e) => e.name == json['relationship']),
        phone: json['phone'] as String? ?? '',
        birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
        cadenceDays: json['cadenceDays'] as int?,
        lastContactedAt: json['lastContactedAt'] != null ? DateTime.parse(json['lastContactedAt'] as String) : null,
        giftIdeas: List<String>.from(json['giftIdeas'] as List? ?? []),
        notes: json['notes'] as String? ?? '',
        interactionLogs: List<String>.from(json['interactionLogs'] as List? ?? []),
      );
}
