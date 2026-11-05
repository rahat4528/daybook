import 'package:flutter/foundation.dart';
import '../../core/enums/task_priority.dart';

enum CaptureSource {
  typed,
  voice,
  shareIntent,
  quickTile,
  commandPalette,
}

enum ParsedIntentType {
  task,
  expense,
  note,
  habit,
  mood,
  alarm,
}

extension ParsedIntentTypeExtension on ParsedIntentType {
  String get labelEn {
    switch (this) {
      case ParsedIntentType.task:
        return 'Task';
      case ParsedIntentType.expense:
        return 'Expense';
      case ParsedIntentType.note:
        return 'Note';
      case ParsedIntentType.habit:
        return 'Habit';
      case ParsedIntentType.mood:
        return 'Mood';
      case ParsedIntentType.alarm:
        return 'Alarm';
    }
  }

  String get labelBn {
    switch (this) {
      case ParsedIntentType.task:
        return 'কাজ';
      case ParsedIntentType.expense:
        return 'খরচ';
      case ParsedIntentType.note:
        return 'নোট';
      case ParsedIntentType.habit:
        return 'অভ্যাস';
      case ParsedIntentType.mood:
        return 'মেজাজ';
      case ParsedIntentType.alarm:
        return 'অ্যালার্ম';
    }
  }

  String get glyph {
    switch (this) {
      case ParsedIntentType.task:
        return '✓';
      case ParsedIntentType.expense:
        return '৳';
      case ParsedIntentType.note:
        return '✎';
      case ParsedIntentType.habit:
        return '⚡';
      case ParsedIntentType.mood:
        return '☯';
      case ParsedIntentType.alarm:
        return '⏰';
    }
  }
}

/// Represents the extracted structured parameters from typed or voiced text.
@immutable
class ParsedCaptureIntent {
  final ParsedIntentType intentType;
  final String title;
  final DateTime? dueDate;
  final double? amount;
  final String? category;
  final TaskPriority priority;
  final int? estimateMinutes;
  final double confidence; // 0.0 to 1.0
  final String rawInput;
  final List<String> tags;

  const ParsedCaptureIntent({
    required this.intentType,
    required this.title,
    this.dueDate,
    this.amount,
    this.category,
    this.priority = TaskPriority.p3,
    this.estimateMinutes,
    this.confidence = 0.85,
    required this.rawInput,
    this.tags = const [],
  });

  ParsedCaptureIntent copyWith({
    ParsedIntentType? intentType,
    String? title,
    DateTime? dueDate,
    double? amount,
    String? category,
    TaskPriority? priority,
    int? estimateMinutes,
    double? confidence,
    String? rawInput,
    List<String>? tags,
  }) {
    return ParsedCaptureIntent(
      intentType: intentType ?? this.intentType,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      confidence: confidence ?? this.confidence,
      rawInput: rawInput ?? this.rawInput,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'intentType': intentType.name,
        'title': title,
        'dueDate': dueDate?.toIso8601String(),
        'amount': amount,
        'category': category,
        'priority': priority.name,
        'estimateMinutes': estimateMinutes,
        'confidence': confidence,
        'rawInput': rawInput,
        'tags': tags,
      };

  factory ParsedCaptureIntent.fromJson(Map<String, dynamic> json) {
    return ParsedCaptureIntent(
      intentType: ParsedIntentType.values.firstWhere(
        (e) => e.name == json['intentType'],
        orElse: () => ParsedIntentType.task,
      ),
      title: json['title'] as String? ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      amount: (json['amount'] as num?)?.toDouble(),
      category: json['category'] as String?,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.p3,
      ),
      estimateMinutes: json['estimateMinutes'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      rawInput: json['rawInput'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

/// A raw capture item waiting in the Inbox or triaged into another domain entity.
@immutable
class CaptureItem {
  final String id;
  final String rawText;
  final CaptureSource source;
  final String? processedIntoType; // 'task', 'expense', 'note', 'archived', null
  final String? processedId;
  final DateTime createdAt;
  final String? attachmentUri;
  final Map<String, dynamic> metadata;

  const CaptureItem({
    required this.id,
    required this.rawText,
    required this.source,
    this.processedIntoType,
    this.processedId,
    required this.createdAt,
    this.attachmentUri,
    this.metadata = const {},
  });

  bool get isProcessed => processedIntoType != null;

  CaptureItem copyWith({
    String? id,
    String? rawText,
    CaptureSource? source,
    String? processedIntoType,
    String? processedId,
    DateTime? createdAt,
    String? attachmentUri,
    Map<String, dynamic>? metadata,
  }) {
    return CaptureItem(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      source: source ?? this.source,
      processedIntoType: processedIntoType ?? this.processedIntoType,
      processedId: processedId ?? this.processedId,
      createdAt: createdAt ?? this.createdAt,
      attachmentUri: attachmentUri ?? this.attachmentUri,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawText': rawText,
        'source': source.name,
        'processedIntoType': processedIntoType,
        'processedId': processedId,
        'createdAt': createdAt.toIso8601String(),
        'attachmentUri': attachmentUri,
        'metadata': metadata,
      };

  factory CaptureItem.fromJson(Map<String, dynamic> json) {
    return CaptureItem(
      id: json['id'] as String,
      rawText: json['rawText'] as String,
      source: CaptureSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => CaptureSource.typed,
      ),
      processedIntoType: json['processedIntoType'] as String?,
      processedId: json['processedId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachmentUri: json['attachmentUri'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }
}
