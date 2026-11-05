class TimeCapsuleItem {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime unlockAt;
  final bool isUnlocked;
  final bool notified;

  const TimeCapsuleItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.unlockAt,
    this.isUnlocked = false,
    this.notified = false,
  });

  bool get shouldUnlock => DateTime.now().isAfter(unlockAt);

  int get daysRemaining {
    final diff = unlockAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  TimeCapsuleItem copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? unlockAt,
    bool? isUnlocked,
    bool? notified,
  }) {
    return TimeCapsuleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      unlockAt: unlockAt ?? this.unlockAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      notified: notified ?? this.notified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'unlock_at': unlockAt.toIso8601String(),
      'is_unlocked': isUnlocked,
      'notified': notified,
    };
  }

  factory TimeCapsuleItem.fromJson(Map<String, dynamic> json) {
    return TimeCapsuleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      unlockAt: DateTime.parse(json['unlock_at'] as String),
      isUnlocked: json['is_unlocked'] == true,
      notified: json['notified'] == true,
    );
  }
}
