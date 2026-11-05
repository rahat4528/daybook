import '../models/daily_plan_block.dart';
import '../models/task_item.dart';

class PlannerService {
  /// Generates a deterministic daily schedule fitting tasks into available gaps
  /// between wake time and sleep time.
  List<DailyPlanBlock> generateDailyPlan({
    required List<TaskItem> tasks,
    List<DailyPlanBlock> fixedBlocks = const [],
    int wakeHour = 6,
    int wakeMinute = 30,
    int sleepHour = 23,
    int sleepMinute = 0,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final List<DailyPlanBlock> schedule = List.from(fixedBlocks);

    // Sort existing fixed blocks chronologically
    schedule.sort((a, b) {
      final aMin = a.startHour * 60 + a.startMinute;
      final bMin = b.startHour * 60 + b.startMinute;
      return aMin.compareTo(bMin);
    });

    final wakeMinutes = wakeHour * 60 + wakeMinute;
    final sleepMinutes = sleepHour * 60 + sleepMinute;

    // Filter candidate tasks (not completed, sorted by dynamic score descending)
    final candidateTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => b.computeDynamicScore(now).compareTo(a.computeDynamicScore(now)));

    int currentPointer = wakeMinutes;

    for (final task in candidateTasks) {
      if (currentPointer >= sleepMinutes - 20) break; // Day is full

      final duration = task.estimatedMinutes.clamp(15, 120);

      // Check if slot overlaps with an existing fixed block
      bool placed = false;
      while (currentPointer + duration <= sleepMinutes && !placed) {
        final slotStart = currentPointer;
        final slotEnd = currentPointer + duration;

        // Check conflict with any scheduled block
        final conflict = schedule.any((block) {
          final bStart = block.startHour * 60 + block.startMinute;
          final bEnd = block.endHour * 60 + block.endMinute;
          return (slotStart < bEnd) && (slotEnd > bStart);
        });

        if (!conflict) {
          final newBlock = DailyPlanBlock(
            id: 'block_${task.id}_${DateTime.now().microsecondsSinceEpoch}',
            title: task.title,
            startHour: slotStart ~/ 60,
            startMinute: slotStart % 60,
            endHour: slotEnd ~/ 60,
            endMinute: slotEnd % 60,
            taskId: task.id,
            category: task.category,
            isCompleted: false,
          );
          schedule.add(newBlock);
          currentPointer = slotEnd + 10; // 10 minute buffer between focus blocks
          placed = true;
        } else {
          // Advance past the conflicting block
          final nextFree = schedule
              .where((b) {
                final bEnd = b.endHour * 60 + b.endMinute;
                return bEnd > currentPointer;
              })
              .map((b) => b.endHour * 60 + b.endMinute)
              .fold<int>(currentPointer + 15, (acc, end) => end > acc ? end : acc);
          currentPointer = nextFree + 5;
        }
      }
    }

    // Sort final schedule by start time
    schedule.sort((a, b) {
      final aMin = a.startHour * 60 + a.startMinute;
      final bMin = b.startHour * 60 + b.startMinute;
      return aMin.compareTo(bMin);
    });

    return schedule;
  }

  /// Rollover unfinished blocks into a new daily plan.
  List<DailyPlanBlock> rolloverUnfinishedBlocks({
    required List<DailyPlanBlock> yesterdayBlocks,
    required List<DailyPlanBlock> todayBlocks,
  }) {
    final unfinished = yesterdayBlocks.where((b) => !b.isCompleted).toList();
    final combined = List<DailyPlanBlock>.from(todayBlocks);

    for (final block in unfinished) {
      final rolled = block.copyWith(
        id: 'rollover_${block.id}_${DateTime.now().millisecondsSinceEpoch}',
        isCompleted: false,
      );
      combined.add(rolled);
    }

    return combined;
  }
}
