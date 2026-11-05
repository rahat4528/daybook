import 'package:flutter/material.dart';
import '../../domain/models/weather_and_briefing.dart';

class MorningBriefingSheet extends StatelessWidget {
  final DailyBriefing briefing;
  final VoidCallback onDismiss;

  const MorningBriefingSheet({
    super.key,
    required this.briefing,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: Color(0xFFF59E0B), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    briefing.greeting,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
            ],
          ),
          const SizedBox(height: 12),
          // Weather pill
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    briefing.weatherBrief,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Wisdom quote
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Text(
              '“${briefing.quote}”',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Today\'s Core Focus Mission:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (briefing.topTaskTitles.isEmpty)
            const Text('No pending tasks scheduled.', style: TextStyle(color: Colors.grey))
          else
            ...briefing.topTaskTitles.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onDismiss,
              child: const Text('Let\'s Seize the Day!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class EveningReviewSheet extends StatefulWidget {
  final int completedCount;
  final int pendingCount;
  final Function(int mood, String notes) onSubmit;

  const EveningReviewSheet({
    super.key,
    required this.completedCount,
    required this.pendingCount,
    required this.onSubmit,
  });

  @override
  State<EveningReviewSheet> createState() => _EveningReviewSheetState();
}

class _EveningReviewSheetState extends State<EveningReviewSheet> {
  int _selectedMood = 4;
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {'score': 1, 'emoji': '😞', 'label': 'Tough'},
    {'score': 2, 'emoji': '😐', 'label': 'Okay'},
    {'score': 3, 'emoji': '🙂', 'label': 'Good'},
    {'score': 4, 'emoji': '💪', 'label': 'Productive'},
    {'score': 5, 'emoji': '🔥', 'label': 'Unstoppable'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.nightlight_round, color: Color(0xFF6366F1), size: 26),
                  SizedBox(width: 8),
                  Text('Evening Reflection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Metric pills
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('${widget.completedCount}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      const Text('Completed', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('${widget.pendingCount}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      const Text('Rollover to Tomorrow', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('How did today feel?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.map((m) {
              final isSel = _selectedMood == m['score'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = m['score'] as int),
                child: Column(
                  children: [
                    Text(m['emoji'] as String, style: TextStyle(fontSize: isSel ? 32 : 24)),
                    const SizedBox(height: 4),
                    Text(
                      m['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? const Color(0xFF6366F1) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Gratitude or reflection note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
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
                widget.onSubmit(_selectedMood, _notesController.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Save Reflection & Close Day', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
