import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/enums/core_enums.dart';
import 'core/localization/app_localizations.dart';
import 'data/app_repository.dart';
import 'domain/services/briefing_service.dart';
import 'presentation/widgets/sky_canvas.dart';
import 'presentation/widgets/daily_progress_ring.dart';
import 'presentation/widgets/briefing_sheets.dart';
import 'presentation/screens/tasks_screen.dart';
import 'presentation/screens/planner_screen.dart';
import 'presentation/screens/alarm_screen.dart';
import 'presentation/screens/assistant_screen.dart';
import 'presentation/screens/memory_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DaybookRootApp());
}

class DaybookRootApp extends StatefulWidget {
  const DaybookRootApp({super.key});

  @override
  State<DaybookRootApp> createState() => _DaybookRootAppState();
}

class _DaybookRootAppState extends State<DaybookRootApp> {
  late final AppRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = AppRepository()..addListener(_onRepositoryUpdated);
  }

  void _onRepositoryUpdated() {
    setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryUpdated);
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _repository.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          primary: const Color(0xFF818CF8),
          secondary: const Color(0xFF34D399),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: DaybookShell(repository: _repository),
    );
  }
}

class DaybookShell extends StatefulWidget {
  final AppRepository repository;

  const DaybookShell({super.key, required this.repository});

  @override
  State<DaybookShell> createState() => _DaybookShellState();
}

class _DaybookShellState extends State<DaybookShell> {
  int _currentIndex = 0;

  void _openMorningBriefing() {
    final briefing = BriefingService.generateMorningBriefing(
      tasks: widget.repository.taskService.getTodayTasks(),
      weather: widget.repository.weatherState,
      firstAlarm: widget.repository.alarms.isNotEmpty ? widget.repository.alarms.first : null,
      isBangla: widget.repository.isBangla,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => MorningBriefingSheet(
        briefing: briefing,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openEveningReview() {
    final todayTasks = widget.repository.taskService.getTodayTasks();
    final completed = todayTasks.where((t) => t.isCompleted).length;
    final pending = todayTasks.where((t) => !t.isCompleted).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => EveningReviewSheet(
        completedCount: completed,
        pendingCount: pending,
        onSubmit: (mood, notes) {
          BriefingService.generateEveningReview(
            allTasks: todayTasks,
            moodScore: mood,
            notes: notes,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evening reflection recorded. Rest well!')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    final locale = AppLocale(isBangla: repo.isBangla);

    final screens = [
      _buildHomeDashboard(repo, locale),
      TasksScreen(
        taskService: repo.taskService,
        onDataChanged: repo.notifyDataChanged,
      ),
      PlannerScreen(
        planBlocks: repo.planBlocks,
        taskService: repo.taskService,
        onBlocksUpdated: repo.updatePlanBlocks,
      ),
      AlarmScreen(
        alarms: repo.alarms,
        onAlarmsUpdated: repo.updateAlarms,
      ),
      AssistantScreen(
        messages: repo.chatMessages,
        taskService: repo.taskService,
        onSendMessage: repo.addChatMessage,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny),
            label: locale.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: locale.tasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: locale.planner,
          ),
          NavigationDestination(
            icon: const Icon(Icons.alarm_outlined),
            selectedIcon: const Icon(Icons.alarm),
            label: locale.alarms,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: locale.assistant,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(AppRepository repo, AppLocale locale) {
    final todayTasks = repo.taskService.getTodayTasks();
    final completedCount = todayTasks.where((t) => t.isCompleted).length;
    final totalCount = todayTasks.length;
    final skyPhase = repo.weatherState.getSkyPhase();

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Dynamic Living Sky Canvas
          WeatherSkyBackground(
            phase: skyPhase,
            condition: repo.weatherState.condition,
            height: 220,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.appTitle,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${repo.weatherState.cityName} • ${repo.weatherState.temperatureC.toStringAsFixed(1)}°C • ${skyPhase.name.toUpperCase()}',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.psychology, color: Colors.white),
                              tooltip: 'Memory Vault',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MemoryScreen(
                                      vaultService: repo.memoryVaultService,
                                      onDataChanged: repo.notifyDataChanged,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white),
                              tooltip: 'Settings',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SettingsScreen(repository: repo),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Morning Briefing / Evening Review Launch Button
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openMorningBriefing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.wb_sunny, size: 16, color: Color(0xFFD97706)),
                          label: Text(locale.morningBriefing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _openEveningReview,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.nights_stay, size: 16),
                          label: Text(locale.eveningReflection, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 2. Daily Progress Ring
          DailyProgressRing(
            completedTasks: completedCount,
            totalTasks: totalCount,
            wakeHour: repo.wakeHour,
            wakeMinute: repo.wakeMinute,
            sleepHour: repo.sleepHour,
            sleepMinute: repo.sleepMinute,
          ),
          // 3. Quick Action shortcuts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => setState(() => _currentIndex = 1), // Tasks
                    icon: const Icon(Icons.add_task, size: 18),
                    label: Text(locale.newTask),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => setState(() => _currentIndex = 2), // Planner
                    icon: const Icon(Icons.bolt, size: 18),
                    label: Text(locale.autoPlan),
                  ),
                ),
              ],
            ),
          ),
          // 4. Focus Priorities Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Eisenhower Mission Tasks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          // 5. Top 3 Tasks preview
          if (todayTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('All tasks completed! Enjoy your day.'),
            )
          else
            ...todayTasks.take(3).map((task) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: task.isCompleted ? Colors.green : const Color(0xFF6366F1),
                      ),
                      onPressed: () {
                        repo.taskService.toggleTaskCompletion(task.id);
                        repo.notifyDataChanged();
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text(
                            '${task.category} • ${task.estimatedMinutes}m • ${task.priority.label.split(':').first}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
