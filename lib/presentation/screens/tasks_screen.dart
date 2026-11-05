import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/enums/core_enums.dart';
import '../../core/enums/task_priority.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/subtask_item.dart';
import '../../domain/services/planner_algorithm.dart';
import '../../domain/services/task_service.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  final TaskService taskService;
  final VoidCallback onDataChanged;
  final bool isBangla;

  const TasksScreen({
    super.key,
    required this.taskService,
    required this.onDataChanged,
    this.isBangla = false,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskItem> _filter(List<TaskItem> list) {
    return list.where((t) {
      final matchesCat = _selectedCategory == 'All' ||
          t.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesCat;
    }).toList();
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final subtaskController = TextEditingController();
    TaskPriority priority = TaskPriority.importantNotUrgent;
    String category = 'Work';
    int estimatedMinutes = 30;
    RecurrenceType recurrence = RecurrenceType.none;
    DateTime? dueAt = DateTime.now().add(const Duration(hours: 4));
    final List<SubtaskItem> tempSubtasks = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
        side: BorderSide(color: AppTokens.border),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isBangla ? 'নতুন টাস্ক তৈরি করুন' : 'Create New Task',
                          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTokens.textSecondary),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      style: const TextStyle(color: AppTokens.textPrimary),
                      decoration: InputDecoration(
                        labelText: widget.isBangla ? 'টাস্কের শিরোনাম' : 'Task Title',
                        labelStyle: const TextStyle(color: AppTokens.textSecondary),
                        filled: true,
                        fillColor: AppTokens.surface1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: AppTokens.textPrimary),
                      decoration: InputDecoration(
                        labelText: widget.isBangla ? 'নোট বা বিবরণ' : 'Notes / Description',
                        labelStyle: const TextStyle(color: AppTokens.textSecondary),
                        filled: true,
                        fillColor: AppTokens.surface1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TaskPriority>(
                            value: priority,
                            dropdownColor: AppTokens.surface1,
                            style: const TextStyle(color: AppTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: widget.isBangla ? 'আইজেনহাওয়ার অগ্রাধিকার' : 'Priority (Eisenhower)',
                              labelStyle: const TextStyle(color: AppTokens.textSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: TaskPriority.values.map((p) {
                              return DropdownMenuItem(value: p, child: Text(p.label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<RecurrenceType>(
                            value: recurrence,
                            dropdownColor: AppTokens.surface1,
                            style: const TextStyle(color: AppTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: widget.isBangla ? 'পুনরাবৃত্তি' : 'Recurrence',
                              labelStyle: const TextStyle(color: AppTokens.textSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: RecurrenceType.values.map((r) {
                              return DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => recurrence = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: estimatedMinutes,
                            dropdownColor: AppTokens.surface1,
                            style: const TextStyle(color: AppTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: widget.isBangla ? 'আনুমানিক সময়' : 'Estimate',
                              labelStyle: const TextStyle(color: AppTokens.textSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [15, 25, 30, 45, 60, 90, 120].map((m) {
                              return DropdownMenuItem(value: m, child: Text('$m mins'));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => estimatedMinutes = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            dropdownColor: AppTokens.surface1,
                            style: const TextStyle(color: AppTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: widget.isBangla ? 'ক্যাটেগরি' : 'Category',
                              labelStyle: const TextStyle(color: AppTokens.textSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Work', 'Personal', 'Health', 'Finance', 'Growth'].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Subtasks section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subtaskController,
                            style: const TextStyle(color: AppTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: widget.isBangla ? 'সাবটাস্ক যোগ করুন' : 'Add Subtask item',
                              labelStyle: const TextStyle(color: AppTokens.textSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTokens.accentLime),
                          onPressed: () {
                            final text = subtaskController.text.trim();
                            if (text.isNotEmpty) {
                              setModalState(() {
                                tempSubtasks.add(
                                  SubtaskItem(
                                    id: 'st_${DateTime.now().microsecondsSinceEpoch}',
                                    title: text,
                                  ),
                                );
                                subtaskController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (tempSubtasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...tempSubtasks.map((st) => Text('• ${st.title}', style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12))),
                    ],
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.accentLime,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            widget.taskService.addTask(
                              title: titleController.text.trim(),
                              notes: notesController.text.trim(),
                              category: category,
                              priority: priority,
                              estimatedMinutes: estimatedMinutes,
                              recurrence: recurrence,
                              dueAt: dueAt,
                              subtasks: tempSubtasks,
                            );
                            widget.onDataChanged();
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: Text(
                          widget.isBangla ? 'টাস্ক সংরক্ষণ করুন' : 'Save Task',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = _filter(widget.taskService.getTodayTasks());
    final upcomingTasks = _filter(widget.taskService.getUpcomingTasks());
    final allTasks = _filter(widget.taskService.tasks);
    final completedTasks = _filter(widget.taskService.getCompletedTasks());
    final frogTask = PlannerAlgorithm.pickEatTheFrog(todayTasks);

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: Text(
          widget.isBangla ? 'টাস্ক কমান্ড সেন্টার' : 'Task Command Center',
          style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTokens.accentLime,
          labelColor: AppTokens.accentLime,
          unselectedLabelColor: AppTokens.textSecondary,
          tabs: [
            Tab(text: widget.isBangla ? 'আজকের' : 'Today'),
            Tab(text: widget.isBangla ? 'আসন্ন' : 'Upcoming'),
            Tab(text: widget.isBangla ? 'সকল' : 'All Tasks'),
            Tab(text: widget.isBangla ? 'সম্পন্ন' : 'Done'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTokens.accentLime),
            onPressed: _showAddTaskSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTokens.accentLime,
        foregroundColor: Colors.black,
        tooltip: widget.isBangla ? 'নতুন কাজ যোগ করুন' : 'Add Task',
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // "Eat the Frog" Banner on Today View
          if (frogTask != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTokens.accentLime),
              ),
              child: Row(
                children: [
                  const Text('🐸', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isBangla ? 'আজকের সবচেয়ে গুরুত্বপূর্ণ কাজ (Frog)' : 'DAILY BIG FROG TARGET',
                          style: const TextStyle(color: AppTokens.accentLime, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          frogTask.title,
                          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(todayTasks),
                _buildTaskList(upcomingTasks),
                _buildTaskList(allTasks),
                _buildTaskList(completedTasks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<TaskItem> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          widget.isBangla ? 'কোনো কাজ নেই।' : 'No tasks in this view.',
          style: const TextStyle(color: AppTokens.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (ctx, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          isBangla: widget.isBangla,
          onToggleComplete: () {
            widget.taskService.toggleTaskCompletion(task.id);
            widget.onDataChanged();
          },
          onToggleSubtask: (stId) {
            widget.taskService.toggleSubtask(task.id, stId);
            widget.onDataChanged();
          },
          onDelete: () {
            widget.taskService.deleteTask(task.id);
            widget.onDataChanged();
          },
        );
      },
    );
  }
}
