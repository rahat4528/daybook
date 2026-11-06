import 'package:flutter/foundation.dart';
import '../models/day_page.dart';
import '../models/journal_entry.dart';
import '../models/dhar_record.dart';
import '../../data/repositories/entries_repository.dart';

class DharService extends ChangeNotifier {
  static int _dharCounter = 0;
  final Map<String, DharRecord> _records = {};

  List<DharRecord> get allRecords {
    final list = _records.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<DharRecord> get activeReceivables =>
      allRecords.where((r) => r.direction == DharDirection.theyOweMe && !r.isSettled).toList();

  List<DharRecord> get activePayables =>
      allRecords.where((r) => r.direction == DharDirection.iOweThem && !r.isSettled).toList();

  List<DharRecord> get settledRecords =>
      allRecords.where((r) => r.isSettled).toList();

  int get totalReceivablePaisa =>
      activeReceivables.fold(0, (sum, r) => sum + r.remainingPaisa);

  int get totalPayablePaisa =>
      activePayables.fold(0, (sum, r) => sum + r.remainingPaisa);

  double get totalReceivableBdt => totalReceivablePaisa / 100.0;
  double get totalPayableBdt => totalPayablePaisa / 100.0;

  String formatBdt(int paisa) => '৳${(paisa / 100.0).toStringAsFixed(2)}';

  List<DharRecord> getRecordsForPerson(String personId) =>
      allRecords.where((r) => r.personId == personId).toList();

  DharRecord addRecord({
    required String personId,
    required String personName,
    required int amountPaisa,
    required DharDirection direction,
    DateTime? dueDate,
    String notes = '',
    EntriesRepository? entriesRepo,
  }) {
    if (amountPaisa <= 0) {
      throw ArgumentError('Dhar amount must be greater than zero paisa.');
    }

    final now = DateTime.now();
    final id = 'dhar_${now.microsecondsSinceEpoch}_${++_dharCounter}';

    final record = DharRecord(
      id: id,
      personId: personId,
      personName: personName,
      initialAmountPaisa: amountPaisa,
      direction: direction,
      dueDate: dueDate,
      notes: notes,
      createdAt: now,
    );

    _records[id] = record;

    // Log to Day Page single event log
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_dhar_$id',
      type: EntryType.expenseLogged,
      ts: now,
      dayKey: DayPageModel.formatDayKey(now),
      payload: {
        'dharId': id,
        'personName': personName,
        'amountPaisa': amountPaisa,
        'direction': direction.name,
        'notes': notes,
      },
    ));

    notifyListeners();
    return record;
  }

  bool addRepayment({
    required String dharId,
    required int amountPaisa,
    String notes = '',
    DateTime? date,
    EntriesRepository? entriesRepo,
  }) {
    final record = _records[dharId];
    if (record == null) return false;
    if (amountPaisa <= 0 || amountPaisa > record.remainingPaisa) return false;

    final repDate = date ?? DateTime.now();
    final repId = 'rep_${repDate.microsecondsSinceEpoch}';

    final repayment = DharRepayment(
      id: repId,
      amountPaisa: amountPaisa,
      date: repDate,
      notes: notes,
    );

    final updatedRepayments = List<DharRepayment>.from(record.repayments)..add(repayment);
    final updated = record.copyWith(repayments: updatedRepayments);
    _records[dharId] = updated;

    // Log partial repayment event
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_dhar_rep_$repId',
      type: EntryType.expenseLogged,
      ts: repDate,
      dayKey: DayPageModel.formatDayKey(repDate),
      payload: {
        'dharId': dharId,
        'personName': record.personName,
        'amountPaisa': amountPaisa,
        'action': 'repayment',
        'remainingPaisa': updated.remainingPaisa,
      },
    ));

    notifyListeners();
    return true;
  }

  DharRecord recordRepayment({
    required String recordId,
    required int amountPaisa,
    String note = '',
    DateTime? date,
    EntriesRepository? entriesRepo,
  }) {
    final record = _records[recordId];
    if (record == null) {
      throw StateError('Dhar record not found for id $recordId');
    }
    if (amountPaisa <= 0) {
      throw ArgumentError('Repayment amount must be strictly positive.');
    }
    if (amountPaisa > record.remainingPaisa) {
      throw ArgumentError('Repayment amount ($amountPaisa paisa) exceeds remaining balance (${record.remainingPaisa} paisa).');
    }

    final success = addRepayment(
      dharId: recordId,
      amountPaisa: amountPaisa,
      notes: note,
      date: date,
      entriesRepo: entriesRepo,
    );

    if (!success) {
      throw StateError('Failed to record repayment.');
    }

    return _records[recordId]!;
  }
}
