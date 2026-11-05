import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/memory_item.dart';
import '../models/chat_and_memory.dart';
import 'assistant_tool_engine.dart';
import 'ask_your_past_service.dart';
import '../../data/app_repository.dart';

class ProactiveSuggestion {
  final String id;
  final String title;
  final String message;
  final String? actionTool;
  final Map<String, dynamic>? actionArgs;
  final DateTime date;

  const ProactiveSuggestion({
    required this.id,
    required this.title,
    required this.message,
    this.actionTool,
    this.actionArgs,
    required this.date,
  });
}

class AIAssistantService extends ChangeNotifier {
  final AppRepository appRepository;
  final AssistantToolEngine toolEngine;
  late final AskYourPastService askYourPastService;

  bool isAiEnabled = true;
  bool allowMorningSuggestions = true;
  bool allowFocusSuggestions = true;
  bool allowEveningSuggestions = true;

  final List<MemoryItem> _memories = [];
  final List<ProactiveSuggestion> _suggestions = [];

  AIAssistantService({
    required this.appRepository,
    required this.toolEngine,
  }) {
    askYourPastService = AskYourPastService(appRepository: appRepository);
    _initializeDefaultMemories();
  }

  List<MemoryItem> get memories => List.unmodifiable(_memories);
  List<MemoryItem> get pinnedMemories => _memories.where((m) => m.isPinned).toList();
  List<ProactiveSuggestion> get activeSuggestions => List.unmodifiable(_suggestions);

  void toggleAiMasterSwitch(bool enabled) {
    isAiEnabled = enabled;
    notifyListeners();
  }

  void _initializeDefaultMemories() {
    _memories.addAll([
      MemoryItem(
        id: 'mem_1',
        text: 'Prefers 25-minute Pomodoro sessions with Rain soundscape',
        kind: MemoryKind.preference,
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MemoryItem(
        id: 'mem_2',
        text: 'Morning wake quest targets 06:30 with Simon Memory challenge',
        kind: MemoryKind.fact,
        isPinned: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  // =========================================================================
  // MEMORY MANAGEMENT (CRUD, Pinned, Approval, Privacy Sanitation)
  // =========================================================================

  void addMemory(String rawText, {MemoryKind kind = MemoryKind.fact, bool isPinned = false}) {
    final sanitized = MemoryItem.sanitizeText(rawText);
    final item = MemoryItem(
      id: 'mem_${DateTime.now().microsecondsSinceEpoch}',
      text: sanitized,
      kind: kind,
      isPinned: isPinned,
      isApproved: true,
      createdAt: DateTime.now(),
    );
    _memories.insert(0, item);
    notifyListeners();
  }

  void togglePinMemory(String id) {
    final idx = _memories.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final item = _memories[idx];
      _memories[idx] = item.copyWith(isPinned: !item.isPinned);
      notifyListeners();
    }
  }

  void deleteMemory(String id) {
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void clearAllMemories() {
    _memories.clear();
    notifyListeners();
  }

  // =========================================================================
  // CONTEXT BUDGETING & PII REDACTION
  // =========================================================================

  /// Redacts sensitive patterns (phone numbers, emails, passwords)
  static String redactSensitiveData(String text) {
    var redacted = text;
    // Bangladesh & International phone numbers
    redacted = redacted.replaceAll(
      RegExp(r'(?:\+?88)?01[3-9]\d{8}'),
      '[PHONE_REDACTED]',
    );
    // Email addresses
    redacted = redacted.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL_REDACTED]',
    );
    // Passwords and API keys
    redacted = redacted.replaceAll(
      RegExp(r'(password|pin|secret|api_key)\s*[:=]\s*[^\s,;]+', caseSensitive: false),
      r'$1: [REDACTED]',
    );
    return redacted;
  }

  /// Builds a minimal, privacy-redacted context budget payload
  Map<String, dynamic> buildContextBudget() {
    final now = DateTime.now();
    final tasks = appRepository.taskService.tasks
        .where((t) => !t.isCompleted)
        .take(10)
        .map((t) => redactSensitiveData(t.title))
        .toList();

    final pinned = pinnedMemories
        .take(5)
        .map((m) => redactSensitiveData(m.text))
        .toList();

    return {
      'timestamp': now.toIso8601String(),
      'timezone': now.timeZoneName,
      'pending_tasks': tasks,
      'pinned_memories': pinned,
    };
  }

  // =========================================================================
  // PROACTIVE SUGGESTIONS (MAX 3 PER DAY, NO DARK PATTERNS)
  // =========================================================================

  void generateDailyProactiveSuggestions() {
    _suggestions.clear();
    final now = DateTime.now();

    // 1. Morning Planner suggestion
    if (allowMorningSuggestions && now.hour < 12) {
      _suggestions.add(ProactiveSuggestion(
        id: 'sug_morning_${now.day}',
        title: 'Morning Daily Plan',
        message: 'Plan your top 3 high-energy tasks for today.',
        actionTool: 'plan_day',
        actionArgs: {'date': now.toIso8601String()},
        date: now,
      ));
    }

    // 2. Focus Zone suggestion
    if (allowFocusSuggestions && _suggestions.length < 3) {
      final urgentTask = appRepository.taskService.tasks.where((t) => !t.isCompleted).firstOrNull;
      if (urgentTask != null) {
        _suggestions.add(ProactiveSuggestion(
          id: 'sug_focus_${now.day}',
          title: 'Deep Focus Opportunity',
          message: 'Start a 25-minute focus session for "${urgentTask.title}".',
          actionTool: 'start_focus',
          actionArgs: {'minutes': 25, 'taskId': urgentTask.id},
          date: now,
        ));
      }
    }

    // 3. Evening Reflection suggestion
    if (allowEveningSuggestions && now.hour >= 18 && _suggestions.length < 3) {
      _suggestions.add(ProactiveSuggestion(
        id: 'sug_evening_${now.day}',
        title: 'Evening Reflection & Mood Log',
        message: 'Log your energy and mood to complete today\'s Day Page.',
        actionTool: 'log_mood',
        actionArgs: {'rating': 5},
        date: now,
      ));
    }

    notifyListeners();
  }

  void dismissSuggestion(String id) {
    _suggestions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // =========================================================================
  // NATURAL LANGUAGE ASSISTANT / TOOL DISPATCHER (OFFLINE FALLBACK ENGINE)
  // =========================================================================

  /// Processes natural language user messages in Bangla, English, or Banglish
  Future<ChatMessage> processUserMessage(String userText, {bool isBangla = false}) async {
    final now = DateTime.now();

    // 1. If AI is toggled off, inform user that manual controls are active
    if (!isAiEnabled) {
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: isBangla
            ? "এআই ফিচার বর্তমানে বন্ধ রয়েছে। সেটিংস থেকে এটি চালু করতে পারেন। আপনি নিচের বাটন দিয়ে যেকোনো কাজ সরাসরি পরিচালনা করতে পারেন।"
            : "AI Assistant is currently turned off in settings. You can re-enable it anytime or use the manual controls.",
        timestamp: now,
      );
    }

    final lower = userText.toLowerCase().trim();

    // 2. Ask Your Past Detection ("when did i...", "how much spent", "what were my priorities", etc.)
    if (_isPastQuery(lower)) {
      final pastResult = await askYourPastService.askQuestion(userText, isBangla: isBangla);
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: pastResult.answer,
        targetDayKey: pastResult.targetDayKey,
        timestamp: now,
      );
    }

    // 3. Tool Intent Parsing (14 approved tools)
    // A. Create Task
    if (lower.startsWith('create task') || lower.startsWith('add task') || lower.startsWith('task:') ||
        lower.contains('kaj add koro') || lower.contains('কাজ যোগ করো') || lower.contains('notun kaj')) {
      final title = _extractCleanText(userText, ['create task', 'add task', 'task:', 'kaj add koro', 'কাজ যোগ করো', 'notun kaj']);
      final record = await toolEngine.requestToolExecution(
        toolName: 'create_task',
        arguments: {'title': title.isNotEmpty ? title : 'New Task', 'priority': 'p2'},
      );
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: isBangla ? "টাস্ক তৈরি হয়েছে: **$title**" : "Task created: **$title**",
        toolRecordId: record.id,
        undoDescription: record.undoDescription,
        timestamp: now,
      );
    }

    // B. Start Focus
    if (lower.contains('start focus') || lower.contains('focus suru koro') || lower.contains('ফোকাস শুরু করো') || lower.contains('pomodoro')) {
      final record = await toolEngine.requestToolExecution(
        toolName: 'start_focus',
        arguments: {'minutes': 25, 'soundscape': 'rain'},
      );
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: isBangla
            ? "২৫ মিনিটের **Focus Zone** চালু করা হয়েছে (বৃষ্টির শব্দসহ)।"
            : "25-minute **Focus Zone** initiated with Rain soundscape.",
        toolRecordId: record.id,
        undoDescription: record.undoDescription,
        timestamp: now,
      );
    }

    // C. Set Alarm
    if (lower.contains('set alarm') || lower.contains('alarm dao') || lower.contains('অ্যালার্ম দাও') || lower.contains('wake me up')) {
      final time = _extractTime(lower) ?? '07:00';
      final record = await toolEngine.requestToolExecution(
        toolName: 'set_alarm',
        arguments: {'time': time, 'label': 'Wake Quest'},
      );
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: isBangla
            ? "$time এ **Wake Quest** অ্যালার্ম সেট করা হয়েছে।"
            : "Set **Wake Quest** alarm for **$time**.",
        toolRecordId: record.id,
        undoDescription: record.undoDescription,
        timestamp: now,
      );
    }

    // D. Save Memory
    if (lower.startsWith('remember that') || lower.startsWith('save memory') || lower.contains('mone rekho') || lower.contains('মনে রেখো')) {
      final text = _extractCleanText(userText, ['remember that', 'save memory', 'mone rekho', 'মনে রেখো']);
      addMemory(text, kind: MemoryKind.fact);
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: isBangla
            ? "স্মৃতিতে সংরক্ষণ করা হয়েছে: **$text**"
            : "Saved to your personal memories: **$text**",
        timestamp: now,
      );
    }

    // E. Log Mood / Energy
    if (lower.contains('log mood') || lower.contains('energy level') || lower.contains('mood bhalo') || lower.contains('মন ভালো নেই')) {
      final rating = lower.contains('kharap') || lower.contains('bad') || lower.contains('খারাপ') ? 2 : 4;
      final record = await toolEngine.requestToolExecution(
        toolName: 'log_mood',
        arguments: {'rating': rating, 'notes': userText},
      );
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: isBangla
            ? "মুড এবং এনার্জি লগ করা হয়েছে: **$rating/5**"
            : "Recorded your wellness check-in: **$rating/5**",
        toolRecordId: record.id,
        timestamp: now,
      );
    }

    // F. Log Habit
    if (lower.contains('done habit') || lower.contains('completed habit') || lower.contains('ovash sesh') || lower.contains('অভ্যাস পূরণ')) {
      final record = await toolEngine.requestToolExecution(
        toolName: 'log_habit',
        arguments: {'habit_id': 'h1'},
      );
      return ChatMessage(
        id: 'msg_ai_${now.microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: isBangla
            ? "আজকের অভ্যাসের অগ্রগতি সফলভাবে লগ করা হয়েছে! ❄️"
            : "Logged habit completion for today! ❄️",
        toolRecordId: record.id,
        undoDescription: record.undoDescription,
        timestamp: now,
      );
    }

    // G. Fallback Conversational Guidance
    return ChatMessage(
      id: 'msg_ai_${now.microsecondsSinceEpoch}',
      sender: MessageSender.assistant,
      content: isBangla
          ? "আমি DayBook Assistant। আপনি নতুন টাস্ক যোগ করতে পারেন, ফোকাস জোন শুরু করতে পারেন, বা অতীতে কী হয়েছিল তা জানতে চাইতে পারেন (যেমন: 'গত শুক্রবারে আমি কী পড়েছিলাম?')।"
          : "I am your DayBook Assistant. You can ask me to create tasks, start deep focus, set alarms, save memories, or ask questions about your past entries (e.g. 'When was the last time I studied networking?').",
      timestamp: now,
    );
  }

  bool _isPastQuery(String lower) {
    return lower.startsWith('when did') ||
        lower.startsWith('when was') ||
        lower.startsWith('how much') ||
        lower.startsWith('what did i') ||
        lower.startsWith('what were my') ||
        lower.contains('kobe ami') ||
        lower.contains('kobe korechilam') ||
        lower.contains('কবে আমি') ||
        lower.contains('আগে কী হয়েছিল');
  }

  String _extractCleanText(String text, List<String> prefixes) {
    var result = text;
    for (final p in prefixes) {
      if (result.toLowerCase().startsWith(p)) {
        result = result.substring(p.length).trim();
      }
    }
    return result.replaceAll(RegExp(r'^[:\-\s]+'), '').trim();
  }

  String? _extractTime(String lower) {
    final match = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b').firstMatch(lower);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int min = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final ampm = match.group(3);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
    }
    return null;
  }
}
