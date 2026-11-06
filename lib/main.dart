import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/app_tokens.dart';
import 'core/design/app_typography.dart';
import 'core/design/component_gallery.dart';
import 'data/app_repository.dart';
import 'presentation/screens/tasks_screen.dart';
import 'presentation/screens/planner_screen.dart';
import 'presentation/screens/alarm_screen.dart';
import 'presentation/screens/assistant_screen.dart';
import 'presentation/screens/memory_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/book_screen.dart';
import 'presentation/screens/day_page_screen.dart';
import 'presentation/widgets/sky_canvas.dart';
import 'presentation/widgets/daily_progress_ring.dart';
import 'presentation/widgets/briefing_sheets.dart';
import 'presentation/widgets/universal_quick_capture_sheet.dart';
import 'presentation/widgets/wellness_modal.dart';
import 'presentation/screens/inbox_screen.dart';
import 'presentation/screens/habits_screen.dart';
import 'presentation/screens/focus_screen.dart';
import 'presentation/screens/money_screen.dart';
import 'presentation/screens/people_screen.dart';
import 'presentation/screens/student_screen.dart';
import 'domain/services/briefing_service.dart';
import 'domain/models/weather_info.dart';
import 'domain/services/planner_algorithm.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DayBookApp()));
}

class DayBookApp extends StatefulWidget {
  const DayBookApp({super.key});

  @override
  State<DayBookApp> createState() => _DayBookAppState();
}

class _DayBookAppState extends State<DayBookApp> {
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
    // Part 1 Invariant: Pure OLED Black with Lime Accents
    return MaterialApp(
      title: 'DayBook',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Pure OLED black theme only
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        canvasColor: AppColors.bg,
        cardColor: AppColors.surface1,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentLime,
          onPrimary: AppColors.textOnLime,
          surface: AppColors.surface1,
          onSurface: AppColors.textPrimary,
          outline: AppColors.border,
          error: AppColors.errorRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.screenTitle,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface1,
          indicatorColor: AppColors.accentLime.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 11);
            }
            return const TextStyle(color: AppColors.textSecondary, fontSize: 11);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.accentLime);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
        ),
      ),
      home: DayBookShell(repository: _repository),
    );
  }
}

class DayBookShell extends StatefulWidget {
  final AppRepository repository;

  const DayBookShell({super.key, required this.repository});

  @override
  State<DayBookShell> createState() => _DayBookShellState();
}

class _DayBookShellState extends State<DayBookShell> {
  int _currentIndex = 0;
  final Set<String> _quickHabitsCompleted = {};
  String _selectedMood = '⚡ High Energy';

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
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        side: BorderSide(color: AppColors.border),
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
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        side: BorderSide(color: AppColors.border),
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
        },
      ),
    );
  }

  void _openQuickCaptureModal() {
    UniversalQuickCaptureSheet.show(
      context,
      isBangla: widget.repository.isBangla,
      inboxService: widget.repository.inboxService,
      tasksRepo: widget.repository.tasksAndGoalsRepository,
      entriesRepo: widget.repository.entriesRepository,
      onSaved: () {
        widget.repository.notifyDataChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;

    final screens = [
      _buildTodayHome(repo),
      PlannerScreen(
        planBlocks: repo.planBlocks,
        taskService: repo.taskService,
        onBlocksUpdated: repo.updatePlanBlocks,
      ),
      TasksScreen(
        taskService: repo.taskService,
        onDataChanged: repo.notifyDataChanged,
      ),
      BookScreen(
        repository: repo.entriesRepository,
        isBangla: repo.isBangla,
      ),
      AssistantScreen(
        assistantService: repo.aiAssistantService,
        toolEngine: repo.assistantToolEngine,
        isBangla: repo.isBangla,
        onNavigateToDayPage: (dayKey) {
          setState(() => _currentIndex = 0);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          if (idx == 2) {
            _openQuickCaptureModal();
          } else {
            setState(() => _currentIndex = idx);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          // Part 1: Signature Center Lime Button
          NavigationDestination(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentLime,
              child: Icon(Icons.add, color: AppColors.textOnLime, size: 22),
            ),
            label: 'Capture',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Book',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Ask',
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHome(AppRepository repo) {
    final todayTasks = repo.taskService.getTodayTasks();
    final completedCount = todayTasks.where((t) => t.isCompleted).length;
    final totalCount = todayTasks.length;
    final skyPhase = repo.weatherState.getSkyPhase();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dynamic Monochrome Sky Scene
          WeatherSkyBackground(
            phase: skyPhase,
            condition: repo.weatherState.condition,
            height: 220,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DAYBOOK', style: AppTypography.screenTitle),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.palette_outlined, color: AppColors.accentLime),
                              tooltip: 'Component Gallery',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ComponentGalleryScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.alarm_outlined, color: AppColors.textPrimary),
                              tooltip: 'Alarms',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AlarmScreen(
                                      alarms: repo.alarms,
                                      onAlarmsUpdated: repo.updateAlarms,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.psychology_outlined, color: AppColors.textPrimary),
                              tooltip: 'Memory Vault',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MemoryScreen(
                                      assistantService: repo.aiAssistantService,
                                      isBangla: repo.isBangla,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Badge(
                                isLabelVisible: repo.inboxService.unprocessedCount > 0,
                                label: Text('${repo.inboxService.unprocessedCount}'),
                                backgroundColor: AppColors.accentLime,
                                textColor: Colors.black,
                                child: const Icon(Icons.inbox_outlined, color: AppColors.textPrimary),
                              ),
                              tooltip: 'Inbox Triage',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => InboxScreen(
                                      isBangla: repo.isBangla,
                                      inboxService: repo.inboxService,
                                      tasksRepo: repo.tasksAndGoalsRepository,
                                      entriesRepo: repo.entriesRepository,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.center_focus_strong_outlined, color: AppColors.accentLime),
                              tooltip: 'Focus Zone',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FocusScreen(
                                      isBangla: repo.isBangla,
                                      focusService: repo.focusService,
                                      entriesRepo: repo.entriesRepository,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
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
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openMorningBriefing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentLime,
                            foregroundColor: AppColors.textOnLime,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
                          ),
                          icon: const Icon(Icons.wb_sunny, size: 16),
                          label: const Text('MORNING BRIEFING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _openEveningReview,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
                          ),
                          icon: const Icon(Icons.nights_stay_outlined, size: 16),
                          label: const Text('EVENING REVIEW', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Weather Strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      WeatherInfo.defaultDhaka().skyGlyph,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${repo.weatherState.temperatureC.toStringAsFixed(0)}°C • ${repo.weatherState.condition.label}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  repo.weatherState.cityName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // 2. Daily Trajectory Progress Ring
          DailyProgressRing(
            completedTasks: completedCount,
            totalTasks: totalCount,
            wakeHour: repo.wakeHour,
            wakeMinute: repo.wakeMinute,
            sleepHour: repo.sleepHour,
            sleepMinute: repo.sleepMinute,
          ),
          const SizedBox(height: 8),

          // Next Alarm Card (if available)
          if (repo.alarms.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm, color: AppColors.accentLime, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.isBangla ? 'পরবর্তী অ্যালার্ম' : 'NEXT ALARM',
                          style: const TextStyle(color: AppColors.accentLime, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${repo.alarms.first.timeFormatted} • ${repo.alarms.first.label} (${repo.alarms.first.challengeType.displayName})',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Urgent Exam Countdown Card (Part 10 Student Mode)
          if (repo.studentService.urgentExams.isNotEmpty) ...[
            Builder(builder: (context) {
              final exam = repo.studentService.urgentExams.first;
              final daysLeft = exam.daysUntil(DateTime.now());
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.accentLime),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: AppColors.accentLime, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repo.isBangla ? 'আসন্ন পরীক্ষা কাউন্টডাউন' : 'UPCOMING EXAM COUNTDOWN',
                            style: const TextStyle(color: AppColors.accentLime, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${exam.courseCode}: ${exam.title} (${daysLeft == 0 ? "TODAY" : "$daysLeft days left"})',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentScreen(
                              isBangla: repo.isBangla,
                              studentService: repo.studentService,
                              entriesRepo: repo.entriesRepository,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        repo.isBangla ? 'দেখুন' : 'VIEW',
                        style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // 3. Signature Day Page Entry Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo.isBangla ? 'আজকের দিনবই পৃষ্ঠা' : 'TODAY\'S DAY PAGE',
                        style: const TextStyle(
                          color: AppColors.accentLime,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        repo.isBangla ? 'স্বয়ংক্রিয় টাইমলাইন ও রাতের সারসংক্ষেপ' : 'Auto-filled timeline & nightly reflection',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DayPageScreen(
                          repository: repo.entriesRepository,
                          initialDate: DateTime.now(),
                          isBangla: repo.isBangla,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    repo.isBangla ? 'পৃষ্ঠা খুলুন' : 'Open Page',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Habit Quick-Tap Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  repo.isBangla ? 'দৈনিক অভ্যাস কুইক-ট্যাপ' : 'HABITS QUICK-TAP',
                  style: AppTypography.sectionHeader,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HabitsScreen(
                          isBangla: repo.isBangla,
                          habitService: repo.habitService,
                          entriesRepo: repo.entriesRepository,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    repo.isBangla ? 'সব দেখুন →' : 'ALL HABITS →',
                    style: const TextStyle(color: AppColors.accentLime, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            child: Row(
              children: ['💧 Water', '🚶 Walk', '📖 Read 15m', '💻 Code'].map((h) {
                final isDone = _quickHabitsCompleted.contains(h);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(h),
                    selected: isDone,
                    backgroundColor: AppColors.surface1,
                    selectedColor: AppColors.accentLime,
                    labelStyle: TextStyle(
                      color: isDone ? Colors.black : AppColors.textPrimary,
                      fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isDone ? AppColors.accentLime : AppColors.border),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _quickHabitsCompleted.add(h);
                        } else {
                          _quickHabitsCompleted.remove(h);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Mood & Energy Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  repo.isBangla ? 'মন ও শক্তি স্তর' : 'MOOD & ENERGY',
                  style: AppTypography.sectionHeader,
                ),
                TextButton(
                  onPressed: () {
                    WellnessModal.show(
                      context,
                      isBangla: repo.isBangla,
                      wellnessService: repo.wellnessService,
                      entriesRepo: repo.entriesRepository,
                    );
                  },
                  child: Text(
                    repo.isBangla ? 'চেক-ইন →' : 'CHECK-IN →',
                    style: const TextStyle(color: AppColors.accentLime, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            child: Row(
              children: ['⚡ High Energy', '😊 Focused', '😐 Normal', '🌧 Low Energy'].map((m) {
                final isSelected = _selectedMood == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    backgroundColor: AppColors.surface1,
                    selectedColor: AppColors.accentLime,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.accentLime : AppColors.border),
                    onSelected: (_) => setState(() => _selectedMood = m),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Life Ledger & Circles Card (Part 9)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Money & Dhar
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MoneyScreen(
                            isBangla: repo.isBangla,
                            moneyService: repo.moneyService,
                            dharService: repo.dharService,
                            entriesRepo: repo.entriesRepository,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.accentLime),
                              const SizedBox(width: 6),
                              Text(
                                repo.isBangla ? 'টাকা ও ধার' : 'MONEY & DHAR',
                                style: const TextStyle(
                                  color: AppColors.accentLime,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            repo.moneyService.formatBdt(repo.moneyService.netBalancePaisa),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            repo.isBangla
                                ? 'ধার বাকি: ${repo.dharService.formatBdt(repo.dharService.totalReceivablePaisa)}'
                                : 'Receivable: ${repo.dharService.formatBdt(repo.dharService.totalReceivablePaisa)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.border),
                // People & Circles
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PeopleScreen(
                            isBangla: repo.isBangla,
                            peopleService: repo.peopleService,
                            dharService: repo.dharService,
                            entriesRepo: repo.entriesRepository,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_outline, size: 16, color: AppColors.accentLime),
                              const SizedBox(width: 6),
                              Text(
                                repo.isBangla ? 'মানুষ ও সম্পর্ক' : 'PEOPLE & CIRCLES',
                                style: const TextStyle(
                                  color: AppColors.accentLime,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${repo.peopleService.allPeople.length} Contacts',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            repo.peopleService.overduePeople.isNotEmpty
                                ? '${repo.peopleService.overduePeople.length} due for catch-up'
                                : 'All connections fresh',
                            style: TextStyle(
                              color: repo.peopleService.overduePeople.isNotEmpty
                                  ? AppColors.accentLime
                                  : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: repo.peopleService.overduePeople.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Section Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            child: Text('TODAY\'S PRIORITIES', style: AppTypography.sectionHeader),
          ),

          // 5. Tasks
          if (todayTasks.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('All tasks completed for today.', style: AppTypography.bodySecondary),
              ),
            )
          else ...[
            Builder(builder: (context) {
              final frogTask = PlannerAlgorithm.pickEatTheFrog(todayTasks);
              return Column(
                children: todayTasks.take(3).map((task) {
                  final isFrog = task.id == frogTask?.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: isFrog ? AppColors.accentLime : AppColors.border,
                        width: isFrog ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: task.isCompleted ? AppColors.accentLime : AppColors.textSecondary,
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
                              Row(
                                children: [
                                  if (isFrog) const Text('🐸 ', style: TextStyle(fontSize: 14)),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${task.category} • ${task.estimatedMinutes}m',
                                style: AppTypography.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
