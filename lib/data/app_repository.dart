import 'package:flutter/material.dart';
import '../core/enums/core_enums.dart';
import '../core/enums/task_priority.dart';
import '../domain/models/task_item.dart';
import '../domain/models/subtask_item.dart';
import '../domain/models/alarm_item.dart';
import '../domain/models/daily_plan_block.dart';
import '../domain/models/chat_and_memory.dart';
import '../domain/models/weather_and_briefing.dart';
import '../domain/services/task_service.dart';
import '../domain/services/memory_vault_service.dart';
import 'repositories/entries_repository.dart';
import 'repositories/tasks_and_goals_repository.dart';
import '../domain/services/inbox_service.dart';

class AppRepository extends ChangeNotifier {
  final TaskService taskService = TaskService();
  final MemoryVaultService memoryVaultService = MemoryVaultService();
  final EntriesRepository entriesRepository = EntriesRepository();
  final TasksAndGoalsRepository tasksAndGoalsRepository = TasksAndGoalsRepository();
  final InboxService inboxService = InboxService();

  List<AlarmItem> alarms = [];
  List<DailyPlanBlock> planBlocks = [];
  List<ChatMessage> chatMessages = [];
  WeatherState weatherState = WeatherState(lastUpdated: DateTime.now());

  // Settings
  bool isBangla = false;
  ThemeMode themeMode = ThemeMode.system;
  int wakeHour = 6;
  int wakeMinute = 30;
  int sleepHour = 23;
  int sleepMinute = 0;
  String selectedCity = 'Dhaka';

  AppRepository() {
    _initializeSeedData();
  }

  void toggleLanguage() {
    isBangla = !isBangla;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void updateAlarms(List<AlarmItem> newAlarms) {
    alarms = List.from(newAlarms);
    notifyListeners();
  }

  void updatePlanBlocks(List<DailyPlanBlock> newBlocks) {
    planBlocks = List.from(newBlocks);
    notifyListeners();
  }

  void addChatMessage(ChatMessage msg) {
    chatMessages.add(msg);
    notifyListeners();
  }

  void notifyDataChanged() {
    notifyListeners();
  }

  void _initializeSeedData() {
    final now = DateTime.now();

    // 1. Seed Tasks
    taskService.loadTasks([
      TaskItem(
        id: 'task_seed_1',
        title: 'Review Daybook Architecture & Platform Channels',
        notes: 'Verify Kotlin AlarmManager and on-device ML Vision hooks',
        category: 'Work',
        priority: TaskPriority.urgentImportant,
        estimatedMinutes: 45,
        dueAt: DateTime(now.year, now.month, now.day, 18, 0),
        createdAt: now.subtract(const Duration(hours: 2)),
        subtasks: const [
          SubtaskItem(id: 'st_1', title: 'Check AlarmReceiver broadcast intent', isCompleted: true),
          SubtaskItem(id: 'st_2', title: 'Verify Wakelock foreground service', isCompleted: true),
          SubtaskItem(id: 'st_3', title: 'Unit test Math & Memory challenges', isCompleted: false),
        ],
      ),
      TaskItem(
        id: 'task_seed_2',
        title: 'Complete 30-minute English or Bangla Journal Entry',
        notes: 'Reflect on morning productivity and energy levels',
        category: 'Personal',
        priority: TaskPriority.importantNotUrgent,
        estimatedMinutes: 30,
        dueAt: DateTime(now.year, now.month, now.day, 21, 0),
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      TaskItem(
        id: 'task_seed_3',
        title: 'Drink 2.5 Liters of Water',
        category: 'Health',
        priority: TaskPriority.neither,
        estimatedMinutes: 10,
        status: TaskStatus.completed,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ]);

    // 2. Seed Alarms
    alarms = [
      AlarmItem(
        id: 'alarm_primary',
        label: 'Wake Quest: Focus Ascent',
        hour: wakeHour,
        minute: wakeMinute,
        isEnabled: true,
        challengeType: AlarmChallengeType.math,
        difficulty: ChallengeDifficulty.hard,
        minSteps: 30,
        snoozeAllowed: true,
      ),
      const AlarmItem(
        id: 'alarm_power_nap',
        label: 'Afternoon Recharge (20m)',
        hour: 14,
        minute: 30,
        isEnabled: false,
        challengeType: AlarmChallengeType.math,
        difficulty: ChallengeDifficulty.easy,
        snoozeAllowed: true,
      ),
    ];

    // 3. Seed Plan Blocks
    planBlocks = const [
      DailyPlanBlock(
        id: 'block_morning_routine',
        title: 'Morning Awakening & Wake Quest',
        startHour: 6,
        startMinute: 30,
        endHour: 7,
        endMinute: 30,
        category: 'Routine',
      ),
      DailyPlanBlock(
        id: 'block_deep_work_1',
        title: 'Deep Architecture & Kotlin Alarm Engine',
        startHour: 9,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        category: 'Focus',
      ),
      DailyPlanBlock(
        id: 'block_rest',
        title: 'Lunch, Rest & Sunlight Walk',
        startHour: 12,
        startMinute: 30,
        endHour: 13,
        endMinute: 30,
        category: 'Rest',
      ),
    ];

    // 4. Seed Memory Vault
    memoryVaultService.loadMemories([
      PersonalMemory(
        id: 'mem_seed_1',
        key: 'preferred_wake_time',
        value: '6:30 AM wake with Math challenge',
        kind: MemoryKind.preference,
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PersonalMemory(
        id: 'mem_seed_2',
        key: 'focus_work_rhythm',
        value: 'Peak cognitive energy between 9:00 AM and 1:00 PM',
        kind: MemoryKind.fact,
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PersonalMemory(
        id: 'mem_seed_3',
        key: 'current_goal',
        value: 'Ship complete Daybook application with high reliability',
        kind: MemoryKind.preference,
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // 5. Seed Assistant Chat
    chatMessages = [
      ChatMessage(
        id: 'msg_welcome',
        sender: MessageSender.assistant,
        content: 'Welcome to Daybook! শুভ সকাল। I am your personal life operating system. Your tasks, smart alarms, and daily plan are synchronized locally and ready for action.',
        timestamp: now.subtract(const Duration(minutes: 10)),
      ),
    ];

    // 6. Seed Simulated Month for Part 2 Verification
    entriesRepository.seedSimulatedMonth(now.year, now.month);
  }
}
