import 'package:flutter/material.dart';
import '../../domain/models/daily_plan_block.dart';
import '../../domain/services/planner_service.dart';
import '../../domain/services/task_service.dart';

class PlannerScreen extends StatefulWidget {
  final List<DailyPlanBlock> planBlocks;
  final TaskService taskService;
  final Function(List<DailyPlanBlock>) onBlocksUpdated;

  const PlannerScreen({
    super.key,
    required this.planBlocks,
    required this.taskService,
    required this.onBlocksUpdated,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _plannerService = PlannerService();

  void _autoPlanDay() {
    final candidateTasks = widget.taskService.getTodayTasks();
    if (candidateTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active tasks to plan. Add some tasks first!')),
      );
      return;
    }

    final newPlan = _plannerService.generateDailyPlan(
      tasks: candidateTasks,
      fixedBlocks: widget.planBlocks.where((b) => b.taskId == null).toList(), // keep custom blocks
      wakeHour: 7,
      wakeMinute: 0,
      sleepHour: 23,
      sleepMinute: 0,
    );

    widget.onBlocksUpdated(newPlan);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated ${newPlan.length} optimized focus blocks for today!')),
    );
  }

  void _addCustomBlock() {
    final titleController = TextEditingController();
    int startHour = 14;
    int durationMinutes = 45;
    String category = 'Focus';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Focus Block'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Block Title',
                      hintText: 'e.g., Deep Research & Reading',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: startHour,
                          decoration: const InputDecoration(labelText: 'Start Hour'),
                          items: List.generate(18, (i) => i + 6)
                              .map((h) => DropdownMenuItem(value: h, child: Text('$h:00')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => startHour = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: durationMinutes,
                          decoration: const InputDecoration(labelText: 'Duration'),
                          items: [25, 45, 60, 90]
                              .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => durationMinutes = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      final endTotal = (startHour * 60) + durationMinutes;
                      final block = DailyPlanBlock(
                        id: 'block_${DateTime.now().microsecondsSinceEpoch}',
                        title: titleController.text.trim(),
                        startHour: startHour,
                        startMinute: 0,
                        endHour: endTotal ~/ 60,
                        endMinute: endTotal % 60,
                        category: category,
                      );
                      final updated = List<DailyPlanBlock>.from(widget.planBlocks)..add(block);
                      widget.onBlocksUpdated(updated);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Add Block'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortedBlocks = List<DailyPlanBlock>.from(widget.planBlocks)
      ..sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute));

    final totalPlannedMinutes = sortedBlocks.fold(0, (acc, b) => acc + b.durationMinutes);
    final hours = totalPlannedMinutes ~/ 60;
    final mins = totalPlannedMinutes % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Time-Block Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Auto-Plan Day with AI',
            onPressed: _autoPlanDay,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Block',
            onPressed: _addCustomBlock,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF6366F1), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Planned Time: ${hours}h ${mins}m',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Deterministic time blocking protects your peak focus hours.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _autoPlanDay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Auto-Plan', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          // Timeline list
          Expanded(
            child: sortedBlocks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No blocks scheduled today yet.'),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _autoPlanDay,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Auto-Fit Today\'s Tasks'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: sortedBlocks.length,
                    itemBuilder: (ctx, i) {
                      final block = sortedBlocks[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: block.isCompleted
                                ? Colors.transparent
                                : const Color(0xFF6366F1).withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Time indicator pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                block.timeRangeFormatted,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    block.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      decoration: block.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: block.isCompleted ? Colors.grey : null,
                                    ),
                                  ),
                                  Text(
                                    '${block.durationMinutes} mins • ${block.category}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            // Toggle complete
                            IconButton(
                              icon: Icon(
                                block.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: block.isCompleted ? Colors.green : Colors.grey,
                              ),
                              onPressed: () {
                                final updated = List<DailyPlanBlock>.from(widget.planBlocks);
                                final idx = updated.indexWhere((b) => b.id == block.id);
                                if (idx != -1) {
                                  updated[idx] = block.copyWith(isCompleted: !block.isCompleted);
                                  widget.onBlocksUpdated(updated);
                                }
                              },
                            ),
                            // Delete
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                              onPressed: () {
                                final updated = List<DailyPlanBlock>.from(widget.planBlocks)
                                  ..removeWhere((b) => b.id == block.id);
                                widget.onBlocksUpdated(updated);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

