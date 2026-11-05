class DailyPlanBlock {
  final String id;
  final String title;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String? taskId;
  final String category;
  final bool isCompleted;

  const DailyPlanBlock({
    required this.id,
    required this.title,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.taskId,
    this.category = 'Focus',
    this.isCompleted = false,
  });

  int get durationMinutes {
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;
    return endTotal > startTotal ? endTotal - startTotal : 0;
  }

  String get timeRangeFormatted {
    final sPeriod = startHour >= 12 ? 'PM' : 'AM';
    final sH = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
    final sM = startMinute.toString().padLeft(2, '0');

    final ePeriod = endHour >= 12 ? 'PM' : 'AM';
    final eH = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);
    final eM = endMinute.toString().padLeft(2, '0');

    return '$sH:$sM $sPeriod - $eH:$eM $ePeriod';
  }

  DailyPlanBlock copyWith({
    String? id,
    String? title,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? taskId,
    String? category,
    bool? isCompleted,
  }) {
    return DailyPlanBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      taskId: taskId ?? this.taskId,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'taskId': taskId,
        'category': category,
        'isCompleted': isCompleted,
      };

  factory DailyPlanBlock.fromJson(Map<String, dynamic> json) => DailyPlanBlock(
        id: json['id'] as String,
        title: json['title'] as String,
        startHour: json['startHour'] as int,
        startMinute: json['startMinute'] as int,
        endHour: json['endHour'] as int,
        endMinute: json['endMinute'] as int,
        taskId: json['taskId'] as String?,
        category: json['category'] as String? ?? 'Focus',
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class RoutineStep {
  final String id;
  final String title;
  final int durationMinutes;
  final bool isCompleted;

  const RoutineStep({
    required this.id,
    required this.title,
    this.durationMinutes = 15,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'durationMinutes': durationMinutes,
        'isCompleted': isCompleted,
      };

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
        id: json['id'] as String,
        title: json['title'] as String,
        durationMinutes: json['durationMinutes'] as int? ?? 15,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class DayRoutine {
  final String id;
  final String name;
  final String iconName;
  final List<int> days; // 1=Mon ... 7=Sun
  final List<RoutineStep> steps;

  const DayRoutine({
    required this.id,
    required this.name,
    this.iconName = 'wb_sunny',
    this.days = const [1, 2, 3, 4, 5],
    this.steps = const [],
  });

  int get totalMinutes => steps.fold(0, (acc, s) => acc + s.durationMinutes);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'days': days,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory DayRoutine.fromJson(Map<String, dynamic> json) => DayRoutine(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String? ?? 'wb_sunny',
        days: (json['days'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

