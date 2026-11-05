import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/models/sleep_log.dart';
import '../../domain/services/sleep_service.dart';

class SleepTrackerScreen extends StatefulWidget {
  final SleepService sleepService;
  final bool isBangla;
  final int nextAlarmHour;
  final int nextAlarmMinute;

  const SleepTrackerScreen({
    super.key,
    required this.sleepService,
    this.isBangla = false,
    this.nextAlarmHour = 6,
    this.nextAlarmMinute = 30,
  });

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  void _showAddSleepSheet() {
    int durationHours = 7;
    int durationMinutes = 30;
    int rating = 4;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isBangla ? 'ঘুমের তথ্য সংরক্ষণ করুন' : 'Log Sleep Session',
                    style: const TextStyle(color: AppTokens.accentLime, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: durationHours,
                          dropdownColor: AppTokens.surface2,
                          style: const TextStyle(color: AppTokens.textPrimary),
                          decoration: InputDecoration(
                            labelText: widget.isBangla ? 'ঘণ্টা' : 'Hours',
                            labelStyle: const TextStyle(color: AppTokens.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: List.generate(12, (i) => i + 4)
                              .map((h) => DropdownMenuItem(value: h, child: Text('$h hrs')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => durationHours = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: durationMinutes,
                          dropdownColor: AppTokens.surface2,
                          style: const TextStyle(color: AppTokens.textPrimary),
                          decoration: InputDecoration(
                            labelText: widget.isBangla ? 'মিনিট' : 'Minutes',
                            labelStyle: const TextStyle(color: AppTokens.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: [0, 15, 30, 45]
                              .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => durationMinutes = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isBangla ? 'ঘুমের মান (Quality): $rating/৫' : 'Sleep Quality Rating: $rating/5',
                    style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: AppTokens.accentLime,
                          size: 28,
                        ),
                        onPressed: () => setSheetState(() => rating = star),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    style: const TextStyle(color: AppTokens.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'মন্তব্য বা অনুভূতি' : 'Notes / Dreams / Wake Feeling',
                      labelStyle: const TextStyle(color: AppTokens.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.accentLime,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final wake = DateTime.now();
                        final bed = wake.subtract(Duration(hours: durationHours, minutes: durationMinutes));
                        final log = SleepLog(
                          id: 'sleep_${DateTime.now().microsecondsSinceEpoch}',
                          bedtime: bed,
                          wakeTime: wake,
                          qualityRating: rating,
                          notes: notesController.text.trim(),
                        );
                        widget.sleepService.addLog(log);
                        setState(() {});
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        widget.isBangla ? 'সংরক্ষণ করুন' : 'Save Sleep Record',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.sleepService.logs;
    final avgHours = widget.sleepService.getAverageSleepDurationHours();
    final weeklyDebt = widget.sleepService.calculateWeeklySleepDebt();
    final windDown = widget.sleepService.calculateWindDownTime(
      alarmHour: widget.nextAlarmHour,
      alarmMinute: widget.nextAlarmMinute,
    );
    final wakeScore = SleepService.computeWakeScore(
      ringToDismissSeconds: 45,
      snoozeCount: 0,
      minutesToFirstAction: 10,
    );

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: Text(
          widget.isBangla ? 'ঘুম ও সান্ধ্যকালীন প্রস্তুতি' : 'Sleep Analytics & Wind-down',
          style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTokens.accentLime,
        foregroundColor: Colors.black,
        tooltip: widget.isBangla ? 'ঘুম লগ করুন' : 'Log Sleep',
        onPressed: _showAddSleepSheet,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wind-down Reminder Card
            _buildWindDownCard(windDown),
            const SizedBox(height: 16),

            // Metrics Summary Grid (Avg Sleep, Sleep Debt, Wake Score)
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: widget.isBangla ? 'গড় ঘুম' : 'Average Sleep',
                    value: '${avgHours.toStringAsFixed(1)}h',
                    icon: Icons.nightlight_round,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: widget.isBangla ? 'সাপ্তাহিক ঘাটতি' : 'Sleep Debt',
                    value: weeklyDebt == 0 ? 'Optimal' : '${weeklyDebt ~/ 60}h ${weeklyDebt % 60}m',
                    icon: Icons.timelapse,
                    highlightColor: weeklyDebt > 120 ? AppTokens.errorRed : AppTokens.accentLime,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: widget.isBangla ? 'ওয়েক স্কোর' : 'Wake Score',
                    value: '${wakeScore.score}/100',
                    icon: Icons.bolt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Wake Score Diagnostic Breakdown
            _buildWakeScoreCard(wakeScore),
            const SizedBox(height: 24),

            // Recent Sleep Logs
            Text(
              widget.isBangla ? 'সাম্প্রতিক ঘুমের রেকর্ড' : 'Recent Sleep Sessions',
              style: const TextStyle(color: AppTokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surface1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTokens.border),
                ),
                child: Text(
                  widget.isBangla ? 'কোনো ঘুমের রেকর্ড পাওয়া যায়নি।' : 'No sleep sessions recorded yet.',
                  style: const TextStyle(color: AppTokens.textSecondary),
                ),
              )
            else
              ...logs.map(_buildSleepLogCard),
          ],
        ),
      ),
    );
  }

  Widget _buildWindDownCard(DateTime windDown) {
    final p = windDown.hour >= 12 ? 'PM' : 'AM';
    final h = windDown.hour == 0 ? 12 : (windDown.hour > 12 ? windDown.hour - 12 : windDown.hour);
    final m = windDown.minute.toString().padLeft(2, '0');
    final formattedTime = '$h:$m $p';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.accentLime),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTokens.accentLime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bedtime, color: AppTokens.accentLime, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isBangla ? 'সান্ধ্যকালীন প্রস্তুতি রিমাইন্ডার' : 'Tonight\'s Bedtime Wind-down',
                  style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isBangla
                      ? 'কাল সকালের অ্যালার্মের জন্য রাত $formattedTime-এ প্রস্তুতি শুরু করুন।'
                      : 'Wind down at $formattedTime for optimal 8-hour restorative sleep.',
                  style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    Color? highlightColor,
  }) {
    final color = highlightColor ?? AppTokens.accentLime;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: AppTokens.textSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWakeScoreCard(WakeScoreResult wakeScore) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isBangla ? 'ওয়েক স্কোর ডায়াগনস্টিক' : 'Wake Score Diagnostic',
                style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '${wakeScore.score}/100',
                style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isBangla ? wakeScore.breakdownBangla : wakeScore.breakdownEnglish,
            style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepLogCard(SleepLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.durationFormatted,
                style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${log.bedtime.month}/${log.bedtime.day} • ${log.notes.isNotEmpty ? log.notes : "Restful"}',
                style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(
              log.qualityRating,
              (_) => const Icon(Icons.star, color: AppTokens.accentLime, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
