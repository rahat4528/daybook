// NFC Routine Automation Service for DayBook (Page 04)
// Manages physical NFC tag mappings, 60s debounce, routine execution, and SQLite/Entries logging.

import 'package:flutter/foundation.dart';
import '../models/nfc_routine_item.dart';
import '../../data/repositories/entries_repository.dart';

class NfcRoutineService extends ChangeNotifier {
  final EntriesRepository? entriesRepo;
  final Map<String, NfcRoutineItem> _routines = {};
  final Map<String, NfcTagItem> _tagsByUid = {};
  final List<NfcEventLogItem> _eventLogs = [];
  final Map<String, DateTime> _lastScanByUid = {};

  NfcRoutineService({this.entriesRepo}) {
    _seedDefaultRoutinesAndTags();
  }

  void _seedDefaultRoutinesAndTags() {
    final r1 = NfcRoutineItem(
      id: 'routine_plant',
      name: 'Water Desk Plants',
      category: NfcRoutineCategory.plant,
      recurrenceDays: 3,
      pairedTagUid: '04:A2:8B:11:F2:60:80',
    );
    final r2 = NfcRoutineItem(
      id: 'routine_keys',
      name: 'Keys Placed at Home',
      category: NfcRoutineCategory.keys,
      recurrenceDays: 1,
      pairedTagUid: '04:B3:9C:22:E3:71:81',
    );
    final r3 = NfcRoutineItem(
      id: 'routine_vitamins',
      name: 'Take Daily Vitamins',
      category: NfcRoutineCategory.medication,
      recurrenceDays: 1,
      pairedTagUid: '04:C4:0D:33:D4:82:82',
    );
    final r4 = NfcRoutineItem(
      id: 'routine_coffee',
      name: 'Morning Coffee Ritual',
      category: NfcRoutineCategory.coffee,
      recurrenceDays: 1,
      pairedTagUid: '04:D5:1E:44:C5:93:83',
    );

    _routines[r1.id] = r1;
    _routines[r2.id] = r2;
    _routines[r3.id] = r3;
    _routines[r4.id] = r4;

    _tagsByUid[r1.pairedTagUid!] = NfcTagItem(
      id: 'tag_1',
      tagUid: r1.pairedTagUid!,
      label: 'Plant Pot NFC Tag',
      routineId: r1.id,
    );
    _tagsByUid[r2.pairedTagUid!] = NfcTagItem(
      id: 'tag_2',
      tagUid: r2.pairedTagUid!,
      label: 'Key Bowl NFC Tag',
      routineId: r2.id,
    );
    _tagsByUid[r3.pairedTagUid!] = NfcTagItem(
      id: 'tag_3',
      tagUid: r3.pairedTagUid!,
      label: 'Medicine Cabinet Tag',
      routineId: r3.id,
    );
    _tagsByUid[r4.pairedTagUid!] = NfcTagItem(
      id: 'tag_4',
      tagUid: r4.pairedTagUid!,
      label: 'Coffee Machine Tag',
      routineId: r4.id,
    );
  }

  List<NfcRoutineItem> get routines => _routines.values.toList();
  List<NfcTagItem> get pairedTags => _tagsByUid.values.toList();
  List<NfcEventLogItem> get recentLogs => List.unmodifiable(_eventLogs);

  NfcRoutineItem? getRoutine(String id) => _routines[id];
  NfcTagItem? getTagByUid(String uid) => _tagsByUid[uid];

  /// Simulates or executes an NFC tag scan with a 60-second duplicate debounce filter.
  ({bool success, String message, NfcRoutineItem? routine}) handleTagScan(String tagUid) {
    final now = DateTime.now();

    // 1. Debounce check (60 seconds)
    if (_lastScanByUid.containsKey(tagUid)) {
      final lastScan = _lastScanByUid[tagUid]!;
      if (now.difference(lastScan).inSeconds < 60) {
        return (
          success: false,
          message: 'Debounced: Tag was already scanned within the last 60 seconds.',
          routine: null,
        );
      }
    }

    final tag = _tagsByUid[tagUid];
    if (tag == null) {
      return (
        success: false,
        message: 'Unrecognized Tag ($tagUid). Please pair it with a routine.',
        routine: null,
      );
    }

    final routine = _routines[tag.routineId];
    if (routine == null) {
      return (
        success: false,
        message: 'Paired routine not found.',
        routine: null,
      );
    }

    // 2. Update routine execution record
    _lastScanByUid[tagUid] = now;
    final updatedRoutine = routine.copyWith(
      lastTriggeredAt: now,
      totalCompletions: routine.totalCompletions + 1,
    );
    _routines[routine.id] = updatedRoutine;

    // 3. Create event log
    final eventLog = NfcEventLogItem(
      id: 'nfc_log_${now.millisecondsSinceEpoch}',
      routineId: routine.id,
      routineName: routine.name,
      tagUid: tagUid,
      occurredAt: now,
      note: 'Verified via 13.56MHz NFC scan',
    );
    _eventLogs.insert(0, eventLog);

    // 4. Log to DayBook Single Event Log
    entriesRepo?.createManualEntry(
      type: 'nfc_routine_triggered',
      payload: {
        'routineId': routine.id,
        'routineName': routine.name,
        'category': routine.category.name,
        'tagUid': tagUid,
      },
      source: 'nfc_hardware_trigger',
    );

    notifyListeners();

    return (
      success: true,
      message: '✓ ${routine.name} successfully logged!',
      routine: updatedRoutine,
    );
  }

  void pairTag({
    required String tagUid,
    required String label,
    required String routineId,
  }) {
    final newTag = NfcTagItem(
      id: 'tag_${DateTime.now().millisecondsSinceEpoch}',
      tagUid: tagUid,
      label: label,
      routineId: routineId,
    );
    _tagsByUid[tagUid] = newTag;

    final routine = _routines[routineId];
    if (routine != null) {
      _routines[routineId] = routine.copyWith(pairedTagUid: tagUid);
    }

    notifyListeners();
  }

  void saveRoutine(NfcRoutineItem routine) {
    _routines[routine.id] = routine;
    notifyListeners();
  }

  void deleteRoutine(String id) {
    _routines.remove(id);
    _tagsByUid.removeWhere((_, tag) => tag.routineId == id);
    notifyListeners();
  }
}
