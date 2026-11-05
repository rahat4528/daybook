import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/services/wellness_service.dart';
import '../../data/repositories/entries_repository.dart';

class WellnessModal extends StatefulWidget {
  final bool isBangla;
  final WellnessService wellnessService;
  final EntriesRepository entriesRepo;
  final VoidCallback? onSaved;

  const WellnessModal({
    super.key,
    this.isBangla = false,
    required this.wellnessService,
    required this.entriesRepo,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    bool isBangla = false,
    required WellnessService wellnessService,
    required EntriesRepository entriesRepo,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => WellnessModal(
        isBangla: isBangla,
        wellnessService: wellnessService,
        entriesRepo: entriesRepo,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<WellnessModal> createState() => _WellnessModalState();
}

class _WellnessModalState extends State<WellnessModal> {
  int _moodScore = 4;
  int _energyScore = 4;
  final Set<String> _selectedTags = {'Sleep', 'Work'};
  final TextEditingController _reflectionController = TextEditingController();

  static const List<Map<String, String>> _availableFactors = [
    {'en': 'Sleep', 'bn': 'ঘুম', 'icon': '🛌'},
    {'en': 'Work', 'bn': 'কাজ', 'icon': '💼'},
    {'en': 'Family', 'bn': 'পরিবার', 'icon': '👨‍👩‍👧'},
    {'en': 'Health', 'bn': 'স্বাস্থ্য', 'icon': '🏃'},
    {'en': 'Social', 'bn': 'আড্ডা', 'icon': '☕'},
    {'en': 'Weather', 'bn': 'আবহাওয়া', 'icon': '🌦️'},
    {'en': 'Finance', 'bn': 'অর্থনৈতিক', 'icon': '💰'},
  ];

  void _save() {
    widget.wellnessService.logCheckin(
      moodScore: _moodScore,
      energyScore: _energyScore,
      tags: _selectedTags.toList(),
      reflection: _reflectionController.text.trim().isNotEmpty
          ? _reflectionController.text.trim()
          : null,
      entriesRepo: widget.entriesRepo,
    );

    widget.onSaved?.call();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface2,
        content: Text(
          widget.isBangla
              ? 'মুড ও শক্তি চেক-ইন সংরক্ষিত হয়েছে (মুড: $_moodScore/৫, শক্তি: $_energyScore/৫)'
              : 'Wellness logged (Mood: $_moodScore/5, Energy: $_energyScore/5)',
          style: const TextStyle(color: AppColors.accentLime),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Text('☯', style: TextStyle(color: AppColors.accentLime, fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                widget.isBangla ? 'মুড ও শক্তি চেক-ইন' : 'MOOD & ENERGY CHECK-IN',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mood Rating Selector
          Text(
            widget.isBangla ? 'আপনার মানসিক অবস্থা কেমন?' : 'How is your mental state?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (idx) {
              final score = idx + 1;
              final isSelected = _moodScore == score;
              final moodGlyphs = ['😞', '🙁', '😐', '🙂', '✨'];
              return InkWell(
                onTap: () => setState(() => _moodScore = score),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentLime : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accentLime : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(moodGlyphs[idx], style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Physical Energy Rating Selector
          Text(
            widget.isBangla ? 'শারীরিক শক্তির মাত্রা কেমন?' : 'What is your physical energy level?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (idx) {
              final score = idx + 1;
              final isSelected = _energyScore == score;
              final energyGlyphs = ['🪫', '🔋', '⚡', '🔥', '⚡⚡'];
              return InkWell(
                onTap: () => setState(() => _energyScore = score),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentLime : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accentLime : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(energyGlyphs[idx], style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Factor Tags
          Text(
            widget.isBangla ? 'প্রধান প্রভাবকসমূহ' : 'Key Factors & Context',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableFactors.map((f) {
              final tagKey = f['en']!;
              final isSelected = _selectedTags.contains(tagKey);
              return FilterChip(
                avatar: Text(f['icon']!, style: const TextStyle(fontSize: 13)),
                label: Text(widget.isBangla ? f['bn']! : f['en']!),
                selected: isSelected,
                selectedColor: AppColors.accentLime,
                backgroundColor: AppColors.surface2,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.accentLime : AppColors.border,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tagKey);
                    } else {
                      _selectedTags.remove(tagKey);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Micro Reflection Text Field
          TextField(
            controller: _reflectionController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.isBangla ? 'ছোট মন্তব্য (ঐচ্ছিক)...' : 'Micro reflection note (optional)...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _save,
            child: Text(
              widget.isBangla ? 'লগ সম্পন্ন করুন' : 'COMPLETE CHECK-IN',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}
