import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/day_score_model.dart';
import '../../domain/services/insights_service.dart';

class InsightsScreen extends StatefulWidget {
  final InsightsService insightsService;
  final bool isBangla;

  const InsightsScreen({
    super.key,
    required this.insightsService,
    this.isBangla = false,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late DayScoreBreakdown _todayScore;
  late WeeklyInsights _weeklyInsights;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _todayScore = widget.insightsService.computeDayScore(dayKey: todayKey);
    _weeklyInsights = widget.insightsService.computeWeeklyInsights();
  }

  void _showShareableRecapModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isBangla ? 'আজকের রিক্যাপ কার্ড' : 'Daily Line-Art Recap Card',
              style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
            ),
            const SizedBox(height: 16),
            // The Shareable Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.accentLime, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('DAYBOOK RECAP', style: AppTypography.screenTitle),
                      Text(_todayScore.dayKey, style: AppTypography.caption),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentLime, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${_todayScore.totalScore}',
                            style: AppTypography.keyMetricLime.copyWith(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _todayScore.gradeLabel(isBangla: widget.isBangla),
                              style: const TextStyle(
                                color: AppColors.accentLime,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_todayScore.tasksCompleted} Tasks • ${_todayScore.focusMinutes}m Focus • ${_todayScore.habitsDone} Habits',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      widget.isBangla
                          ? 'আজকের প্রতিটি পদক্ষেপ তোমার ভবিষ্যৎকে গড়ে তুলছে।'
                          : 'Every day is a page in the book of your life. Make it count.',
                      style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLime,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
                icon: const Icon(Icons.share, size: 18),
                label: Text(widget.isBangla ? 'শেয়ার বা সেভ করুন' : 'Share Recap Card'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recap card copied to clipboard! Ready to share.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text(
          widget.isBangla ? 'দিনস্কোর ও ইনসাইটস' : 'Day Score & Insights',
          style: AppTypography.screenTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppColors.accentLime),
            tooltip: 'Share Daily Recap',
            onPressed: _showShareableRecapModal,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Hero Day Score Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  widget.isBangla ? 'আজকের সামগ্রিক দিনস্কোর' : 'TODAY\'S DAY SCORE',
                  style: AppTypography.caption.copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: _todayScore.totalScore / 100.0,
                        strokeWidth: 10,
                        backgroundColor: AppColors.surface2,
                        valueColor: AlwaysStoppedAnimation<Color>(_todayScore.gradeColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_todayScore.totalScore}',
                          style: AppTypography.keyMetricLime.copyWith(fontSize: 40),
                        ),
                        Text(
                          '/ 100',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: _todayScore.gradeColor),
                  ),
                  child: Text(
                    _todayScore.gradeLabel(isBangla: widget.isBangla),
                    style: TextStyle(
                      color: _todayScore.gradeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 5-Pillar Breakdown Bars
          Text(
            widget.isBangla ? 'স্কোরের ৫টি স্তম্ভ' : '5-PILLAR BREAKDOWN',
            style: AppTypography.sectionHeader,
          ),
          const SizedBox(height: 8),

          _buildPillarBar(
            title: widget.isBangla ? 'কাজের সম্পাদন' : 'Task Execution',
            score: _todayScore.taskScore,
            maxScore: 30,
            metricText: '${_todayScore.tasksCompleted}/${_todayScore.tasksTotal} done',
          ),
          _buildPillarBar(
            title: widget.isBangla ? 'সকালের অ্যালার্ম নিয়মানুবর্তিতা' : 'Wake Quest Discipline',
            score: _todayScore.wakeScore,
            maxScore: 20,
            metricText: _todayScore.wakeScore >= 20 ? 'No Snooze' : 'Snoozed',
          ),
          _buildPillarBar(
            title: widget.isBangla ? 'গভীর ফোকাস সময়' : 'Deep Work Focus',
            score: _todayScore.focusScore,
            maxScore: 25,
            metricText: '${_todayScore.focusMinutes}m (Target: 90m)',
          ),
          _buildPillarBar(
            title: widget.isBangla ? 'দৈনিক অভ্যাসের ধারাবাহিকতা' : 'Habit Streaks',
            score: _todayScore.habitScore,
            maxScore: 15,
            metricText: '${_todayScore.habitsDone}/${_todayScore.habitsTotal} logged',
          ),
          _buildPillarBar(
            title: widget.isBangla ? 'রাতের আত্মপর্যালোচনা' : 'Nightly Reflection',
            score: _todayScore.reflectionScore,
            maxScore: 10,
            metricText: _todayScore.hasEveningReview ? 'Completed' : 'Pending',
          ),
          const SizedBox(height: 16),

          // 3. Weekly 7-Day Trajectory Bar Chart
          Text(
            widget.isBangla ? 'সাপ্তাহিক গতিপথ (৭ দিন)' : '7-DAY WEEKLY TRAJECTORY',
            style: AppTypography.sectionHeader,
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Average: ${_weeklyInsights.averageScore}',
                      style: AppTypography.caption.copyWith(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Best: ${_weeklyInsights.bestDayScore} (${_weeklyInsights.bestDayKey.substring(5)})',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _weeklyInsights.dailyScores.map((score) {
                      final heightRatio = (score.totalScore / 100.0).clamp(0.05, 1.0);
                      final dayLabel = score.dayKey.substring(8); // dd
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${score.totalScore}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: 70 * heightRatio,
                            decoration: BoxDecoration(
                              color: score.totalScore >= 70 ? AppColors.accentLime : AppColors.surface2,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(dayLabel, style: AppTypography.caption),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Weekly Summary Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: widget.isBangla ? 'মোট ফোকাস' : 'Total Focus',
                  value: '${_weeklyInsights.totalFocusMinutes}m',
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: widget.isBangla ? 'সম্পন্ন কাজ' : 'Tasks Done',
                  value: '${_weeklyInsights.totalTasksCompleted}',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricTile(
            title: widget.isBangla ? 'সর্বোচ্চ উৎপাদনশীল সময়' : 'Peak Energy Window',
            value: _weeklyInsights.peakEnergyPeriod,
            icon: Icons.bolt,
          ),
        ],
      ),
    );
  }

  Widget _buildPillarBar({
    required String title,
    required double score,
    required double maxScore,
    required String metricText,
  }) {
    final ratio = (score / maxScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '${score.toStringAsFixed(1)} / ${maxScore.toInt()} pts',
                style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.surface2,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentLime),
            ),
          ),
          const SizedBox(height: 4),
          Text(metricText, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentLime, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
