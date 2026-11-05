import '../models/daily_plan_block.dart';
import '../models/task_item.dart';
import '../../core/enums/task_priority.dart';

class PlannerResult {
  final List<DailyPlanBlock> blocks;
  final bool isOverloaded;
  final int deficitMinutes;
  final TaskItem? frogTask;
  final int totalPlannedMinutes;
  final int availableWorkMinutes;

  const PlannerResult({
    required this.blocks,
    this.isOverloaded = false,
    this.deficitMinutes = 0,
    this.frogTask,
    this.totalPlannedMinutes = 0,
    this.availableWorkMinutes = 0,
  });
}

class PlannerAlgorithm {
  /// Deterministically fits candidate tasks into free blocks between wake and sleep.
  static PlannerResult fitTasksIntoDay({
    required List<TaskItem> tasks,
    required int wakeHour,
    required int wakeMinute,
    required int sleepHour,
    required int sleepMinute,
    List<DailyPlanBlock> fixedBlocks = const [],
    bool isBangla = false,
  }) {
    // 1. Identify "Eat the Frog" task (highest priority + longest duration, unblocked)
    final eligibleTasks = tasks.where((t) => !t.isCompleted && !t.isBlocked).toList();
    final frogTask = pickEatTheFrog(eligibleTasks);

    // 2. Sort tasks by score, boosting the frog task
    final sortedTasks = List<TaskItem>.from(eligibleTasks)
      ..sort((a, b) {
        final aScore = a.computeDynamicScore() + (a.id == frogTask?.id ? 30.0 : 0.0);
        final bScore = b.computeDynamicScore() + (b.id == frogTask?.id ? 30.0 : 0.0);
        return bScore.compareTo(aScore);
      });

    // 3. Compute available time windows between wake and sleep
    final dayStartMinutes = wakeHour * 60 + wakeMinute;
    final dayEndMinutes = sleepHour * 60 + sleepMinute;
    final totalWorkWindowMinutes = dayEndMinutes > dayStartMinutes ? dayEndMinutes - dayStartMinutes : 0;

    // Build timeline of occupied slots by fixed blocks
    final occupiedMinutes = fixedBlocks.fold<int>(0, (sum, b) => sum + b.durationMinutes);
    final availableMinutes = (totalWorkWindowMinutes - occupiedMinutes).clamp(0, 1440);

    final totalRequiredMinutes = sortedTasks.fold<int>(0, (sum, t) => sum + t.estimatedMinutes);
    final isOverloaded = totalRequiredMinutes > availableMinutes;
    final deficit = isOverloaded ? totalRequiredMinutes - availableMinutes : 0;

    // 4. Energy-aware scheduling
    // Peak window default: 09:00 (540m) to 13:00 (780m)
    const peakStartMinutes = 9 * 60; // 9:00 AM
    const peakEndMinutes = 13 * 60; // 1:00 PM

    final plannedBlocks = <DailyPlanBlock>[];
    int cursor = dayStartMinutes;

    for (final task in sortedTasks) {
      if (cursor + task.estimatedMinutes > dayEndMinutes) {
        // Exceeds available day bounds
        break;
      }

      // Skip over fixed block collisions
      for (final fb in fixedBlocks) {
        final fbStart = fb.startHour * 60 + fb.startMinute;
        final fbEnd = fb.endHour * 60 + fb.endMinute;
        if (cursor < fbEnd && cursor + task.estimatedMinutes > fbStart) {
          cursor = fbEnd + 5; // Move past fixed event
        }
      }

      final startH = cursor ~/ 60;
      final startM = cursor % 60;
      final endTotal = cursor + task.estimatedMinutes;
      final endH = endTotal ~/ 60;
      final endM = endTotal % 60;

      final isInPeak = cursor >= peakStartMinutes && cursor < peakEndMinutes;
      final isHighFriction = task.priority == TaskPriority.urgentImportant || task.estimatedMinutes >= 45;
      final blockCategory = (isInPeak && isHighFriction) ? 'Deep Focus' : task.category;

      plannedBlocks.add(
        DailyPlanBlock(
          id: 'block_${task.id}',
          title: task.title,
          startHour: startH,
          startMinute: startM,
          endHour: endH,
          endMinute: endM,
          taskId: task.id,
          category: blockCategory,
        ),
      );

      // Advance cursor + 10 minute buffer after heavy focus tasks
      final buffer = task.estimatedMinutes >= 45 ? 10 : 5;
      cursor = endTotal + buffer;
    }

    return PlannerResult(
      blocks: [...fixedBlocks, ...plannedBlocks]..sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute)),
      isOverloaded: isOverloaded,
      deficitMinutes: deficit,
      frogTask: frogTask,
      totalPlannedMinutes: totalRequiredMinutes,
      availableWorkMinutes: availableMinutes,
    );
  }

  /// Selects the single highest-impact/highest-friction task for the day.
  static TaskItem? pickEatTheFrog(List<TaskItem> tasks) {
    final candidates = tasks.where((t) => !t.isCompleted && !t.isBlocked).toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      // 1. High priority first
      final pCmp = a.priority.index.compareTo(b.priority.index);
      if (pCmp != 0) return pCmp;
      // 2. Longer estimated minutes
      return b.estimatedMinutes.compareTo(a.estimatedMinutes);
    });

    return candidates.first;
  }

  /// "Reset My Day": Reshuffle uncompleted tasks from current time forward
  static List<DailyPlanBlock> resetMyDay({
    required List<DailyPlanBlock> currentBlocks,
    required List<TaskItem> tasks,
    required DateTime now,
    required int sleepHour,
    bool isBangla = false,
  }) {
    final currentMinutes = now.hour * 60 + now.minute;
    final preservedBlocks = currentBlocks.where((b) {
      if (b.isCompleted) return true;
      if (b.taskId == null && (b.endHour * 60 + b.endMinute) <= currentMinutes) return true;
      return false;
    }).toList();

    final uncompletedTaskIds = currentBlocks
        .where((b) => !b.isCompleted && b.taskId != null)
        .map((b) => b.taskId!)
        .toSet();

    final remainingTasks = tasks.where((t) => uncompletedTaskIds.contains(t.id) && !t.isCompleted).toList();

    // Re-fit starting from now + 10 mins
    final newStartMinutes = currentMinutes + 10;
    int cursor = newStartMinutes;
    final reshuffled = <DailyPlanBlock>[];

    for (final task in remainingTasks) {
      if (cursor + task.estimatedMinutes > sleepHour * 60) break;

      final startH = cursor ~/ 60;
      final startM = cursor % 60;
      final endTotal = cursor + task.estimatedMinutes;
      final endH = endTotal ~/ 60;
      final endM = endTotal % 60;

      reshuffled.add(
        DailyPlanBlock(
          id: 'reset_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          title: task.title,
          startHour: startH,
          startMinute: startM,
          endHour: endH,
          endMinute: endM,
          taskId: task.id,
          category: task.category,
        ),
      );
      cursor = endTotal + 10; // 10 min buffer
    }

    return [...preservedBlocks, ...reshuffled]..sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute));
  }
}
