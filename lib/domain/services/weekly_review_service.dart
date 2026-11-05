import '../models/task_item.dart';
import '../../core/enums/core_enums.dart';

class WeeklyReviewReport {
  final int completedTasksCount;
  final int pendingTasksCount;
  final double completionRate;
  final List<TaskItem> carryOverTasks;
  final List<TaskItem> archivedTasks;

  const WeeklyReviewReport({
    required this.completedTasksCount,
    required this.pendingTasksCount,
    required this.completionRate,
    required this.carryOverTasks,
    required this.archivedTasks,
  });
}

class WeeklyReviewService {
  /// Evaluates past week's task momentum, separates completed from uncompleted tasks,
  /// and prepares the carry-over batch for next week.
  static WeeklyReviewReport generateWeeklyReview(List<TaskItem> allTasks) {
    final completed = allTasks.where((t) => t.isCompleted).toList();
    final pending = allTasks.where((t) => !t.isCompleted).toList();

    final total = allTasks.length;
    final rate = total > 0 ? (completed.length / total) : 0.0;

    // Rollover tasks for next week: pending tasks with due dates updated or reset
    final carryOver = pending.map((t) {
      return t.copyWith(
        status: TaskStatus.pending,
      );
    }).toList();

    return WeeklyReviewReport(
      completedTasksCount: completed.length,
      pendingTasksCount: pending.length,
      completionRate: rate,
      carryOverTasks: carryOver,
      archivedTasks: completed,
    );
  }

  /// Carries over incomplete tasks into the following week
  static List<TaskItem> rolloverIncompleteTasks(List<TaskItem> tasks, {int daysAhead = 7}) {
    return tasks.map((task) {
      if (task.isCompleted) return task;
      final newDue = task.dueAt != null
          ? task.dueAt!.add(Duration(days: daysAhead))
          : DateTime.now().add(Duration(days: daysAhead));
      return task.copyWith(dueAt: newDue);
    }).toList();
  }
}
