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

class AppRepository extends ChangeNotifier {
  final TaskService taskService = TaskService();
  final MemoryVaultService memoryVaultService = MemoryVaultService();

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
        subtasks: const [
          SubtaskItem(id: 'st_1', title: 'Check AlarmReceiver broadcast intent', isCompleted: true),
          SubtaskItem(id: 'st_2', title: 'Verify Wakelock foreground service', isCompleted: true),
          SubtaskItem(id: 'st_3', title: 'Unit test Math & Memory challenges', isCompleted: false),
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      TaskItem(
        id: 'task_seed_2',
        title: 'CSE246: Dynamic Programming Practice',
        notes: 'Solve Longest Common Subsequence and Knapsack variants',
        category: 'Study',
        priority: TaskPriority.importantNotUrgent,
        estimatedMinutes: 60,
        dueAt: DateTime(now.year, now.month, now.day, 21, 0),
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      TaskItem(
        id: 'task_seed_3',
        title: 'Brisk 5km Evening Jog & Hydration',
        notes: 'Maintain 5-day fitness consistency streak',
        category: 'Health',
        priority: TaskPriority.urgentNotImportant,
        estimatedMinutes: 35,
        dueAt: DateTime(now.year, now.month, now.day, 17, 30),
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      TaskItem(
        id: 'task_seed_4',
        title: 'Buy Green Tea & Fresh Almonds',
        category: 'Personal',
        priority: TaskPriority.neither,
        estimatedMinutes: 15,
        status: TaskStatus.completed,
        completedAt: now.subtract(const Duration(minutes: 40)),
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ]);

    // 2. Seed Smart Alarms
    alarms = [
      const AlarmItem(
        id: 'alm_seed_1',
        hour: 6,
        minute: 30,
        label: 'Sunrise Productivity Wake-Up',
        isEnabled: true,
        repeatDays: [1, 2, 3, 4, 5],
        challengeType: AlarmChallengeType.math,
        difficulty: ChallengeDifficulty.medium,
        ringtone: 'Sunrise Symphony',
      ),
      const AlarmItem(
        id: 'alm_seed_2',
        hour: 7,
        minute: 15,
        label: 'Bathroom QR Code Verification',
        isEnabled: true,
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
        challengeType: AlarmChallengeType.qrScan,
        difficulty: ChallengeDifficulty.hard,
        qrHash: 'bathroom_sink_target',
      ),
    ];

    // 3. Seed Plan Blocks
    planBlocks = [
      const DailyPlanBlock(
        id: 'dpb_seed_1',
        title: 'Deep Engineering Session',
        startHour: 9,
        startMinute: 0,
        endHour: 10,
        endMinute: 30,
        category: 'Work',
      ),
      const DailyPlanBlock(
        id: 'dpb_seed_2',
        title: 'Algorithms & Course Review',
        startHour: 11,
        startMinute: 0,
        endHour: 12,
        endMinute: 15,
        category: 'Study',
      ),
    ];

    // 4. Seed Personal Memories
    memoryVaultService.loadMemories([
      PersonalMemory(
        id: 'mem_seed_1',
        key: 'preferred_wake_time',
        value: '6:30 AM on weekdays, 7:30 AM on weekends',
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
  }
}

