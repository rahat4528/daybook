import 'package:flutter/foundation.dart';
import '../models/day_page.dart';
import '../models/habit_item.dart';
import '../models/journal_entry.dart';
import '../../data/repositories/entries_repository.dart';

class HabitService extends ChangeNotifier {
  final Map<String, HabitItem> _habits = {};
  final List<HabitLog> _logs = [];

  List<HabitItem> get habits => _habits.values.toList();

  HabitItem? getHabit(String id) => _habits[id];

  List<HabitLog> getLogsForHabit(String habitId) {
    return _logs.where((l) => l.habitId == habitId).toList();
  }

  /// Adds or updates a habit definition.
  void saveHabit(HabitItem habit) {
    _habits[habit.id] = habit;
    notifyListeners();
  }

  /// Deletes a habit and its associated logs.
  void deleteHabit(String id) {
    _habits.remove(id);
    _logs.removeWhere((l) => l.habitId == id);
    notifyListeners();
  }

  /// Checks if a habit was completed on a given day.
  bool isHabitCompleted(String habitId, String dayKey) {
    return _logs.any((l) => l.habitId == habitId && l.dayKey == dayKey && !l.isFreezeConsumed);
  }

  /// Toggles habit completion for a target date with streak calculation and freeze token logic.
  bool toggleHabit(
    String habitId, {
    DateTime? date,
    required EntriesRepository entriesRepo,
  }) {
    final habit = _habits[habitId];
    if (habit == null) return false;

    final targetDate = date ?? DateTime.now();
    final dayKey = DayPageModel.formatDayKey(targetDate);
    final existingIdx = _logs.indexWhere((l) => l.habitId == habitId && l.dayKey == dayKey);

    if (existingIdx >= 0) {
      // Toggle OFF: remove log and decrement streak
      _logs.removeAt(existingIdx);
      final newStreak = (habit.currentStreak - 1).clamp(0, 9999);
      _habits[habitId] = habit.copyWith(currentStreak: newStreak);
      notifyListeners();
      return false;
    } else {
      // Toggle ON: record completion
      final log = HabitLog(
        id: 'hlog_${DateTime.now().microsecondsSinceEpoch}',
        habitId: habitId,
        dayKey: dayKey,
        value: habit.targetValue,
        timestamp: DateTime.now(),
      );
      _logs.add(log);

      // Streak & Freeze Token Calculation
      int newStreak = habit.currentStreak + 1;
      int newLongest = newStreak > habit.longestStreak ? newStreak : habit.longestStreak;
      int newFreezeTokens = habit.freezeTokens;

      // Earn 1 freeze token every 7 consecutive days (max 2 active)
      if (newStreak > 0 && newStreak % 7 == 0 && newFreezeTokens < 2) {
        newFreezeTokens++;
      }

      _habits[habitId] = habit.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongest,
        freezeTokens: newFreezeTokens,
        lastCompletedDayKey: dayKey,
      );

      // Single Event Log compliance
      entriesRepo.insertEntry(JournalEntry(
        id: 'entry_habit_${log.id}',
        type: EntryType.habitLogged,
        ts: DateTime.now(),
        payload: {
          'habitId': habitId,
          'name': habit.name,
          'streak': newStreak,
          'freezeTokens': newFreezeTokens,
        },
        dayKey: dayKey,
        source: 'habit_tracker',
      ));

      notifyListeners();
      return true;
    }
  }

  /// Evaluates missed days for active habits and consumes freeze tokens if available.
  void evaluateStreakContinuity(DateTime today, EntriesRepository entriesRepo) {
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = DayPageModel.formatDayKey(yesterday);

    for (final habit in _habits.values) {
      if (habit.lastCompletedDayKey == null) continue;

      // If yesterday was missed and habit had an active streak
      if (habit.currentStreak > 0 && !isHabitCompleted(habit.id, yesterdayKey)) {
        if (habit.freezeTokens > 0) {
          // Consume 1 Freeze Token to preserve streak
          final freezeLog = HabitLog(
            id: 'hlog_freeze_${DateTime.now().microsecondsSinceEpoch}',
            habitId: habit.id,
            dayKey: yesterdayKey,
            value: 0,
            isFreezeConsumed: true,
            timestamp: DateTime.now(),
          );
          _logs.add(freezeLog);

          _habits[habit.id] = habit.copyWith(
            freezeTokens: habit.freezeTokens - 1,
            lastCompletedDayKey: yesterdayKey,
          );

          entriesRepo.insertEntry(JournalEntry(
            id: 'entry_freeze_${freezeLog.id}',
            type: EntryType.habitLogged,
            ts: DateTime.now(),
            payload: {
              'habitId': habit.id,
              'name': habit.name,
              'streakPreserved': habit.currentStreak,
              'freezeTokensRemaining': habit.freezeTokens - 1,
            },
            dayKey: yesterdayKey,
            source: 'streak_freeze_engine',
          ));
        } else {
          // No freeze tokens: streak resets to 0
          _habits[habit.id] = habit.copyWith(currentStreak: 0);
        }
      }
    }
    notifyListeners();
  }

  /// Generates a 30-day completion heatmap data array (0 to 4 opacity tier) for a habit.
  List<int> getHeatmap30Days(String habitId, DateTime reference) {
    final result = <int>[];
    for (int i = 29; i >= 0; i--) {
      final d = reference.subtract(Duration(days: i));
      final k = DayPageModel.formatDayKey(d);
      final hasLog = _logs.any((l) => l.habitId == habitId && l.dayKey == k);
      final isFrozen = _logs.any((l) => l.habitId == habitId && l.dayKey == k && l.isFreezeConsumed);

      if (isFrozen) {
        result.add(1); // 25% opacity for frozen day
      } else if (hasLog) {
        result.add(4); // 100% opacity for completed day
      } else {
        result.add(0); // 0% opacity for missed day
      }
    }
    return result;
  }
}
