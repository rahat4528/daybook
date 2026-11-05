import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/models/daily_plan_block.dart';
import '../../domain/models/task_item.dart';
import '../../domain/services/planner_algorithm.dart';
import '../../domain/services/task_service.dart';

class PlannerScreen extends StatefulWidget {
  final List<DailyPlanBlock> planBlocks;
  final TaskService taskService;
  final Function(List<DailyPlanBlock>) onBlocksUpdated;
  final bool isBangla;

  const PlannerScreen({
    super.key,
    required this.planBlocks,
    required this.taskService,
    required this.onBlocksUpdated,
    this.isBangla = false,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  List<DailyPlanBlock>? _undoPlanSnapshot;
  bool _isOverloaded = false;
  int _deficitMinutes = 0;
  TaskItem? _frogTask;

  void _autoPlanDay() {
    final candidateTasks = widget.taskService.getTodayTasks();
    if (candidateTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.surface2,
          content: Text(
            widget.isBangla ? 'পরিকল্পনার জন্য কোনো সক্রিয় টাস্ক নেই।' : 'No active tasks to plan. Add some tasks first!',
            style: const TextStyle(color: AppTokens.textPrimary),
          ),
        ),
      );
      return;
    }

    _undoPlanSnapshot = List.from(widget.planBlocks);

    final result = PlannerAlgorithm.fitTasksIntoDay(
      tasks: candidateTasks,
      wakeHour: 7,
      wakeMinute: 0,
      sleepHour: 23,
      sleepMinute: 0,
      fixedBlocks: widget.planBlocks.where((b) => b.taskId == null).toList(),
      isBangla: widget.isBangla,
    );

    setState(() {
      _isOverloaded = result.isOverloaded;
      _deficitMinutes = result.deficitMinutes;
      _frogTask = result.frogTask;
    });

    widget.onBlocksUpdated(result.blocks);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTokens.surface2,
        content: Text(
          widget.isBangla
              ? '${result.blocks.length}টি ফোকাস ব্লক নির্ধারিত হয়েছে!'
              : 'Generated ${result.blocks.length} optimized focus blocks for today!',
          style: const TextStyle(color: AppTokens.accentLime),
        ),
        action: SnackBarAction(
          label: widget.isBangla ? 'পূর্বাবস্থায়' : 'Undo',
          textColor: AppTokens.accentLime,
          onPressed: _undoPlan,
        ),
      ),
    );
  }

  void _resetMyDay() {
    if (widget.planBlocks.isEmpty) return;

    _undoPlanSnapshot = List.from(widget.planBlocks);

    final reshuffled = PlannerAlgorithm.resetMyDay(
      currentBlocks: widget.planBlocks,
      tasks: widget.taskService.getTodayTasks(),
      now: DateTime.now(),
      sleepHour: 23,
      isBangla: widget.isBangla,
    );

    widget.onBlocksUpdated(reshuffled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTokens.surface2,
        content: Text(
          widget.isBangla ? 'দিনটি সফলভাবে রিশাফেল করা হয়েছে!' : 'Day schedule reshuffled realistically from now forward!',
          style: const TextStyle(color: AppTokens.accentLime),
        ),
        action: SnackBarAction(
          label: widget.isBangla ? 'পূর্বাবস্থায়' : 'Undo',
          textColor: AppTokens.accentLime,
          onPressed: _undoPlan,
        ),
      ),
    );
  }

  void _undoPlan() {
    if (_undoPlanSnapshot != null) {
      widget.onBlocksUpdated(_undoPlanSnapshot!);
      setState(() => _undoPlanSnapshot = null);
    }
  }

  void _addCustomBlock() {
    final titleController = TextEditingController();
    int startHour = 14;
    int durationMinutes = 45;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTokens.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                side: const BorderSide(color: AppTokens.border),
              ),
              title: Text(
                widget.isBangla ? 'নতুন ফোকাস ব্লক যোগ করুন' : 'Add Focus Block',
                style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppTokens.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'ব্লক শিরোনাম' : 'Block Title',
                      labelStyle: const TextStyle(color: AppTokens.textSecondary),
                      hintText: widget.isBangla ? 'যেমন: গভীর গবেষণা ও পড়া' : 'e.g., Deep Architecture & Reading',
                      hintStyle: const TextStyle(color: AppTokens.textSecondary),
                      filled: true,
                      fillColor: AppTokens.surface1,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: startHour,
                          dropdownColor: AppTokens.surface1,
                          style: const TextStyle(color: AppTokens.textPrimary),
                          decoration: InputDecoration(
                            labelText: widget.isBangla ? 'শুরুর সময়' : 'Start Hour',
                            labelStyle: const TextStyle(color: AppTokens.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
                          dropdownColor: AppTokens.surface1,
                          style: const TextStyle(color: AppTokens.textPrimary),
                          decoration: InputDecoration(
                            labelText: widget.isBangla ? 'দৈর্ঘ্য' : 'Duration',
                            labelStyle: const TextStyle(color: AppTokens.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
                  child: Text(widget.isBangla ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppTokens.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTokens.accentLime, foregroundColor: Colors.black),
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
                        category: 'Focus',
                      );
                      final updated = List<DailyPlanBlock>.from(widget.planBlocks)..add(block);
                      widget.onBlocksUpdated(updated);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(widget.isBangla ? 'সংযোজন' : 'Add Block', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final sortedBlocks = List<DailyPlanBlock>.from(widget.planBlocks)
      ..sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute));

    final totalPlannedMinutes = sortedBlocks.fold(0, (acc, b) => acc + b.durationMinutes);
    final hours = totalPlannedMinutes ~/ 60;
    final mins = totalPlannedMinutes % 60;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: Text(
          widget.isBangla ? 'দৈনিক সময় পরিকল্পনা' : 'Daily Time-Block Planner',
          style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt, color: AppTokens.accentLime),
            tooltip: widget.isBangla ? 'দিন রিশাফেল করুন (Reset Day)' : 'Reset My Day',
            onPressed: _resetMyDay,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTokens.accentLime),
            tooltip: widget.isBangla ? 'স্বয়ংক্রিয় পরিকল্পনা' : 'Auto-Plan Day',
            onPressed: _autoPlanDay,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppTokens.textPrimary),
            tooltip: widget.isBangla ? 'ব্লক যোগ করুন' : 'Add Custom Block',
            onPressed: _addCustomBlock,
          ),
        ],
      ),
      body: Column(
        children: [
          // Overload Warning Banner
          if (_isOverloaded)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTokens.errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTokens.errorRed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTokens.errorRed, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isBangla
                          ? 'সতর্কতা: পরিকল্পিত সময় কাজের সক্ষমতার চেয়ে $_deficitMinutes মিনিট বেশি।'
                          : 'Overload Warning: Planned tasks exceed available work time by $_deficitMinutes mins.',
                      style: const TextStyle(color: AppTokens.errorRed, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Header summary card (OLED Surface & Lime Bold)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.surface1,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppTokens.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTokens.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTokens.accentLime),
                  ),
                  child: const Icon(Icons.schedule, color: AppTokens.accentLime, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isBangla ? 'মোট পরিকল্পিত সময়: $hoursঘ $minsমি' : 'Total Planned Time: ${hours}h ${mins}m',
                        style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isBangla
                            ? 'নির্ধারিত ফোকাস ব্লক আপনার সর্বোচ্চ শক্তি সময়কে সুরক্ষিত রাখে।'
                            : 'Deterministic blocks protect your peak cognitive focus hours.',
                        style: const TextStyle(fontSize: 12, color: AppTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // "Eat the Frog" Banner if designated
          if (_frogTask != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTokens.accentLime.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Text('🐸', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isBangla ? 'আজকের ফ্রগ (Eat the Frog)' : 'TODAY\'S BIG FROG CHALLENGE',
                          style: const TextStyle(color: AppTokens.accentLime, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _frogTask!.title,
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
          const SizedBox(height: 8),

          // Plan Blocks Timeline
          Expanded(
            child: sortedBlocks.isEmpty
                ? Center(
                    child: Text(
                      widget.isBangla ? 'কোনো ব্লক নেই। "স্বয়ংক্রিয় পরিকল্পনা" চাপুন।' : 'No blocks planned. Tap Auto-Plan to start.',
                      style: const TextStyle(color: AppTokens.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: sortedBlocks.length,
                    itemBuilder: (ctx, index) {
                      final block = sortedBlocks[index];
                      final isFrogBlock = block.taskId == _frogTask?.id;
                      final isBuffer = block.category == 'Rest' || block.category == 'Routine';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTokens.surface1,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFrogBlock ? AppTokens.accentLime : AppTokens.border,
                            width: isFrogBlock ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              block.timeRangeFormatted,
                              style: const TextStyle(
                                color: AppTokens.textSecondary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    block.title,
                                    style: TextStyle(
                                      color: isBuffer ? AppTokens.textSecondary : AppTokens.textPrimary,
                                      fontWeight: isFrogBlock ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  if (isFrogBlock)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        widget.isBangla ? 'শীর্ষ শক্তি সময় ব্লক' : 'Peak Energy Focus Block',
                                        style: const TextStyle(color: AppTokens.accentLime, fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTokens.textSecondary, size: 16),
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
