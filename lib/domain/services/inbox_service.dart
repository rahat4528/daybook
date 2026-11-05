import 'package:flutter/foundation.dart';
import '../../core/enums/task_priority.dart';
import '../models/capture_item.dart';
import '../models/journal_entry.dart';
import '../models/rich_note.dart';
import '../models/task_item.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/tasks_and_goals_repository.dart';
import 'banglish_parser.dart';

class InboxTriageAction {
  final String captureId;
  final String action; // 'task', 'expense', 'note', 'archived'
  final CaptureItem previousState;
  final String? createdEntityId;

  const InboxTriageAction({
    required this.captureId,
    required this.action,
    required this.previousState,
    this.createdEntityId,
  });
}

class InboxService extends ChangeNotifier {
  static String formatDayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  final Map<String, CaptureItem> _captures = {};
  final Map<String, RichNote> _notes = {};
  final List<InboxTriageAction> _triageUndoStack = [];
  int _idCounter = 0;

  bool get canUndo => _triageUndoStack.isNotEmpty;

  int get unprocessedCount =>
      _captures.values.where((c) => !c.isProcessed).length;

  List<CaptureItem> getUnprocessedCaptures() {
    final list = _captures.values.where((c) => !c.isProcessed).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<CaptureItem> getAllCaptures() {
    final list = _captures.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Ingests a new capture from typed text, voice recording, or Android share intent.
  CaptureItem createCapture({
    required String rawText,
    required CaptureSource source,
    String? attachmentUri,
    Map<String, dynamic> metadata = const {},
  }) {
    _idCounter++;
    final id = 'cap_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
    final item = CaptureItem(
      id: id,
      rawText: rawText.trim(),
      source: source,
      createdAt: DateTime.now(),
      attachmentUri: attachmentUri,
      metadata: metadata,
    );
    _captures[id] = item;
    notifyListeners();
    return item;
  }

  /// Triages a capture into a TaskItem and saves to Tasks repository and single event log.
  TaskItem convertToTask(
    String captureId, {
    required TasksAndGoalsRepository tasksRepo,
    EntriesRepository? entriesRepo,
    TaskPriority? priorityOverride,
    DateTime? dueOverride,
    String? titleOverride,
  }) {
    final cap = _captures[captureId];
    if (cap == null) throw ArgumentError('Capture not found: $captureId');

    final parsed = BanglishParser.parse(cap.rawText);
    _idCounter++;
    final taskId = 'task_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';

    final task = TaskItem(
      id: taskId,
      title: titleOverride ?? (parsed.title.isNotEmpty ? parsed.title : cap.rawText),
      dueAt: dueOverride ?? parsed.dueDate,
      priority: priorityOverride ?? parsed.priority,
      category: parsed.category ?? 'Inbox',
      isFrog: parsed.priority == TaskPriority.p1,
      createdAt: DateTime.now(),
    );

    tasksRepo.addTask(task);

    // Single event log entry in Day Page
    final dayKey = formatDayKey(DateTime.now());
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_task_$taskId',
      type: EntryType.taskCompleted,
      ts: DateTime.now(),
      payload: {
        'taskId': taskId,
        'title': task.title,
        'priority': task.priority.name,
        'fromCaptureId': captureId,
      },
      dayKey: dayKey,
      source: cap.source.name,
    ));

    _triageUndoStack.add(InboxTriageAction(
      captureId: captureId,
      action: 'task',
      previousState: cap,
      createdEntityId: taskId,
    ));

    _captures[captureId] = cap.copyWith(
      processedIntoType: 'task',
      processedId: taskId,
    );

    notifyListeners();
    return task;
  }

  /// Triages a capture into an Expense entry in the event log.
  Map<String, dynamic> convertToExpense(
    String captureId, {
    required EntriesRepository entriesRepo,
    double? amountOverride,
    String? categoryOverride,
    String? noteOverride,
  }) {
    final cap = _captures[captureId];
    if (cap == null) throw ArgumentError('Capture not found: $captureId');

    final parsed = BanglishParser.parse(cap.rawText);
    final amount = amountOverride ?? parsed.amount ?? 0.0;
    final category = categoryOverride ?? parsed.category ?? 'General';
    final note = noteOverride ?? (parsed.title.isNotEmpty ? parsed.title : cap.rawText);

    _idCounter++;
    final expenseId = 'exp_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
    final dayKey = formatDayKey(DateTime.now());

    final expensePayload = {
      'expenseId': expenseId,
      'amount': amount,
      'currency': 'BDT',
      'category': category,
      'note': note,
      'fromCaptureId': captureId,
    };

    entriesRepo.insertEntry(JournalEntry(
      id: 'entry_exp_$expenseId',
      type: EntryType.expenseLogged,
      ts: DateTime.now(),
      payload: expensePayload,
      dayKey: dayKey,
      source: cap.source.name,
    ));

    _triageUndoStack.add(InboxTriageAction(
      captureId: captureId,
      action: 'expense',
      previousState: cap,
      createdEntityId: expenseId,
    ));

    _captures[captureId] = cap.copyWith(
      processedIntoType: 'expense',
      processedId: expenseId,
    );

    notifyListeners();
    return expensePayload;
  }

  /// Triages a capture into a RichNote.
  RichNote convertToRichNote(
    String captureId, {
    EntriesRepository? entriesRepo,
    NoteType type = NoteType.plain,
    String? titleOverride,
    List<ChecklistItem>? checklistItems,
  }) {
    final cap = _captures[captureId];
    if (cap == null) throw ArgumentError('Capture not found: $captureId');

    _idCounter++;
    final noteId = 'note_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
    final dayKey = formatDayKey(DateTime.now());

    // Auto-detect link or plain
    NoteType effectiveType = type;
    String? linkUrl;
    if (type == NoteType.plain && (cap.rawText.contains('http://') || cap.rawText.contains('https://'))) {
      effectiveType = NoteType.link;
      final match = RegExp(r'https?://[^\s]+').firstMatch(cap.rawText);
      linkUrl = match?.group(0);
    }

    final note = RichNote(
      id: noteId,
      title: titleOverride ?? (cap.rawText.length > 40 ? '${cap.rawText.substring(0, 37)}...' : cap.rawText),
      body: cap.rawText,
      type: effectiveType,
      checklistItems: checklistItems ?? const [],
      attachmentUri: cap.attachmentUri,
      linkUrl: linkUrl,
      dayKey: dayKey,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _notes[noteId] = note;

    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_note_$noteId',
      type: EntryType.manualNote,
      ts: DateTime.now(),
      payload: {
        'noteId': noteId,
        'title': note.title,
        'type': note.type.name,
      },
      dayKey: dayKey,
      source: cap.source.name,
    ));

    _triageUndoStack.add(InboxTriageAction(
      captureId: captureId,
      action: 'note',
      previousState: cap,
      createdEntityId: noteId,
    ));

    _captures[captureId] = cap.copyWith(
      processedIntoType: 'note',
      processedId: noteId,
    );

    notifyListeners();
    return note;
  }

  /// Archives a capture without converting it.
  void archiveCapture(String captureId) {
    final cap = _captures[captureId];
    if (cap == null) return;

    _triageUndoStack.add(InboxTriageAction(
      captureId: captureId,
      action: 'archived',
      previousState: cap,
    ));

    _captures[captureId] = cap.copyWith(
      processedIntoType: 'archived',
    );
    notifyListeners();
  }

  /// Undoes the last triage action.
  CaptureItem? undoLastTriage() {
    if (_triageUndoStack.isEmpty) return null;
    final action = _triageUndoStack.removeLast();

    _captures[action.captureId] = action.previousState;

    if (action.actionType == 'note' && action.createdEntityId != null) {
      _notes.remove(action.createdEntityId);
    }

    notifyListeners();
    return _captures[action.captureId];
  }

  // --- RICH NOTE CRUD ---

  RichNote createRichNote(RichNote note, {EntriesRepository? entriesRepo}) {
    _notes[note.id] = note;
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_note_${note.id}',
      type: EntryType.manualNote,
      ts: DateTime.now(),
      payload: {
        'noteId': note.id,
        'title': note.title,
        'type': note.type.name,
      },
      dayKey: note.dayKey,
      source: 'app_manual',
    ));
    notifyListeners();
    return note;
  }

  List<RichNote> getNotesForDay(String dayKey) {
    final list = _notes.values.where((n) => n.dayKey == dayKey).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<RichNote> getPinnedNotes() {
    return _notes.values.where((n) => n.isPinned).toList();
  }

  bool toggleChecklistItem(String noteId, String itemId) {
    final note = _notes[noteId];
    if (note == null) return false;

    final updatedItems = note.checklistItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    _notes[noteId] = note.copyWith(
      checklistItems: updatedItems,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }
}

extension InboxTriageActionExtension on InboxTriageAction {
  String get actionType => action;
}

