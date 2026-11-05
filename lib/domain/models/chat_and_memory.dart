import '../../core/enums/core_enums.dart';

class PersonalMemory {
  final String id;
  final String key;
  final String value;
  final MemoryKind kind;
  final bool isPinned;
  final DateTime createdAt;

  const PersonalMemory({
    required this.id,
    required this.key,
    required this.value,
    this.kind = MemoryKind.fact,
    this.isPinned = false,
    required this.createdAt,
  });

  PersonalMemory copyWith({
    String? id,
    String? key,
    String? value,
    MemoryKind? kind,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return PersonalMemory(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      kind: kind ?? this.kind,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'value': value,
        'kind': kind.index,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PersonalMemory.fromJson(Map<String, dynamic> json) => PersonalMemory(
        id: json['id'] as String,
        key: json['key'] as String,
        value: json['value'] as String,
        kind: MemoryKind.values[json['kind'] as int? ?? 0],
        isPinned: json['isPinned'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AssistantToolInvocation {
  final String toolName;
  final Map<String, dynamic> parameters;
  final String resultSummary;
  final bool isExecuted;

  const AssistantToolInvocation({
    required this.toolName,
    required this.parameters,
    this.resultSummary = '',
    this.isExecuted = false,
  });

  Map<String, dynamic> toJson() => {
        'toolName': toolName,
        'parameters': parameters,
        'resultSummary': resultSummary,
        'isExecuted': isExecuted,
      };

  factory AssistantToolInvocation.fromJson(Map<String, dynamic> json) =>
      AssistantToolInvocation(
        toolName: json['toolName'] as String,
        parameters: json['parameters'] as Map<String, dynamic>? ?? {},
        resultSummary: json['resultSummary'] as String? ?? '',
        isExecuted: json['isExecuted'] as bool? ?? false,
      );
}

enum MessageSender { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final AssistantToolInvocation? toolInvocation;
  final String? toolRecordId;
  final String? targetDayKey;
  final String? undoDescription;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.toolInvocation,
    this.toolRecordId,
    this.targetDayKey,
    this.undoDescription,
  });

  bool get isUser => sender == MessageSender.user;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender.index,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'toolInvocation': toolInvocation?.toJson(),
        'toolRecordId': toolRecordId,
        'targetDayKey': targetDayKey,
        'undoDescription': undoDescription,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        sender: MessageSender.values[json['sender'] as int? ?? 0],
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        toolInvocation: json['toolInvocation'] != null
            ? AssistantToolInvocation.fromJson(
                json['toolInvocation'] as Map<String, dynamic>)
            : null,
        toolRecordId: json['toolRecordId'] as String?,
        targetDayKey: json['targetDayKey'] as String?,
        undoDescription: json['undoDescription'] as String?,
      );
}

