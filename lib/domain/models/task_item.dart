import 'dart:convert';
import '../../core/enums/task_priority.dart';
import '../../core/enums/core_enums.dart';
import 'subtask_item.dart';

class TaskItem {
  final String id;
  final String title;
  final String notes;
  final String category;
  final TaskPriority priority;
  final TaskStatus status;
  final RecurrenceType recurrence;
  final List<int> customDays; // 1 = Mon ... 7 = Sun
  final int estimatedMinutes;
  final DateTime? dueAt;
  final int? reminderMinutesBefore;
  final List<SubtaskItem> subtasks;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.category = 'General',
    this.priority = TaskPriority.importantNotUrgent,
    this.status = TaskStatus.pending,
    this.recurrence = RecurrenceType.none,
    this.customDays = const [],
    this.estimatedMinutes = 30,
    this.dueAt,
    this.reminderMinutesBefore,
    this.subtasks = const [],
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;

  double get subtaskProgress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final done = subtasks.where((s) => s.isCompleted).length;
    return done / subtasks.length;
  }

  bool get isOverdue {
    if (isCompleted || dueAt == null) return false;
    return DateTime.now().isAfter(dueAt!);
  }

  bool get isDueToday {
    if (dueAt == null) return false;
    final now = DateTime.now();
    return dueAt!.year == now.year &&
        dueAt!.month == now.month &&
        dueAt!.day == now.day;
  }

  /// Calculates dynamic priority score based on Eisenhower weight, proximity to deadline,
  /// and short-duration bias (shorter tasks can be knocked out quickly).
  double computeDynamicScore([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    double score = priority.baseScore.toDouble();

    if (dueAt != null) {
      final hoursUntilDue = dueAt!.difference(now).inMinutes / 60.0;
      if (hoursUntilDue < 0) {
        // Overdue tasks get highest escalation
        score += 80.0;
      } else if (hoursUntilDue <= 6) {
        score += 50.0;
      } else if (hoursUntilDue <= 24) {
        score += 30.0;
      } else if (hoursUntilDue <= 48) {
        score += 15.0;
      }
    }

    // Quick-win bonus for tasks under 25 minutes
    if (estimatedMinutes <= 25) {
      score += 10.0;
    }

    return score;
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? notes,
    String? category,
    TaskPriority? priority,
    TaskStatus? status,
    RecurrenceType? recurrence,
    List<int>? customDays,
    int? estimatedMinutes,
    DateTime? dueAt,
    int? reminderMinutesBefore,
    List<SubtaskItem>? subtasks,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      customDays: customDays ?? this.customDays,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dueAt: dueAt ?? this.dueAt,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'category': category,
        'priority': priority.index,
        'status': status.index,
        'recurrence': recurrence.index,
        'customDays': customDays,
        'estimatedMinutes': estimatedMinutes,
        'dueAt': dueAt?.toIso8601String(),
        'reminderMinutesBefore': reminderMinutesBefore,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        priority: TaskPriority.values[json['priority'] as int? ?? 1],
        status: TaskStatus.values[json['status'] as int? ?? 0],
        recurrence: RecurrenceType.values[json['recurrence'] as int? ?? 0],
        customDays: (json['customDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 30,
        dueAt: json['dueAt'] != null ? DateTime.parse(json['dueAt'] as String) : null,
        reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
        subtasks: (json['subtasks'] as List<dynamic>?)
                ?.map((e) => SubtaskItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  @override
  String toString() => 'TaskItem($title, $priority, $status, due: $dueAt)';
}

