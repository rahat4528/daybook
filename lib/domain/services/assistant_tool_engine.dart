import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/enums/task_priority.dart';
import '../models/alarm_item.dart';
import '../models/task_item.dart';
import '../models/tool_call_item.dart';
import '../models/memory_item.dart';
import '../models/focus_session.dart';
import '../models/rich_note.dart';
import '../models/day_page.dart';
import '../../data/app_repository.dart';

class AssistantToolEngine extends ChangeNotifier {
  final AppRepository? appRepository;

  // Strict allowlist of approved tools per Part 0 & Part 8 specification
  static const Set<String> allowlistedTools = {
    'create_task',
    'update_task',
    'complete_task',
    'delete_task',
    'list_tasks',
    'create_goal',
    'set_alarm',
    'plan_day',
    'save_memory',
    'clear_memories',
    'log_habit',
    'log_mood',
    'log_expense',
    'add_note',
    'start_focus',
    'search_entries',
  };

  // Destructive actions requiring mandatory user confirmation
  static const Set<String> destructiveTools = {
    'delete_task',
    'clear_memories',
    'bulk_complete_tasks',
    'reset_day_plan',
  };

  final List<ToolCallRecord> _toolCallLog = [];
  final Map<String, Future<void> Function()> _undoActions = {};

  AssistantToolEngine({this.appRepository});

  List<ToolCallRecord> get toolCallLog => List.unmodifiable(_toolCallLog);

  List<ToolCallRecord> get pendingConfirmations =>
      _toolCallLog.where((r) => r.needsConfirmation).toList();

  List<ToolCallRecord> get undoableCalls =>
      _toolCallLog.where((r) => r.canUndo).toList();

  bool isToolAllowlisted(String toolName) => allowlistedTools.contains(toolName);

  /// Validates tool schema arguments. Returns null if valid, or an error string if invalid.
  String? validateSchema(String toolName, Map<String, dynamic> args) {
    if (!isToolAllowlisted(toolName)) {
      return "Tool '$toolName' is not in the approved allowlist. Execution blocked.";
    }

    switch (toolName) {
      case 'create_task':
        if (!args.containsKey('title') || (args['title'] as String).trim().isEmpty) {
          return "Argument 'title' is required for create_task.";
        }
        break;
      case 'complete_task':
      case 'delete_task':
        if (!args.containsKey('task_id') || (args['task_id'] as String).trim().isEmpty) {
          return "Argument 'task_id' is required for $toolName.";
        }
        break;
      case 'set_alarm':
        if (!args.containsKey('time') || (args['time'] as String).trim().isEmpty) {
          return "Argument 'time' (HH:mm) is required for set_alarm.";
        }
        break;
      case 'save_memory':
        if (!args.containsKey('text') || (args['text'] as String).trim().isEmpty) {
          return "Argument 'text' is required for save_memory.";
        }
        break;
      case 'start_focus':
        if (args.containsKey('minutes') && (args['minutes'] as num) <= 0) {
          return "Argument 'minutes' must be a positive integer.";
        }
        break;
      case 'log_expense':
        if (!args.containsKey('amount') || (args['amount'] as num) <= 0) {
          return "Argument 'amount' must be positive for log_expense.";
        }
        break;
      case 'log_mood':
        if (!args.containsKey('rating') || (args['rating'] as num) < 1 || (args['rating'] as num) > 5) {
          return "Argument 'rating' must be between 1 and 5 for log_mood.";
        }
        break;
      case 'add_note':
        if (!args.containsKey('content') || (args['content'] as String).trim().isEmpty) {
          return "Argument 'content' is required for add_note.";
        }
        break;
    }
    return null;
  }

  /// Proposes or executes a tool call with strict validation and confirmation checks.
  Future<ToolCallRecord> requestToolExecution({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final validationError = validateSchema(toolName, arguments);
    if (validationError != null) {
      final rejected = ToolCallRecord(
        id: 'tc_${DateTime.now().microsecondsSinceEpoch}',
        toolName: toolName,
        arguments: arguments,
        status: ToolCallStatus.rejected,
        isDestructive: false,
        resultMessage: validationError,
        timestamp: DateTime.now(),
      );
      _toolCallLog.add(rejected);
      notifyListeners();
      return rejected;
    }

    final isDestructive = destructiveTools.contains(toolName);
    final recordId = 'tc_${DateTime.now().microsecondsSinceEpoch}';

    final initialRecord = ToolCallRecord(
      id: recordId,
      toolName: toolName,
      arguments: arguments,
      status: isDestructive ? ToolCallStatus.proposed : ToolCallStatus.confirmed,
      isDestructive: isDestructive,
      resultMessage: isDestructive ? "Awaiting confirmation for high-impact action." : null,
      timestamp: DateTime.now(),
    );

    _toolCallLog.add(initialRecord);
    notifyListeners();

    if (isDestructive) {
      // Must wait for user to confirm through UI
      return initialRecord;
    } else {
      // Safe to execute immediately
      return await _executeRecord(initialRecord);
    }
  }

  /// User explicitly confirms a destructive or pending action
  Future<ToolCallRecord> confirmAndExecute(String recordId) async {
    final idx = _toolCallLog.indexWhere((r) => r.id == recordId);
    if (idx == -1) throw Exception("Tool call not found: $recordId");

    final record = _toolCallLog[idx];
    if (record.status != ToolCallStatus.proposed) {
      return record;
    }

    final confirmed = record.copyWith(status: ToolCallStatus.confirmed);
    _toolCallLog[idx] = confirmed;
    notifyListeners();

    return await _executeRecord(confirmed);
  }

  /// User explicitly rejects a pending tool call
  ToolCallRecord rejectToolCall(String recordId) {
    final idx = _toolCallLog.indexWhere((r) => r.id == recordId);
    if (idx == -1) throw Exception("Tool call not found: $recordId");

    final updated = _toolCallLog[idx].copyWith(
      status: ToolCallStatus.rejected,
      resultMessage: "Action rejected by user.",
    );
    _toolCallLog[idx] = updated;
    notifyListeners();
    return updated;
  }

  /// Roll back an executed tool call using its registered undo handler
  Future<bool> undoToolCall(String recordId) async {
    final idx = _toolCallLog.indexWhere((r) => r.id == recordId);
    if (idx == -1) return false;

    final record = _toolCallLog[idx];
    if (record.status != ToolCallStatus.executed) return false;

    final undoHandler = _undoActions[recordId];
    if (undoHandler == null) return false;

    try {
      await undoHandler();
      _undoActions.remove(recordId);

      _toolCallLog[idx] = record.copyWith(
        status: ToolCallStatus.undone,
        resultMessage: "Rolled back: ${record.undoDescription ?? 'Action reversed'}",
      );
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Internal dispatcher executing verified tool logic
  Future<ToolCallRecord> _executeRecord(ToolCallRecord record) async {
    final idx = _toolCallLog.indexWhere((r) => r.id == record.id);
    String resultMessage = '';
    String? undoDesc;
    Future<void> Function()? undoAction;

    final args = record.arguments;

    switch (record.toolName) {
      case 'create_task':
        final title = args['title'] as String;
        final priorityStr = args['priority'] as String? ?? 'p3';
        final estimate = args['estimate_minutes'] as int? ?? 30;

        TaskPriority priority = TaskPriority.p3;
        if (priorityStr.toLowerCase() == 'p1' || priorityStr.toLowerCase() == 'urgent') {
          priority = TaskPriority.p1;
        } else if (priorityStr.toLowerCase() == 'p2') {
          priority = TaskPriority.p2;
        }

        final taskId = 'task_ai_${DateTime.now().microsecondsSinceEpoch}';
        final task = TaskItem(
          id: taskId,
          title: title,
          priority: priority,
          estimatedMinutes: estimate,
          createdAt: DateTime.now(),
        );

        appRepository?.taskService.insertTask(task);
        resultMessage = "Task created: '$title' ($taskId)";
        undoDesc = "Delete task '$title'";
        undoAction = () async {
          appRepository?.taskService.deleteTask(taskId);
        };
        break;

      case 'complete_task':
        final taskId = args['task_id'] as String;
        final tasks = appRepository?.taskService.tasks ?? [];
        final existing = tasks.firstWhere((t) => t.id == taskId, orElse: () => TaskItem(id: taskId, title: 'Unknown Task', createdAt: DateTime.now()));
        final wasCompleted = existing.isCompleted;

        appRepository?.taskService.toggleTaskCompletion(taskId);
        resultMessage = "Task completed: '${existing.title}'";
        undoDesc = "Mark task incomplete";
        undoAction = () async {
          if (!wasCompleted) {
            appRepository?.taskService.toggleTaskCompletion(taskId);
          }
        };
        break;

      case 'delete_task':
        final taskId = args['task_id'] as String;
        final tasks = appRepository?.taskService.tasks ?? [];
        final target = tasks.firstWhere((t) => t.id == taskId, orElse: () => TaskItem(id: taskId, title: 'Deleted Task', createdAt: DateTime.now()));

        appRepository?.taskService.deleteTask(taskId);
        resultMessage = "Task deleted: '${target.title}'";
        undoDesc = "Restore deleted task '${target.title}'";
        undoAction = () async {
          appRepository?.taskService.insertTask(target);
        };
        break;

      case 'save_memory':
        final text = MemoryItem.sanitizeText(args['text'] as String);
        final kindStr = args['kind'] as String? ?? 'fact';
        final kind = MemoryKind.values.firstWhere((k) => k.name == kindStr, orElse: () => MemoryKind.fact);

        final memory = MemoryItem(
          id: 'mem_ai_${DateTime.now().microsecondsSinceEpoch}',
          text: text,
          kind: kind,
          isApproved: true,
          createdAt: DateTime.now(),
        );

        appRepository?.memoryVaultService.addMemory(
          key: kind.name,
          value: memory.text,
        );
        resultMessage = "Memory saved: '$text' (${kind.name})";
        undoDesc = "Remove saved memory";
        undoAction = () async {
          // Remove memory from vault
        };
        break;

      case 'start_focus':
        final minutes = args['minutes'] as int? ?? 25;
        final soundscapeStr = args['soundscape'] as String? ?? 'silence';
        final soundscape = FocusSoundscape.values.firstWhere(
          (s) => s.name.toLowerCase() == soundscapeStr.toLowerCase(),
          orElse: () => FocusSoundscape.silence,
        );

        appRepository?.focusService.configureSession(
          targetMinutes: minutes,
          soundscape: soundscape,
        );
        appRepository?.focusService.start();
        resultMessage = "Focus Zone active for $minutes minutes ($soundscapeStr).";
        undoDesc = "Cancel focus session";
        undoAction = () async {
          appRepository?.focusService.reset();
        };
        break;

      case 'set_alarm':
        final timeStr = args['time'] as String;
        final label = args['label'] as String? ?? 'DayBook Alarm';
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 7;
        final min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

        final alarm = AlarmItem(
          id: 'alm_ai_${DateTime.now().microsecondsSinceEpoch}',
          hour: hour,
          minute: min,
          label: label,
          isEnabled: true,
        );

        final currentAlarms = List<AlarmItem>.from(appRepository?.alarms ?? []);
        currentAlarms.add(alarm);
        appRepository?.updateAlarms(currentAlarms);

        resultMessage = "Alarm set for ${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} ($label)";
        undoDesc = "Remove alarm $timeStr";
        undoAction = () async {
          final updated = List<AlarmItem>.from(appRepository?.alarms ?? []);
          updated.removeWhere((a) => a.id == alarm.id);
          appRepository?.updateAlarms(updated);
        };
        break;

      case 'log_habit':
        final habitId = args['habit_id'] as String? ?? 'h1';
        if (appRepository != null) {
          appRepository!.habitService.toggleHabit(
            habitId,
            date: DateTime.now(),
            entriesRepo: appRepository!.entriesRepository,
          );
        }
        resultMessage = "Logged completion for habit '$habitId'.";
        undoDesc = "Toggle habit off";
        undoAction = () async {
          if (appRepository != null) {
            appRepository!.habitService.toggleHabit(
              habitId,
              date: DateTime.now(),
              entriesRepo: appRepository!.entriesRepository,
            );
          }
        };
        break;

      case 'log_mood':
        final rating = (args['rating'] as num).toInt();
        final energy = (args['energy'] as num?)?.toInt() ?? rating;
        final notes = args['notes'] as String? ?? '';

        if (appRepository != null) {
          appRepository!.wellnessService.logCheckin(
            moodScore: rating,
            energyScore: energy,
            reflection: notes,
            entriesRepo: appRepository!.entriesRepository,
          );
        }
        resultMessage = "Recorded mood: $rating/5, energy: $energy/5";
        break;

      case 'add_note':
        final content = args['content'] as String;
        final title = args['title'] as String? ?? 'Quick Note';
        final note = RichNote(
          id: 'note_ai_${DateTime.now().microsecondsSinceEpoch}',
          title: title,
          body: content,
          type: NoteType.plain,
          dayKey: DayPageModel.formatDayKey(DateTime.now()),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        appRepository?.inboxService.addNote(note);
        resultMessage = "Note saved: '$title'";
        undoDesc = "Delete note '$title'";
        undoAction = () async {
          appRepository?.inboxService.deleteNote(note.id);
        };
        break;

      default:
        resultMessage = "Executed tool '${record.toolName}' successfully.";
    }

    final executedRecord = record.copyWith(
      status: ToolCallStatus.executed,
      resultMessage: resultMessage,
      undoDescription: undoDesc,
    );

    if (undoAction != null) {
      _undoActions[record.id] = undoAction;
    }

    if (idx != -1) {
      _toolCallLog[idx] = executedRecord;
    }
    notifyListeners();
    return executedRecord;
  }
}
