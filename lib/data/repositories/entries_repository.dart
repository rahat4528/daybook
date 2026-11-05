import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/day_page.dart';
import '../../domain/models/journal_entry.dart';
import '../../domain/models/time_capsule.dart';
import '../../domain/services/nightly_summary_service.dart';

class UndoAction {
  final String actionType; // 'delete' or 'update'
  final JournalEntry entry;

  const UndoAction({required this.actionType, required this.entry});
}

class EntriesRepository {
  // In-memory backing store for instant access, tested for offline survival
  final Map<String, JournalEntry> _entries = {};
  final Map<String, DayPageModel> _dayPages = {};
  final List<TimeCapsuleItem> _timeCapsules = [];
  final List<UndoAction> _undoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;

  // --- CRUD & UNDO ---
  void insertEntry(JournalEntry entry) {
    _entries[entry.id] = entry;
    _updateDayPageCache(entry.dayKey);
  }

  void updateEntry(JournalEntry entry) {
    final old = _entries[entry.id];
    if (old != null) {
      _undoStack.add(UndoAction(actionType: 'update', entry: old));
    }
    _entries[entry.id] = entry;
    _updateDayPageCache(entry.dayKey);
  }

  bool deleteEntry(String id) {
    final entry = _entries.remove(id);
    if (entry != null) {
      _undoStack.add(UndoAction(actionType: 'delete', entry: entry));
      _updateDayPageCache(entry.dayKey);
      return true;
    }
    return false;
  }

  JournalEntry? undo() {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.removeLast();

    if (action.actionType == 'delete' || action.actionType == 'update') {
      _entries[action.entry.id] = action.entry;
      _updateDayPageCache(action.entry.dayKey);
      return action.entry;
    }
    return null;
  }

  // --- DAY PAGE QUERIES ---
  DayPageModel getDayPage(String dayKey, {DateTime? fallbackDate}) {
    final existing = _dayPages[dayKey];
    final dayEntries = _entries.values.where((e) => e.dayKey == dayKey).toList()
      ..sort((a, b) => a.ts.compareTo(b.ts));

    final parsedDate = fallbackDate ?? DateTime.tryParse(dayKey) ?? DateTime.now();

    if (existing != null) {
      final updated = existing.copyWith(
        entries: dayEntries,
        calculatedScore: existing.computeDayScore(),
      );
      _dayPages[dayKey] = updated;
      return updated;
    }

    final newPage = DayPageModel(
      dayKey: dayKey,
      date: parsedDate,
      entries: dayEntries,
    );
    final calculated = newPage.copyWith(calculatedScore: newPage.computeDayScore());
    _dayPages[dayKey] = calculated;
    return calculated;
  }

  void saveDayPageMetadata({
    required String dayKey,
    String? title,
    bool? isStarred,
    String? reflectionNote,
    String? gratitudeNote,
    String? nightlySummary,
  }) {
    final current = getDayPage(dayKey);
    final updated = current.copyWith(
      title: title ?? current.title,
      isStarred: isStarred ?? current.isStarred,
      reflectionNote: reflectionNote ?? current.reflectionNote,
      gratitudeNote: gratitudeNote ?? current.gratitudeNote,
      nightlySummary: nightlySummary ?? current.nightlySummary,
    );
    _dayPages[dayKey] = updated.copyWith(calculatedScore: updated.computeDayScore());
  }

  void generateAndSaveNightlySummary(String dayKey, {bool isBangla = false}) {
    final page = getDayPage(dayKey);
    final summary = NightlySummaryService.synthesizeOfflineSummary(page, isBangla: isBangla);
    saveDayPageMetadata(dayKey: dayKey, nightlySummary: summary);
  }

  void _updateDayPageCache(String dayKey) {
    getDayPage(dayKey);
  }

  // --- ON THIS DAY (1 MONTH & 1 YEAR AGO) ---
  List<DayPageModel> getOnThisDay(DateTime referenceDate) {
    final results = <DayPageModel>[];

    // 1 month ago
    final oneMonthAgo = DateTime(referenceDate.year, referenceDate.month - 1, referenceDate.day);
    final monthKey = _formatKey(oneMonthAgo);
    final monthPage = _dayPages[monthKey];
    if (monthPage != null && monthPage.entries.isNotEmpty) {
      results.add(monthPage);
    }

    // 1 year ago
    final oneYearAgo = DateTime(referenceDate.year - 1, referenceDate.month, referenceDate.day);
    final yearKey = _formatKey(oneYearAgo);
    final yearPage = _dayPages[yearKey];
    if (yearPage != null && yearPage.entries.isNotEmpty) {
      results.add(yearPage);
    }

    return results;
  }

  // --- MONTH SHELF & CALENDAR HEAT VIEW ---
  List<DayPageModel> getMonthDays(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final pages = <DayPageModel>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final key = _formatKey(date);
      pages.add(getDayPage(key, fallbackDate: date));
    }

    return pages;
  }

  List<DayPageModel> getBookmarkedDays() {
    return _dayPages.values.where((p) => p.isStarred).toList();
  }

  // --- SEARCH ---
  List<JournalEntry> searchEntries(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();

    return _entries.values.where((e) {
      final text = e.displayText().toLowerCase();
      final title = (e.payload['title'] ?? '').toString().toLowerCase();
      final note = (e.payload['note'] ?? '').toString().toLowerCase();
      return text.contains(lower) || title.contains(lower) || note.contains(lower);
    }).toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
  }

  // --- TIME CAPSULES ---
  void addTimeCapsule(TimeCapsuleItem capsule) {
    _timeCapsules.add(capsule);
  }

  List<TimeCapsuleItem> getTimeCapsules() {
    return List.unmodifiable(_timeCapsules);
  }

  List<TimeCapsuleItem> unlockEligibleCapsules(DateTime now) {
    final newlyUnlocked = <TimeCapsuleItem>[];
    for (int i = 0; i < _timeCapsules.length; i++) {
      final c = _timeCapsules[i];
      if (!c.isUnlocked && now.isAfter(c.unlockAt)) {
        final unlocked = c.copyWith(isUnlocked: true, notified: true);
        _timeCapsules[i] = unlocked;
        newlyUnlocked.add(unlocked);
      }
    }
    return newlyUnlocked;
  }

  // Seed simulated month for verification
  void seedSimulatedMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day, 8, 30);
      final dayKey = _formatKey(date);

      // 1. Alarm dismissed
      insertEntry(JournalEntry(
        id: 'alarm_$dayKey',
        type: EntryType.alarmDismissed,
        ts: DateTime(year, month, day, 6, 30),
        payload: {'challenge': 'Math Challenge (Hard)'},
        dayKey: dayKey,
      ));

      // 2. Tasks completed
      insertEntry(JournalEntry(
        id: 'task_${dayKey}_1',
        type: EntryType.taskCompleted,
        ts: DateTime(year, month, day, 10, 15),
        payload: {'task_name': 'Review DayBook Architecture'},
        dayKey: dayKey,
      ));

      if (day % 2 == 0) {
        insertEntry(JournalEntry(
          id: 'task_${dayKey}_2',
          type: EntryType.taskCompleted,
          ts: DateTime(year, month, day, 14, 0),
          payload: {'task_name': 'Ship Clean Unit Tests'},
          dayKey: dayKey,
        ));
      }

      // 3. Habits
      insertEntry(JournalEntry(
        id: 'habit_${dayKey}_1',
        type: EntryType.habitLogged,
        ts: DateTime(year, month, day, 12, 0),
        payload: {'habit_name': 'Drink 2.5L Water'},
        dayKey: dayKey,
      ));

      // 4. Focus session
      insertEntry(JournalEntry(
        id: 'focus_$dayKey',
        type: EntryType.focusSession,
        ts: DateTime(year, month, day, 15, 30),
        payload: {'minutes': 45},
        dayKey: dayKey,
      ));

      // 5. Weather
      insertEntry(JournalEntry(
        id: 'weather_$dayKey',
        type: EntryType.weatherChange,
        ts: DateTime(year, month, day, 18, 0),
        payload: {'condition': 'Clear Sky', 'temp': 26},
        dayKey: dayKey,
      ));

      // Evening reflections & summary
      saveDayPageMetadata(
        dayKey: dayKey,
        title: day == 1 ? 'First Day of Month' : (day == 15 ? 'Mid-Month Sprint' : null),
        isStarred: day % 5 == 0,
        reflectionNote: 'Maintained strong focus on high-impact priorities.',
        gratitudeNote: 'Grateful for quiet evening focus and health.',
      );
      generateAndSaveNightlySummary(dayKey);
    }
  }

  String _formatKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

// Global Riverpod Provider
final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  return EntriesRepository();
});

