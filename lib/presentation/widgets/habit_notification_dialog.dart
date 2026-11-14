// Interactive Habit Notification Simulator Dialog (Page 03)
// Simulates OS Lock Screen interactive notifications with 'Done' and 'Snooze 30m' buttons.

import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/models/habit_item.dart';
import '../../domain/services/habit_notification_service.dart';

class HabitNotificationSimulatorDialog extends StatelessWidget {
  final HabitItem habit;
  final HabitNotificationService notificationService;
  final bool isBangla;
  final VoidCallback onActionCompleted;

  const HabitNotificationSimulatorDialog({
    super.key,
    required this.habit,
    required this.notificationService,
    this.isBangla = false,
    required this.onActionCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required HabitItem habit,
    required HabitNotificationService notificationService,
    bool isBangla = false,
    required VoidCallback onActionCompleted,
  }) {
    return showDialog(
      context: context,
      builder: (_) => HabitNotificationSimulatorDialog(
        habit: habit,
        notificationService: notificationService,
        isBangla: isBangla,
        onActionCompleted: onActionCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accentLime, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentLime.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OS Notification Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_active, color: AppColors.accentLime, size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'DAYBOOK NOTIFICATION CENTER',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                const Text('NOW', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 14),

            // Notification Content Body
            Text(
              '${habit.title} (${habit.currentStreak}-Day Streak)',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBangla
                  ? 'আপনার আজকের অভ্যাস সম্পূর্ণ করুন অথবা ৩০ মিনিট স্নুজ করুন।'
                  : 'Complete today\'s habit directly or snooze for 30 minutes.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 18),

            // Interactive Action Buttons
            Row(
              children: [
                // ACTION: SNOOZE 30M
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      notificationService.handleNotificationAction(
                        HabitNotificationService.actionSnooze,
                        habit.id,
                      );
                      Navigator.of(context).pop();
                      onActionCompleted();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⏱ Snoozed "${habit.title}" for 30 minutes.'),
                          backgroundColor: AppColors.surface2,
                        ),
                      );
                    },
                    child: const Text('⏱ Snooze 30m', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                // ACTION: DONE
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      notificationService.handleNotificationAction(
                        HabitNotificationService.actionDone,
                        habit.id,
                      );
                      Navigator.of(context).pop();
                      onActionCompleted();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Marked "${habit.title}" Done from notification!'),
                          backgroundColor: AppColors.accentLime,
                        ),
                      );
                    },
                    child: const Text('✓ Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
