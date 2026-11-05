import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/data/app_repository.dart';
import 'package:daybook/domain/models/journal_entry.dart';
import 'package:daybook/domain/models/memory_item.dart';
import 'package:daybook/domain/models/task_item.dart';
import 'package:daybook/domain/models/tool_call_item.dart';
import 'package:daybook/domain/services/assistant_tool_engine.dart';
import 'package:daybook/domain/services/ask_your_past_service.dart';
import 'package:daybook/domain/services/ai_assistant_service.dart';
import 'package:daybook/presentation/screens/assistant_screen.dart';
import 'package:daybook/presentation/screens/memory_screen.dart';

void main() {
  group('PART 8 — Assistant Tool Engine & Confirmation Gate Tests', () {
    late AppRepository appRepo;
    late AssistantToolEngine toolEngine;

    setUp(() {
      appRepo = AppRepository();
      toolEngine = AssistantToolEngine(appRepository: appRepo);
    });

    test('Allowlisted safe tools execute immediately', () async {
      final record = await toolEngine.requestToolExecution(
        toolName: 'create_task',
        arguments: {'title': 'Study Operating Systems', 'priority': 'p1'},
      );

      expect(record.status, ToolCallStatus.executed);
      expect(record.resultMessage, contains("Task created: 'Study Operating Systems'"));
      expect(toolEngine.toolCallLog.length, 1);

      // Verify task actually created in domain service
      final tasks = appRepo.taskService.tasks;
      expect(tasks.any((t) => t.title == 'Study Operating Systems'), isTrue);
    });

    test('Non-allowlisted tools are blocked immediately with zero execution', () async {
      final record = await toolEngine.requestToolExecution(
        toolName: 'drop_database_tables',
        arguments: {'target': 'all'},
      );

      expect(record.status, ToolCallStatus.rejected);
      expect(record.resultMessage, contains("not in the approved allowlist"));
    });

    test('Destructive actions require explicit confirmation gate', () async {
      final record = await toolEngine.requestToolExecution(
        toolName: 'delete_task',
        arguments: {'task_id': 'task_seed_1'},
      );

      expect(record.status, ToolCallStatus.proposed);
      expect(record.isDestructive, isTrue);
      expect(record.needsConfirmation, isTrue);

      // Confirm tool call
      final confirmed = await toolEngine.confirmAndExecute(record.id);
      expect(confirmed.status, ToolCallStatus.executed);
      expect(confirmed.resultMessage, contains("Task deleted"));
    });

    test('User can reject a proposed destructive tool call', () async {
      final record = await toolEngine.requestToolExecution(
        toolName: 'delete_task',
        arguments: {'task_id': 'task_seed_2'},
      );

      expect(record.status, ToolCallStatus.proposed);

      final rejected = toolEngine.rejectToolCall(record.id);
      expect(rejected.status, ToolCallStatus.rejected);
      expect(rejected.resultMessage, contains("Action rejected by user"));
    });

    test('Undo stack reverses executed actions cleanly', () async {
      final record = await toolEngine.requestToolExecution(
        toolName: 'create_task',
        arguments: {'title': 'Temporary Draft Task', 'priority': 'p3'},
      );
      expect(record.status, ToolCallStatus.executed);

      final undone = await toolEngine.undoToolCall(record.id);
      expect(undone, isTrue);

      // Verify task is removed
      final tasks = appRepo.taskService.tasks;
      expect(tasks.any((t) => t.title == 'Temporary Draft Task'), isFalse);
    });
  });

  group('PART 8 — Memory Vault & Privacy Sanitization Tests', () {
    test('MemoryItem sanitizes passwords and credit card identifiers', () {
      const raw = "My password is SuperSecret123 and card is 4111 2222 3333 4444";
      final sanitized = MemoryItem.sanitizeText(raw);

      expect(sanitized.contains('SuperSecret123'), isFalse);
      expect(sanitized.contains('4111 2222 3333 4444'), isFalse);
      expect(sanitized, contains('[REDACTED]'));
      expect(sanitized, contains('[CARD_REDACTED]'));
    });

    test('AIAssistantService manages memory CRUD, pin and clear all', () {
      final repo = AppRepository();
      final toolEngine = AssistantToolEngine(appRepository: repo);
      final aiService = AIAssistantService(appRepository: repo, toolEngine: toolEngine);

      aiService.addMemory("Prefers working in monochrome theme", kind: MemoryKind.preference);
      expect(aiService.memories.any((m) => m.text.contains("monochrome")), isTrue);

      final added = aiService.memories.first;
      aiService.togglePinMemory(added.id);
      expect(aiService.pinnedMemories.any((m) => m.id == added.id), isTrue);

      aiService.deleteMemory(added.id);
      expect(aiService.memories.any((m) => m.id == added.id), isFalse);

      aiService.clearAllMemories();
      expect(aiService.memories.isEmpty, isTrue);
    });
  });

  group('PART 8 — Context Budgeting & Redaction Tests', () {
    test('Context budgeting caps length and redacts PII', () {
      final repo = AppRepository();
      final toolEngine = AssistantToolEngine(appRepository: repo);
      final aiService = AIAssistantService(appRepository: repo, toolEngine: toolEngine);

      // Add a task with personal info
      repo.taskService.insertTask(TaskItem(
        id: 't_pii',
        title: 'Call developer at +8801712345678 or dev@test.com',
        createdAt: DateTime.now(),
      ));

      final contextBudget = aiService.buildContextBudget();

      expect(contextBudget.containsKey('timestamp'), isTrue);
      expect(contextBudget.containsKey('timezone'), isTrue);
      expect(contextBudget.containsKey('pending_tasks'), isTrue);

      final tasks = contextBudget['pending_tasks'] as List;
      final piiTask = tasks.firstWhere((t) => t.toString().contains('Call developer'));

      expect(piiTask.toString().contains('+8801712345678'), isFalse);
      expect(piiTask.toString().contains('dev@test.com'), isFalse);
      expect(piiTask.toString(), contains('[PHONE_REDACTED]'));
      expect(piiTask.toString(), contains('[EMAIL_REDACTED]'));
    });
  });

  group('PART 8 — Ask Your Past: Bangla Conjunct-Safe Retrieval Tests', () {
    late AppRepository repo;
    late AskYourPastService askPast;

    setUp(() {
      repo = AppRepository();
      askPast = AskYourPastService(appRepository: repo);

      // Seed journal entries for retrieval
      repo.entriesRepository.insertEntry(JournalEntry(
        id: 'ent_past_1',
        type: EntryType.manualNote,
        ts: DateTime(2026, 11, 4, 14, 0),
        dayKey: '2026-11-04',
        payload: {
          'title': 'Computer Networking Lab Session',
          'note': 'Configured OSPF routing protocols and studied packet flow.',
        },
      ));

      repo.entriesRepository.insertEntry(JournalEntry(
        id: 'ent_past_2',
        type: EntryType.manualNote,
        ts: DateTime(2026, 11, 3, 11, 0),
        dayKey: '2026-11-03',
        payload: {
          'title': 'জাভাস্ক্রিপ্ট প্রোজেক্ট পর্যালোচনা',
          'note': 'ফ্লাটার এবং রিভারপড দিয়ে স্টেট ম্যানেজমেন্টের কাজ শেষ করেছি।',
        },
      ));
    });

    test('Tokenizes Bangla conjuncts and vowel marks without breakage', () {
      const banglaText = "জাভাস্ক্রিপ্ট এবং বিজ্ঞান প্রজেক্ট";
      final tokens = AskYourPastService.tokenize(banglaText);

      expect(tokens, contains("জাভাস্ক্রিপ্ট"));
      expect(tokens, contains("বিজ্ঞান"));
      expect(tokens, contains("প্রজেক্ট"));
    });

    test('English natural question returns exact grounded answer with Day Page key', () async {
      final result = await askPast.askQuestion("When did I last study networking?");

      expect(result.hasResults, isTrue);
      expect(result.answer, contains("Computer Networking Lab Session"));
      expect(result.targetDayKey, isNotNull);
      expect(result.matchedEntries.length, 1);
    });

    test('Bangla query returns exact answer with conjunct matching', () async {
      final result = await askPast.askQuestion("কবে আমি জাভাস্ক্রিপ্ট নিয়ে কাজ করেছিলাম?", isBangla: true);

      expect(result.hasResults, isTrue);
      expect(result.answer, contains("জাভাস্ক্রিপ্ট প্রোজেক্ট পর্যালোচনা"));
      expect(result.targetDayKey, isNotNull);
    });

    test('Query with no matches returns honest response without fabrication', () async {
      final result = await askPast.askQuestion("When was the last time I had fever or flu?");

      expect(result.hasResults, isFalse);
      expect(result.matchedEntries.isEmpty, isTrue);
      expect(result.answer, contains("No records found"));
    });
  });

  group('PART 8 — Proactive Suggestions & AI Master Switch Tests', () {
    test('Proactive suggestions are capped at 3 per day and can be dismissed', () {
      final repo = AppRepository();
      final toolEngine = AssistantToolEngine(appRepository: repo);
      final aiService = AIAssistantService(appRepository: repo, toolEngine: toolEngine);

      aiService.generateDailyProactiveSuggestions();
      expect(aiService.activeSuggestions.length <= 3, isTrue);

      if (aiService.activeSuggestions.isNotEmpty) {
        final firstId = aiService.activeSuggestions.first.id;
        aiService.dismissSuggestion(firstId);
        expect(aiService.activeSuggestions.any((s) => s.id == firstId), isFalse);
      }
    });

    test('When AI is toggled off, returns clear guidance without auto tool dispatch', () async {
      final repo = AppRepository();
      final toolEngine = AssistantToolEngine(appRepository: repo);
      final aiService = AIAssistantService(appRepository: repo, toolEngine: toolEngine);

      aiService.toggleAiMasterSwitch(false);
      final reply = await aiService.processUserMessage("Add task: Buy groceries");

      expect(reply.content, contains("AI Assistant is currently turned off"));
      expect(toolEngine.toolCallLog.isEmpty, isTrue);
    });
  });

  group('PART 8 — Presentation Smoke Tests', () {
    testWidgets('AssistantScreen renders header, suggestions, and input field without overflow', (tester) async {
      final repo = AppRepository();

      await tester.pumpWidget(MaterialApp(
        home: AssistantScreen(
          assistantService: repo.aiAssistantService,
          toolEngine: repo.assistantToolEngine,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DayBook Assistant'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
    });

    testWidgets('MemoryScreen renders filter chips and add button without overflow', (tester) async {
      final repo = AppRepository();

      await tester.pumpWidget(MaterialApp(
        home: MemoryScreen(
          assistantService: repo.aiAssistantService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Personal Memory Vault'), findsOneWidget);
      expect(find.text('Fact'), findsOneWidget);
      expect(find.text('Preference'), findsOneWidget);
      expect(find.text('Episodic'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
