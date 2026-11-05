enum MemoryKind {
  fact,
  preference,
  episodic,
}

class MemoryItem {
  final String id;
  final String text;
  final MemoryKind kind;
  final bool isPinned;
  final bool isApproved;
  final DateTime createdAt;

  const MemoryItem({
    required this.id,
    required this.text,
    required this.kind,
    this.isPinned = false,
    this.isApproved = true,
    required this.createdAt,
  });

  /// Sanitizes text to prevent storing passwords or sensitive identifiers
  static String sanitizeText(String raw) {
    var sanitized = raw;
    // Password patterns (e.g. "password is Secret123", "password: Secret123", "pin = 1234")
    sanitized = sanitized.replaceAll(
      RegExp(r'(password|pass|secret|pin|api[_\s]?key)(?:\s+is|\s*[:=])?\s+([^\s,;]+)', caseSensitive: false),
      r'$1: [REDACTED]',
    );
    // 16-digit card numbers
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:\d{4}[ -]?){3}\d{4}\b'),
      '[CARD_REDACTED]',
    );
    return sanitized.trim();
  }

  MemoryItem copyWith({
    String? id,
    String? text,
    MemoryKind? kind,
    bool? isPinned,
    bool? isApproved,
    DateTime? createdAt,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      text: text ?? this.text,
      kind: kind ?? this.kind,
      isPinned: isPinned ?? this.isPinned,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'kind': kind.name,
      'isPinned': isPinned,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String,
      text: json['text'] as String,
      kind: MemoryKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => MemoryKind.fact,
      ),
      isPinned: json['isPinned'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
