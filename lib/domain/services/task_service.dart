import '../models/task_item.dart';
import '../models/subtask_item.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/core_enums.dart';

class TaskService {
  List<TaskItem> _tasks = [];

  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  void loadTasks(List<TaskItem> initialTasks) {
    _tasks = List.from(initialTasks);
  }

  /// Returns tasks due today or overdue, sorted by dynamic priority score descending.
  List<TaskItem> getTodayTasks([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    return _tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueAt == null) return true; // Undated tasks appear in daily queue
      return t.isDueToday || t.dueAt!.isBefore(now);
    }).toList()
      ..sort((a, b) => b.computeDynamicScore(now).compareTo(a.computeDynamicScore(now)));
  }

  /// Returns upcoming tasks (due after today).
  List<TaskItem> getUpcomingTasks([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _tasks.where((t) {
      if (t.isCompleted || t.dueAt == null) return false;
      return t.dueAt!.isAfter(todayEnd);
    }).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
  }

  /// Returns all completed tasks, newest first.
  List<TaskItem> getCompletedTasks() {
    return _tasks.where((t) => t.isCompleted).toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
  }

  /// Filter by category and search query.
  List<TaskItem> filterTasks({String? category, String? query}) {
    return _tasks.where((t) {
      final matchesCategory = category == null ||
          category.isEmpty ||
          category == 'All' ||
          t.category.toLowerCase() == category.toLowerCase();
      final matchesQuery = query == null ||
          query.isEmpty ||
          t.title.toLowerCase().contains(query.toLowerCase()) ||
          t.notes.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Adds a new task directly.
  void insertTask(TaskItem task) {
    _tasks.add(task);
  }

  /// Adds a new task.
  TaskItem addTask({
    required String title,
    String notes = '',
    String category = 'General',
    TaskPriority priority = TaskPriority.importantNotUrgent,
    RecurrenceType recurrence = RecurrenceType.none,
    List<int> customDays = const [],
    int estimatedMinutes = 30,
    DateTime? dueAt,
    int? reminderMinutesBefore,
    List<SubtaskItem> subtasks = const [],
  }) {
    final newTask = TaskItem(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      notes: notes,
      category: category,
      priority: priority,
      recurrence: recurrence,
      customDays: customDays,
      estimatedMinutes: estimatedMinutes,
      dueAt: dueAt,
      reminderMinutesBefore: reminderMinutesBefore,
      subtasks: subtasks,
      createdAt: DateTime.now(),
    );
    _tasks.add(newTask);
    return newTask;
  }

  /// Toggles task completion. If recurring, automatically spawns next occurrence.
  TaskItem? toggleTaskCompletion(String taskId, [DateTime? completionTime]) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return null;

    final current = _tasks[index];
    final now = completionTime ?? DateTime.now();

    if (!current.isCompleted) {
      // Mark current as completed
      final completed = current.copyWith(
        status: TaskStatus.completed,
        completedAt: now,
        subtasks: current.subtasks.map((s) => s.copyWith(isCompleted: true)).toList(),
      );
      _tasks[index] = completed;

      // Handle recurrence
      if (current.recurrence.isRepeating) {
        _spawnNextOccurrence(current, now);
      }
      return completed;
    } else {
      // Revert to pending
      final pending = current.copyWith(
        status: TaskStatus.pending,
        completedAt: null,
      );
      _tasks[index] = pending;
      return pending;
    }
  }

  /// Toggles an individual subtask. If all subtasks are finished, auto-completes parent task.
  TaskItem? toggleSubtask(String taskId, String subtaskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return null;

    final current = _tasks[index];
    final updatedSubtasks = current.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    final allDone = updatedSubtasks.isNotEmpty &&
        updatedSubtasks.every((s) => s.isCompleted);

    final updated = current.copyWith(
      subtasks: updatedSubtasks,
      status: allDone ? TaskStatus.completed : TaskStatus.inProgress,
      completedAt: allDone ? DateTime.now() : null,
    );

    _tasks[index] = updated;
    return updated;
  }

  /// Deletes task.
  bool deleteTask(String taskId) {
    final initialLen = _tasks.length;
    _tasks.removeWhere((t) => t.id == taskId);
    return _tasks.length < initialLen;
  }

  /// Spawns next recurring task iteration.
  void _spawnNextOccurrence(TaskItem template, DateTime completedAt) {
    DateTime nextDue;
    final baseDate = template.dueAt ?? completedAt;

    switch (template.recurrence) {
      case RecurrenceType.daily:
        nextDue = baseDate.add(const Duration(days: 1));
        break;
      case RecurrenceType.weekdays:
        int daysToAdd = 1;
        while (baseDate.add(Duration(days: daysToAdd)).weekday > 5) {
          daysToAdd++;
        }
        nextDue = baseDate.add(Duration(days: daysToAdd));
        break;
      case RecurrenceType.weekly:
        nextDue = baseDate.add(const Duration(days: 7));
        break;
      case RecurrenceType.monthly:
        nextDue = DateTime(baseDate.year, baseDate.month + 1, baseDate.day, baseDate.hour, baseDate.minute);
        break;
      case RecurrenceType.afterCompletion:
        nextDue = completedAt.add(const Duration(days: 1));
        break;
      case RecurrenceType.customDays:
        if (template.customDays.isEmpty) {
          nextDue = baseDate.add(const Duration(days: 1));
        } else {
          int daysToAdd = 1;
          while (!template.customDays.contains(baseDate.add(Duration(days: daysToAdd)).weekday)) {
            daysToAdd++;
            if (daysToAdd > 14) break; // guard
          }
          nextDue = baseDate.add(Duration(days: daysToAdd));
        }
        break;
      case RecurrenceType.none:
        return;
    }

    final nextTask = TaskItem(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: template.title,
      notes: template.notes,
      category: template.category,
      priority: template.priority,
      recurrence: template.recurrence,
      customDays: template.customDays,
      estimatedMinutes: template.estimatedMinutes,
      dueAt: nextDue,
      reminderMinutesBefore: template.reminderMinutesBefore,
      subtasks: template.subtasks.map((s) => s.copyWith(isCompleted: false)).toList(),
      createdAt: completedAt,
    );

    _tasks.add(nextTask);
  }
}

