import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/core_enums.dart';
import '../../core/enums/task_priority.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/subtask_item.dart';
import '../../domain/services/task_service.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  final TaskService taskService;
  final VoidCallback onDataChanged;

  const TasksScreen({
    super.key,
    required this.taskService,
    required this.onDataChanged,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TaskItem> _filter(List<TaskItem> list) {
    return list.where((t) {
      final matchesCat = _selectedCategory == 'All' ||
          t.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final subtaskController = TextEditingController();
    TaskPriority priority = TaskPriority.importantNotUrgent;
    String category = 'Work';
    int estimatedMinutes = 30;
    DateTime? dueAt = DateTime.now().add(const Duration(hours: 4));
    final List<SubtaskItem> tempSubtasks = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        const Text(
                          'Create New Task',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'e.g., Finalize system blueprint',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Priority selector
                    const Text('Priority (Eisenhower)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: TaskPriority.values.map((p) {
                        final isSelected = priority == p;
                        return ChoiceChip(
                          label: Text(p.label.split(':').first, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => priority = p);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Category & Duration
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: AppConstants.taskCategories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: estimatedMinutes.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Est. Minutes',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null) estimatedMinutes = parsed;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Subtask input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subtaskController,
                            decoration: const InputDecoration(
                              hintText: 'Add subtask step...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (subtaskController.text.trim().isNotEmpty) {
                              setModalState(() {
                                tempSubtasks.add(SubtaskItem(
                                  id: 'st_${DateTime.now().microsecondsSinceEpoch}',
                                  title: subtaskController.text.trim(),
                                ));
                                subtaskController.clear();
                              });
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (tempSubtasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...tempSubtasks.map((st) => Text('• ${st.title}', style: const TextStyle(fontSize: 12))),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
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
                              dueAt: dueAt,
                              subtasks: tempSubtasks,
                            );
                            widget.onDataChanged();
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: const Text('Save Task', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Command Center', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search & Category Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ['All', ...AppConstants.taskCategories].map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Today (${todayTasks.length})'),
                  Tab(text: 'Upcoming (${upcomingTasks.length})'),
                  Tab(text: 'All (${allTasks.length})'),
                  Tab(text: 'Done (${completedTasks.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(todayTasks),
          _buildTaskList(upcomingTasks),
          _buildTaskList(allTasks),
          _buildTaskList(completedTasks),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildTaskList(List<TaskItem> list) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No tasks in this view', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final task = list[i];
        return TaskCard(
          task: task,
          onToggleComplete: () {
            setState(() {
              widget.taskService.toggleTaskCompletion(task.id);
            });
            widget.onDataChanged();
          },
          onToggleSubtask: (stId) {
            setState(() {
              widget.taskService.toggleSubtask(task.id, stId);
            });
            widget.onDataChanged();
          },
          onDelete: () {
            setState(() {
              widget.taskService.deleteTask(task.id);
            });
            widget.onDataChanged();
          },
        );
      },
    );
  }
}

