enum ToolCallStatus {
  proposed,
  confirmed,
  executed,
  undone,
  rejected,
}

class ToolCallRecord {
  final String id;
  final String toolName;
  final Map<String, dynamic> arguments;
  final ToolCallStatus status;
  final bool isDestructive;
  final String? resultMessage;
  final String? undoDescription;
  final DateTime timestamp;

  const ToolCallRecord({
    required this.id,
    required this.toolName,
    required this.arguments,
    this.status = ToolCallStatus.proposed,
    this.isDestructive = false,
    this.resultMessage,
    this.undoDescription,
    required this.timestamp,
  });

  bool get canUndo => status == ToolCallStatus.executed && undoDescription != null;
  bool get needsConfirmation => isDestructive && status == ToolCallStatus.proposed;

  ToolCallRecord copyWith({
    String? id,
    String? toolName,
    Map<String, dynamic>? arguments,
    ToolCallStatus? status,
    bool? isDestructive,
    String? resultMessage,
    String? undoDescription,
    DateTime? timestamp,
  }) {
    return ToolCallRecord(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      arguments: arguments ?? this.arguments,
      status: status ?? this.status,
      isDestructive: isDestructive ?? this.isDestructive,
      resultMessage: resultMessage ?? this.resultMessage,
      undoDescription: undoDescription ?? this.undoDescription,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolName': toolName,
      'arguments': arguments,
      'status': status.name,
      'isDestructive': isDestructive,
      'resultMessage': resultMessage,
      'undoDescription': undoDescription,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ToolCallRecord.fromJson(Map<String, dynamic> json) {
    return ToolCallRecord(
      id: json['id'] as String,
      toolName: json['toolName'] as String,
      arguments: Map<String, dynamic>.from(json['arguments'] as Map),
      status: ToolCallStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ToolCallStatus.proposed,
      ),
      isDestructive: json['isDestructive'] as bool? ?? false,
      resultMessage: json['resultMessage'] as String?,
      undoDescription: json['undoDescription'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
