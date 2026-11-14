// Habit Notification Service for DayBook (Page 03)
// Handles interactive notifications with "Done" and "Snooze 30m" actions.

import 'package:flutter/foundation.dart';
import 'habit_service.dart';
import '../../data/repositories/entries_repository.dart';
import '../models/day_page.dart';

class HabitSnoozeRecord {
  final String habitId;
  final String habitTitle;
  final DateTime originalScheduledTime;
  final DateTime snoozedUntil;

  HabitSnoozeRecord({
    required this.habitId,
    required this.habitTitle,
    required this.originalScheduledTime,
    required this.snoozedUntil,
  });
}

class HabitNotificationService extends ChangeNotifier {
  static const String actionDone = 'ACTION_DONE';
  static const String actionSnooze = 'ACTION_SNOOZE';
  static const String categoryHabitAction = 'HABIT_ACTION';

  final HabitService habitService;
  final EntriesRepository entriesRepo;
  final Map<String, HabitSnoozeRecord> _activeSnoozes = {};

  HabitNotificationService({
    required this.habitService,
    required this.entriesRepo,
  });

  Map<String, HabitSnoozeRecord> get activeSnoozes => Map.unmodifiable(_activeSnoozes);

  bool isSnoozed(String habitId) {
    final record = _activeSnoozes[habitId];
    if (record == null) return false;
    if (DateTime.now().isAfter(record.snoozedUntil)) {
      _activeSnoozes.remove(habitId);
      return false;
    }
    return true;
  }

  /// Processes an incoming notification action without requiring a full app launch.
  /// Idempotent: Repeated taps of 'Done' will not double-count completions.
  bool handleNotificationAction(String actionIdentifier, String habitId) {
    final habit = habitService.getHabit(habitId);
    if (habit == null) return false;

    if (actionIdentifier == actionDone) {
      final todayKey = DayPageModel.formatDayKey(DateTime.now());
      if (habitService.isHabitCompleted(habitId, todayKey)) {
        // Already completed today, ignore repeated tap
        return true;
      }

      // Mark completed directly in HabitService
      habitService.toggleHabit(habitId, entriesRepo: entriesRepo);
      _activeSnoozes.remove(habitId);

      // Log direct event to Single Event Log
      entriesRepo.createManualEntry(
        type: 'habit_notification_done',
        payload: {
          'habitId': habitId,
          'title': habit.title,
          'action': 'ACTION_DONE',
          'streak': habit.currentStreak,
        },
        source: 'interactive_notification',
      );

      notifyListeners();
      return true;
    } else if (actionIdentifier == actionSnooze) {
      // Reschedule reminder 30 minutes in future
      final snoozedUntil = DateTime.now().add(const Duration(minutes: 30));
      _activeSnoozes[habitId] = HabitSnoozeRecord(
        habitId: habitId,
        habitTitle: habit.title,
        originalScheduledTime: DateTime.now(),
        snoozedUntil: snoozedUntil,
      );

      entriesRepo.createManualEntry(
        type: 'habit_notification_snooze',
        payload: {
          'habitId': habitId,
          'title': habit.title,
          'action': 'ACTION_SNOOZE',
          'snoozedUntil': snoozedUntil.toIso8601String(),
        },
        source: 'interactive_notification',
      );

      notifyListeners();
      return true;
    }

    return false;
  }

  /// Returns today's habit progress (e.g. 5 of 7 completed)
  Map<String, int> getDailyHabitProgress() {
    final habits = habitService.habits;
    final total = habits.length;
    final todayKey = DayPageModel.formatDayKey(DateTime.now());
    final completed = habits.where((h) => habitService.isHabitCompleted(h.id, todayKey)).length;

    return {
      'completed': completed,
      'total': total,
    };
  }
}
