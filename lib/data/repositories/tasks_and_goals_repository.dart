import '../../domain/models/task_item.dart';
import '../../domain/models/goal_item.dart';
import '../../core/enums/core_enums.dart';
import '../../core/enums/task_priority.dart';
import '../../domain/services/planner_algorithm.dart';

class TaskUndoState {
  final String action; // 'delete', 'complete', 'bulk'
  final List<TaskItem> tasks;

  const TaskUndoState({required this.action, required this.tasks});
}

class TasksAndGoalsRepository {
  final Map<String, TaskItem> _tasks = {};
  final Map<String, GoalItem> _goals = {};
  final List<TaskUndoState> _undoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;

  // --- TASK CRUD ---
  void addTask(TaskItem task) {
    _tasks[task.id] = task;
  }

  void updateTask(TaskItem task) {
    _tasks[task.id] = task;
  }

  bool deleteTask(String id) {
    final t = _tasks.remove(id);
    if (t != null) {
      _undoStack.add(TaskUndoState(action: 'delete', tasks: [t]));
      return true;
    }
    return false;
  }

  /// Toggles task completion with dependency checking and recurring auto-advance.
  bool toggleTask(String id) {
    final task = _tasks[id];
    if (task == null) return false;

    // Check if blocked
    if (!task.isCompleted && !canCompleteTask(id)) {
      return false; // Cannot complete a blocked task!
    }

    final newStatus = task.isCompleted ? TaskStatus.pending : TaskStatus.completed;
    final updated = task.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
    );
    _tasks[id] = updated;

    // Handle recurrence auto-generation
    if (newStatus == TaskStatus.completed && task.recurrence != RecurrenceType.none) {
      final nextDue = task.computeNextDueDate();
      if (nextDue != null) {
        final recurringNext = task.copyWith(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          status: TaskStatus.pending,
          dueAt: nextDue,
          createdAt: DateTime.now(),
          completedAt: null,
        );
        _tasks[recurringNext.id] = recurringNext;
      }
    }

    _undoStack.add(TaskUndoState(action: 'complete', tasks: [task]));
    return true;
  }

  // --- DEPENDENCY CHECKING ---
  bool canCompleteTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null) return true;
    if (task.blockedByTaskIds.isEmpty) return true;

    // Every blocker must be completed
    for (final blockerId in task.blockedByTaskIds) {
      final blocker = _tasks[blockerId];
      if (blocker != null && !blocker.isCompleted) {
        return false;
      }
    }
    return true;
  }

  List<String> getBlockerTitles(TaskItem task) {
    final titles = <String>[];
    for (final blockerId in task.blockedByTaskIds) {
      final blocker = _tasks[blockerId];
      if (blocker != null && !blocker.isCompleted) {
        titles.add(blocker.title);
      }
    }
    return titles;
  }

  // --- UNDO ---
  List<TaskItem>? undo() {
    if (_undoStack.isEmpty) return null;
    final state = _undoStack.removeLast();

    for (final task in state.tasks) {
      _tasks[task.id] = task;
    }
    return state.tasks;
  }

  // --- BULK OPERATIONS ---
  void bulkComplete(List<String> taskIds) {
    final snapshot = <TaskItem>[];
    for (final id in taskIds) {
      final t = _tasks[id];
      if (t != null && canCompleteTask(id)) {
        snapshot.add(t);
        _tasks[id] = t.copyWith(status: TaskStatus.completed, completedAt: DateTime.now());
      }
    }
    if (snapshot.isNotEmpty) {
      _undoStack.add(TaskUndoState(action: 'bulk', tasks: snapshot));
    }
  }

  void bulkDelete(List<String> taskIds) {
    final snapshot = <TaskItem>[];
    for (final id in taskIds) {
      final t = _tasks.remove(id);
      if (t != null) snapshot.add(t);
    }
    if (snapshot.isNotEmpty) {
      _undoStack.add(TaskUndoState(action: 'delete', tasks: snapshot));
    }
  }

  // --- FILTERED VIEWS ---
  List<TaskItem> getAllTasks() => _tasks.values.toList();

  List<TaskItem> getTodayTasks() {
    return _tasks.values.where((t) {
      if (t.isCompleted) return false;
      if (t.dueAt == null) return true; // Undated tasks show in Today unless inboxed
      return t.isDueToday || t.isOverdue;
    }).toList()
      ..sort((a, b) => b.computeDynamicScore().compareTo(a.computeDynamicScore()));
  }

  List<TaskItem> getUpcomingTasks() {
    final now = DateTime.now();
    return _tasks.values.where((t) {
      if (t.isCompleted || t.dueAt == null) return false;
      return t.dueAt!.isAfter(DateTime(now.year, now.month, now.day, 23, 59));
    }).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
  }

  List<TaskItem> getInboxTasks() {
    return _tasks.values.where((t) => !t.isCompleted && t.category == 'Inbox').toList();
  }

  List<TaskItem> getCompletedTasks() {
    return _tasks.values.where((t) => t.isCompleted).toList()
      ..sort((a, b) => (b.completedAt ?? DateTime.now()).compareTo(a.completedAt ?? DateTime.now()));
  }

  List<TaskItem> getCalendarTasks(DateTime date) {
    return _tasks.values.where((t) {
      if (t.dueAt == null) return false;
      return t.dueAt!.year == date.year && t.dueAt!.month == date.month && t.dueAt!.day == date.day;
    }).toList();
  }

  TaskItem? getDailyFrogTask() {
    return PlannerAlgorithm.pickEatTheFrog(getTodayTasks());
  }

  // --- GOALS & MILESTONES ---
  void addGoal(GoalItem goal) {
    _goals[goal.id] = goal;
  }

  List<GoalItem> getGoals() => _goals.values.toList();

  void toggleMilestone(String goalId, String milestoneId) {
    final goal = _goals[goalId];
    if (goal == null) return;

    final updatedMilestones = goal.milestones.map((m) {
      if (m.id == milestoneId) {
        return m.copyWith(isCompleted: !m.isCompleted);
      }
      return m;
    }).toList();

    _goals[goalId] = goal.copyWith(milestones: updatedMilestones);
  }

  // --- SEED REALISTIC WEEK DATA ---
  void seedRealisticWeek() {
    final now = DateTime.now();

    // 1. Blocker task
    final blocker = TaskItem(
      id: 'task_blocker_spec',
      title: 'Finalize Mobile Architecture & Database Schema',
      category: 'Work',
      priority: TaskPriority.urgentImportant,
      estimatedMinutes: 60,
      dueAt: DateTime(now.year, now.month, now.day, 12, 0),
      createdAt: now.subtract(const Duration(days: 2)),
    );
    addTask(blocker);

    // 2. Blocked task (Dependent on task_blocker_spec)
    final dependent = TaskItem(
      id: 'task_dep_impl',
      title: 'Implement Native Kotlin Alarm BroadcastReceiver',
      category: 'Work',
      priority: TaskPriority.urgentImportant,
      estimatedMinutes: 90,
      dueAt: DateTime(now.year, now.month, now.day, 17, 0),
      blockedByTaskIds: ['task_blocker_spec'],
      createdAt: now.subtract(const Duration(days: 1)),
    );
    addTask(dependent);

    // 3. "Eat the Frog" candidate: High friction, urgent
    final frog = TaskItem(
      id: 'task_frog_hardest',
      title: 'Conduct End-to-End Background Battery Quota Audit',
      category: 'Work',
      priority: TaskPriority.urgentImportant,
      estimatedMinutes: 120,
      isFrog: true,
      dueAt: DateTime(now.year, now.month, now.day, 18, 0),
      createdAt: now,
    );
    addTask(frog);

    // 4. Recurring daily task
    final recurring = TaskItem(
      id: 'task_daily_rec',
      title: 'Morning 20-min Bangla / English Reflection',
      category: 'Personal',
      priority: TaskPriority.importantNotUrgent,
      recurrence: RecurrenceType.daily,
      estimatedMinutes: 20,
      dueAt: DateTime(now.year, now.month, now.day, 8, 30),
      createdAt: now.subtract(const Duration(days: 3)),
    );
    addTask(recurring);

    // 5. Goals with milestones
    final goal = GoalItem(
      id: 'goal_cv_launch',
      title: 'Ship Portfolio-Grade DayBook App to Google Play',
      description: 'Zero crashes, full offline reliability, complete Bangla/English parity.',
      category: 'Career',
      targetDate: now.add(const Duration(days: 30)),
      createdAt: now.subtract(const Duration(days: 7)),
      milestones: const [
        MilestoneItem(id: 'ms_1', goalId: 'goal_cv_launch', title: 'Complete MVP Parts 0-6', isCompleted: true),
        MilestoneItem(id: 'ms_2', goalId: 'goal_cv_launch', title: 'Implement Core Parts 7-8', isCompleted: false),
        MilestoneItem(id: 'ms_3', goalId: 'goal_cv_launch', title: 'Security & Release Hardening Parts 12-13', isCompleted: false),
      ],
    );
    addGoal(goal);
  }
}
