import 'package:flutter/foundation.dart';
import '../models/day_page.dart';
import '../models/journal_entry.dart';
import '../models/mood_log.dart';
import '../../data/repositories/entries_repository.dart';

class WellnessService extends ChangeNotifier {
  final Map<String, MoodLog> _logs = {};

  List<MoodLog> get allLogs => _logs.values.toList();

  MoodLog? getLogForDay(String dayKey) => _logs[dayKey];

  MoodLog logCheckin({
    required int moodScore,
    required int energyScore,
    List<String> tags = const [],
    String? reflection,
    DateTime? timestamp,
    required EntriesRepository entriesRepo,
  }) {
    final now = timestamp ?? DateTime.now();
    final dayKey = DayPageModel.formatDayKey(now);
    final id = 'mood_${now.microsecondsSinceEpoch}';

    final log = MoodLog(
      id: id,
      moodScore: moodScore.clamp(1, 5),
      energyScore: energyScore.clamp(1, 5),
      tags: tags,
      reflection: reflection,
      dayKey: dayKey,
      timestamp: now,
    );

    _logs[dayKey] = log;

    entriesRepo.insertEntry(JournalEntry(
      id: 'entry_mood_$id',
      type: EntryType.moodEnergyCheckin,
      ts: now,
      mood: log.moodScore,
      energy: log.energyScore,
      payload: {
        'moodScore': log.moodScore,
        'energyScore': log.energyScore,
        'tags': log.tags,
        'reflection': log.reflection,
      },
      dayKey: dayKey,
      source: 'wellness_checkin',
    ));

    notifyListeners();
    return log;
  }
}
