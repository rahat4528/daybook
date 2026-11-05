import 'package:flutter/foundation.dart';

enum NoteType {
  plain,
  checklist,
  voiceNote,
  photo,
  link,
}

extension NoteTypeExtension on NoteType {
  String get labelEn {
    switch (this) {
      case NoteType.plain:
        return 'Note';
      case NoteType.checklist:
        return 'Checklist';
      case NoteType.voiceNote:
        return 'Voice Clip';
      case NoteType.photo:
        return 'Photo';
      case NoteType.link:
        return 'Saved Link';
    }
  }

  String get labelBn {
    switch (this) {
      case NoteType.plain:
        return 'নোট';
      case NoteType.checklist:
        return 'চেকলিস্ট';
      case NoteType.voiceNote:
        return 'ভয়েস ক্লিপ';
      case NoteType.photo:
        return 'ছবি';
      case NoteType.link:
        return 'সংরক্ষিত লিংক';
    }
  }

  String get glyph {
    switch (this) {
      case NoteType.plain:
        return '✎';
      case NoteType.checklist:
        return '☑';
      case NoteType.voiceNote:
        return '🎙';
      case NoteType.photo:
        return '📷';
      case NoteType.link:
        return '🔗';
    }
  }
}

@immutable
class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isCompleted': isCompleted,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

@immutable
class RichNote {
  final String id;
  final String title;
  final String body;
  final NoteType type;
  final List<ChecklistItem> checklistItems;
  final String? attachmentUri;
  final int? audioDurationSeconds;
  final String? linkUrl;
  final String? linkPreviewTitle;
  final String dayKey;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RichNote({
    required this.id,
    required this.title,
    required this.body,
    this.type = NoteType.plain,
    this.checklistItems = const [],
    this.attachmentUri,
    this.audioDurationSeconds,
    this.linkUrl,
    this.linkPreviewTitle,
    required this.dayKey,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  RichNote copyWith({
    String? id,
    String? title,
    String? body,
    NoteType? type,
    List<ChecklistItem>? checklistItems,
    String? attachmentUri,
    int? audioDurationSeconds,
    String? linkUrl,
    String? linkPreviewTitle,
    String? dayKey,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RichNote(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      checklistItems: checklistItems ?? this.checklistItems,
      attachmentUri: attachmentUri ?? this.attachmentUri,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      linkUrl: linkUrl ?? this.linkUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      dayKey: dayKey ?? this.dayKey,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'checklistItems': checklistItems.map((e) => e.toJson()).toList(),
        'attachmentUri': attachmentUri,
        'audioDurationSeconds': audioDurationSeconds,
        'linkUrl': linkUrl,
        'linkPreviewTitle': linkPreviewTitle,
        'dayKey': dayKey,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RichNote.fromJson(Map<String, dynamic> json) {
    return RichNote(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: NoteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NoteType.plain,
      ),
      checklistItems: (json['checklistItems'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      attachmentUri: json['attachmentUri'] as String?,
      audioDurationSeconds: json['audioDurationSeconds'] as int?,
      linkUrl: json['linkUrl'] as String?,
      linkPreviewTitle: json['linkPreviewTitle'] as String?,
      dayKey: json['dayKey'] as String,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
