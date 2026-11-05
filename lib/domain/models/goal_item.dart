class MilestoneItem {
  final String id;
  final String goalId;
  final String title;
  final DateTime? targetDate;
  final bool isCompleted;

  const MilestoneItem({
    required this.id,
    required this.goalId,
    required this.title,
    this.targetDate,
    this.isCompleted = false,
  });

  MilestoneItem copyWith({
    String? id,
    String? goalId,
    String? title,
    DateTime? targetDate,
    bool? isCompleted,
  }) {
    return MilestoneItem(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'title': title,
      'target_date': targetDate?.toIso8601String(),
      'is_completed': isCompleted,
    };
  }

  factory MilestoneItem.fromJson(Map<String, dynamic> json) {
    return MilestoneItem(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      title: json['title'] as String,
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,
      isCompleted: json['is_completed'] == true,
    );
  }
}

class GoalItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime targetDate;
  final List<MilestoneItem> milestones;
  final List<String> taskIds;
  final DateTime createdAt;

  const GoalItem({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Growth',
    required this.targetDate,
    this.milestones = const [],
    this.taskIds = const [],
    required this.createdAt,
  });

  double get progressPercentage {
    if (milestones.isEmpty) return 0.0;
    final done = milestones.where((m) => m.isCompleted).length;
    return (done / milestones.length).clamp(0.0, 1.0);
  }

  bool get isAchieved => milestones.isNotEmpty && milestones.every((m) => m.isCompleted);

  int get daysRemaining {
    final diff = targetDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  GoalItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? targetDate,
    List<MilestoneItem>? milestones,
    List<String>? taskIds,
    DateTime? createdAt,
  }) {
    return GoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      milestones: milestones ?? this.milestones,
      taskIds: taskIds ?? this.taskIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'target_date': targetDate.toIso8601String(),
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'task_ids': taskIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Growth',
      targetDate: DateTime.parse(json['target_date'] as String),
      milestones: (json['milestones'] as List<dynamic>? ?? [])
          .map((m) => MilestoneItem.fromJson(m as Map<String, dynamic>))
          .toList(),
      taskIds: (json['task_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
