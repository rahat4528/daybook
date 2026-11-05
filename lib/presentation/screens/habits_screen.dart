import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/models/day_page.dart';
import '../../domain/models/habit_item.dart';
import '../../domain/services/habit_service.dart';
import '../../data/repositories/entries_repository.dart';

class HabitsScreen extends StatefulWidget {
  final bool isBangla;
  final HabitService habitService;
  final EntriesRepository entriesRepo;

  const HabitsScreen({
    super.key,
    this.isBangla = false,
    required this.habitService,
    required this.entriesRepo,
  });

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    widget.habitService.addListener(_onServiceUpdated);
  }

  void _onServiceUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.habitService.removeListener(_onServiceUpdated);
    super.dispose();
  }

  void _showAddHabitSheet() {
    final nameController = TextEditingController();
    final nameBnController = TextEditingController();
    final targetController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'times');
    String glyph = '⚡';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.isBangla ? 'নতুন অভ্যাস যুক্ত করুন' : 'CREATE NEW HABIT',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.accentLime,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: widget.isBangla ? 'অভ্যাসের নাম (ইংরেজি)' : 'Habit Name (English)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameBnController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: widget.isBangla ? 'অভ্যাসের নাম (বাংলা)' : 'Habit Name (Bangla)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'লক্ষ্যমাত্রা' : 'Target Count',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: unitController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'একক' : 'Unit (ml, pages, mins)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentLime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final nameBn = nameBnController.text.trim();
                if (name.isNotEmpty) {
                  final target = int.tryParse(targetController.text) ?? 1;
                  widget.habitService.saveHabit(
                    HabitItem(
                      id: 'habit_${DateTime.now().microsecondsSinceEpoch}',
                      name: name,
                      nameBn: nameBn.isNotEmpty ? nameBn : name,
                      glyph: glyph,
                      targetValue: target,
                      unit: unitController.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: Text(
                widget.isBangla ? 'সংরক্ষণ' : 'SAVE HABIT',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = widget.habitService.habits;
    final todayKey = DayPageModel.formatDayKey(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          widget.isBangla ? 'দৈনিক অভ্যাস ও ধারাবাহিকতা' : 'HABITS & STREAKS',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Text('⚡', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isBangla ? 'কোনো অভ্যাস যুক্ত নেই' : 'No Habits Defined Yet',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isBangla ? 'নিচের বোতাম চেপে নতুন অভ্যাস তৈরি করুন।' : 'Tap + to build your momentum chain.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isDone = widget.habitService.isHabitCompleted(habit.id, todayKey);
                final heatmap = widget.habitService.getHeatmap30Days(habit.id, DateTime.now());

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDone ? AppColors.accentLime.withValues(alpha: 0.6) : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Name + Freeze Tokens + Toggle Check
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(habit.glyph, style: const TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isBangla ? habit.nameBn : habit.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      widget.isBangla
                                          ? 'ধারাবাহিকতা: ${habit.currentStreak} দিন'
                                          : 'Streak: ${habit.currentStreak} days',
                                      style: TextStyle(
                                        color: habit.currentStreak > 0
                                            ? AppColors.accentLime
                                            : AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (habit.freezeTokens > 0) ...[
                                      const SizedBox(width: 8),
                                      Row(
                                        children: List.generate(
                                          habit.freezeTokens,
                                          (_) => const Text('❄️', style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // 1-tap Toggle Button
                          InkWell(
                            onTap: () {
                              widget.habitService.toggleHabit(
                                habit.id,
                                entriesRepo: widget.entriesRepo,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDone ? AppColors.accentLime : AppColors.surface2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDone ? AppColors.accentLime : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.check,
                                color: isDone ? Colors.black : AppColors.textSecondary,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 30-Day Heatmap Micro Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: heatmap.map((tier) {
                          Color cellColor = AppColors.surface2;
                          if (tier == 4) cellColor = AppColors.accentLime;
                          if (tier == 1) cellColor = AppColors.accentLime.withValues(alpha: 0.3);

                          return Container(
                            width: 8,
                            height: 14,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentLime,
        foregroundColor: Colors.black,
        tooltip: widget.isBangla ? 'নতুন অভ্যাস' : 'New Habit',
        onPressed: _showAddHabitSheet,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
