import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/enums/core_enums.dart';
import '../../core/enums/task_priority.dart';
import '../../domain/models/task_item.dart';

class TaskCard extends StatefulWidget {
  final TaskItem task;
  final VoidCallback onToggleComplete;
  final Function(String subtaskId)? onToggleSubtask;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isBangla;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    this.onToggleSubtask,
    this.onDelete,
    this.onEdit,
    this.isBangla = false,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isExpanded = false;

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return AppTokens.errorRed;
      case TaskPriority.importantNotUrgent:
        return AppTokens.accentLime;
      case TaskPriority.urgentNotImportant:
        return const Color(0xFF60A5FA);
      case TaskPriority.neither:
        return AppTokens.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final priorityColor = _getPriorityColor(task.priority);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: task.isFrog
              ? AppTokens.accentLime
              : (task.isCompleted ? AppTokens.border : priorityColor.withValues(alpha: 0.5)),
          width: task.isFrog ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Checkbox (or Lock if blocked)
                IconButton(
                  icon: Icon(
                    task.isBlocked && !task.isCompleted
                        ? Icons.lock_outline
                        : (task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                    color: task.isBlocked && !task.isCompleted
                        ? AppTokens.textSecondary
                        : (task.isCompleted ? AppTokens.accentLime : priorityColor),
                    size: 24,
                  ),
                  onPressed: () {
                    if (task.isBlocked && !task.isCompleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTokens.surface2,
                          content: Text(
                            widget.isBangla
                                ? 'এই কাজটি পূর্বশর্তের উপর নির্ভরশীল।'
                                : 'This task is blocked by unfinished prerequisite tasks!',
                            style: const TextStyle(color: AppTokens.errorRed),
                          ),
                        ),
                      );
                    } else {
                      widget.onToggleComplete();
                    }
                  },
                ),

                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (task.isFrog) ...[
                            const Text('🐸 ', style: TextStyle(fontSize: 14)),
                          ],
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                color: task.isCompleted ? AppTokens.textSecondary : AppTokens.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Metadata chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              task.priority.label.split(':').first,
                              style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),

                          // Recurrence Badge
                          if (task.recurrence != RecurrenceType.none)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTokens.surface2,
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                border: Border.all(color: AppTokens.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.repeat, size: 10, color: AppTokens.accentLime),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.recurrence.name.toUpperCase(),
                                    style: const TextStyle(color: AppTokens.accentLime, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                          // Duration Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTokens.surface2,
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              border: Border.all(color: AppTokens.border),
                            ),
                            child: Text(
                              '${task.estimatedMinutes}m',
                              style: const TextStyle(color: AppTokens.textSecondary, fontSize: 10),
                            ),
                          ),

                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTokens.surface2,
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              border: Border.all(color: AppTokens.border),
                            ),
                            child: Text(
                              task.category,
                              style: const TextStyle(color: AppTokens.textSecondary, fontSize: 10),
                            ),
                          ),
                        ],
                      ),

                      // Blocked warning
                      if (task.isBlocked && !task.isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.lock, size: 12, color: AppTokens.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                widget.isBangla ? 'পূর্বশর্ত দ্বারা লক করা' : 'Blocked by prerequisite tasks',
                                style: const TextStyle(color: AppTokens.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Subtasks Expander Toggle
                if (task.subtasks.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTokens.textSecondary,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),

                // Delete Button
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTokens.textSecondary, size: 16),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),

          // Subtasks Checklist Expander
          if (_isExpanded && task.subtasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTokens.border)),
              ),
              child: Column(
                children: task.subtasks.map((st) {
                  return Row(
                    children: [
                      Checkbox(
                        value: st.isCompleted,
                        activeColor: AppTokens.accentLime,
                        checkColor: Colors.black,
                        onChanged: (_) {
                          if (widget.onToggleSubtask != null) {
                            widget.onToggleSubtask!(st.id);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          st.title,
                          style: TextStyle(
                            color: st.isCompleted ? AppTokens.textSecondary : AppTokens.textPrimary,
                            fontSize: 12.5,
                            decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
