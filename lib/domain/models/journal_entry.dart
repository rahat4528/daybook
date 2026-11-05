import 'dart:convert';
import 'package:intl/intl.dart';

enum EntryType {
  alarmDismissed('alarm_dismissed'),
  taskCompleted('task_completed'),
  habitLogged('habit_logged'),
  focusSession('focus_session'),
  stepMilestone('step_milestone'),
  weatherChange('weather_change'),
  expenseLogged('expense_logged'),
  manualNote('manual_note'),
  moodEnergyCheckin('mood_energy_checkin'),
  momentPinned('moment_pinned');

  final String value;
  const EntryType(this.value);

  static EntryType fromString(String val) {
    return EntryType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => EntryType.manualNote,
    );
  }

  String label({bool isBangla = false}) {
    switch (this) {
      case EntryType.alarmDismissed:
        return isBangla ? 'অ্যালার্ম বন্ধ' : 'Alarm Dismissed';
      case EntryType.taskCompleted:
        return isBangla ? 'কাজ সম্পন্ন' : 'Task Done';
      case EntryType.habitLogged:
        return isBangla ? 'অভ্যাস পূরণ' : 'Habit Logged';
      case EntryType.focusSession:
        return isBangla ? 'ফোকাস সেশন' : 'Focus Session';
      case EntryType.stepMilestone:
        return isBangla ? 'হাঁটার ধাপ' : 'Step Milestone';
      case EntryType.weatherChange:
        return isBangla ? 'আবহাওয়া' : 'Weather';
      case EntryType.expenseLogged:
        return isBangla ? 'খরচ' : 'Expense';
      case EntryType.manualNote:
        return isBangla ? 'নোট' : 'Note';
      case EntryType.moodEnergyCheckin:
        return isBangla ? 'মুড ও শক্তি' : 'Mood & Energy';
      case EntryType.momentPinned:
        return isBangla ? 'পিন করা মুহূর্ত' : 'Pinned Moment';
    }
  }
}

class JournalEntry {
  final String id;
  final EntryType type;
  final DateTime ts;
  final Map<String, dynamic> payload;
  final int? mood; // 1-5
  final int? energy; // 1-5
  final String? skyCode;
  final String source;
  final String dayKey; // YYYY-MM-DD
  final bool isPinned;
  final bool starred;
  final String? voiceNotePath;
  final String? photoAttachmentPath;

  const JournalEntry({
    required this.id,
    required this.type,
    required this.ts,
    this.payload = const {},
    this.mood,
    this.energy,
    this.skyCode,
    this.source = 'user',
    required this.dayKey,
    this.isPinned = false,
    this.starred = false,
    this.voiceNotePath,
    this.photoAttachmentPath,
  });

  String get timeFormatted => DateFormat('HH:mm').format(ts);

  String displayText({bool isBangla = false}) {
    final title = payload['title'] as String?;
    final note = payload['note'] as String?;
    final desc = payload['description'] as String?;

    if (title != null && title.isNotEmpty) return title;
    if (note != null && note.isNotEmpty) return note;
    if (desc != null && desc.isNotEmpty) return desc;

    switch (type) {
      case EntryType.alarmDismissed:
        final chal = payload['challenge'] ?? 'Wake Quest';
        return isBangla ? 'চ্যালেঞ্জ সম্পন্ন: $chal' : 'Wake Quest cleared: $chal';
      case EntryType.taskCompleted:
        final t = payload['task_name'] ?? (isBangla ? 'অজ্ঞাত কাজ' : 'Task');
        return isBangla ? 'সম্পন্ন: $t' : 'Completed: $t';
      case EntryType.habitLogged:
        final h = payload['habit_name'] ?? (isBangla ? 'দৈনিক অভ্যাস' : 'Habit');
        return isBangla ? 'অভ্যাস পূর্ণ: $h' : 'Completed: $h';
      case EntryType.focusSession:
        final mins = payload['minutes'] ?? 25;
        return isBangla ? '$mins মিনিট গভীর ফোকাস' : '$mins mins deep focus';
      case EntryType.stepMilestone:
        final steps = payload['steps'] ?? 5000;
        return isBangla ? '$steps কদম হাঁটা সম্পন্ন' : '$steps steps logged';
      case EntryType.weatherChange:
        final cond = payload['condition'] ?? 'Clear';
        final temp = payload['temp'] ?? 28;
        return isBangla ? '$cond, $temp°সে' : '$cond, $temp°C';
      case EntryType.expenseLogged:
        final amt = payload['amount'] ?? 0;
        final cat = payload['category'] ?? 'General';
        return isBangla ? '৳$amt খরচ ($cat)' : '\$$amt spent ($cat)';
      case EntryType.moodEnergyCheckin:
        return isBangla ? 'মুড $mood/5, শক্তি $energy/5' : 'Mood $mood/5, Energy $energy/5';
      case EntryType.momentPinned:
        return payload['text'] ?? (isBangla ? 'বিশেষ মুহূর্ত' : 'Special Moment');
      case EntryType.manualNote:
        return payload['text'] ?? (isBangla ? 'নোট' : 'Note');
    }
  }

  JournalEntry copyWith({
    String? id,
    EntryType? type,
    DateTime? ts,
    Map<String, dynamic>? payload,
    int? mood,
    int? energy,
    String? skyCode,
    String? source,
    String? dayKey,
    bool? isPinned,
    bool? starred,
    String? voiceNotePath,
    String? photoAttachmentPath,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      ts: ts ?? this.ts,
      payload: payload ?? this.payload,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      skyCode: skyCode ?? this.skyCode,
      source: source ?? this.source,
      dayKey: dayKey ?? this.dayKey,
      isPinned: isPinned ?? this.isPinned,
      starred: starred ?? this.starred,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      photoAttachmentPath: photoAttachmentPath ?? this.photoAttachmentPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'ts': ts.toIso8601String(),
      'payload_json': jsonEncode(payload),
      'mood': mood,
      'energy': energy,
      'sky_code': skyCode,
      'source': source,
      'day_key': dayKey,
      'is_pinned': isPinned,
      'starred': starred,
      'voice_note_path': voiceNotePath,
      'photo_attachment_path': photoAttachmentPath,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedPayload = {};
    if (json['payload_json'] != null) {
      if (json['payload_json'] is Map) {
        parsedPayload = Map<String, dynamic>.from(json['payload_json']);
      } else if (json['payload_json'] is String) {
        try {
          parsedPayload = jsonDecode(json['payload_json']);
        } catch (_) {
          parsedPayload = {'raw': json['payload_json']};
        }
      }
    }

    return JournalEntry(
      id: json['id'] as String,
      type: EntryType.fromString(json['type'] as String? ?? 'manual_note'),
      ts: DateTime.parse(json['ts'] as String),
      payload: parsedPayload,
      mood: json['mood'] as int?,
      energy: json['energy'] as int?,
      skyCode: json['sky_code'] as String?,
      source: json['source'] as String? ?? 'user',
      dayKey: json['day_key'] as String,
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      starred: json['starred'] == true || json['starred'] == 1,
      voiceNotePath: json['voice_note_path'] as String?,
      photoAttachmentPath: json['photo_attachment_path'] as String?,
    );
  }
}
