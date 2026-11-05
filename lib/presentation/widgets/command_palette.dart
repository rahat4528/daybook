import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';

class CommandAction {
  final String trigger;
  final String titleEn;
  final String titleBn;
  final String descriptionEn;
  final String descriptionBn;
  final String glyph;

  const CommandAction({
    required this.trigger,
    required this.titleEn,
    required this.titleBn,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.glyph,
  });
}

const List<CommandAction> kDayBookCommands = [
  CommandAction(
    trigger: '/task',
    titleEn: 'Create Task',
    titleBn: 'নতুন কাজ যোগ করুন',
    descriptionEn: 'Add action item with due date and priority',
    descriptionBn: 'সময়সীমা ও গুরুত্বসহ কাজ যুক্ত করুন',
    glyph: '✓',
  ),
  CommandAction(
    trigger: '/expense',
    titleEn: 'Log Expense',
    titleBn: 'খরচের হিসাব রাখুন',
    descriptionEn: 'Quick spend log with BDT amount and category',
    descriptionBn: 'টাকার পরিমাণ ও খাতসহ খরচ সংরক্ষণ করুন',
    glyph: '৳',
  ),
  CommandAction(
    trigger: '/note',
    titleEn: 'New Rich Note',
    titleBn: 'নতুন নোট লিখুন',
    descriptionEn: 'Capture memo, checklist, or link',
    descriptionBn: 'চেকলিস্ট বা লিংকসহ মেমো লিখুন',
    glyph: '✎',
  ),
  CommandAction(
    trigger: '/habit',
    titleEn: 'Log Habit',
    titleBn: 'অভ্যাস চিহ্নিত করুন',
    descriptionEn: 'Record water, reading, or workout streak',
    descriptionBn: 'পানি, বই পড়া বা ব্যায়ামের অগ্রগতি সংরক্ষণ করুন',
    glyph: '⚡',
  ),
  CommandAction(
    trigger: '/mood',
    titleEn: 'Log Mood & Energy',
    titleBn: 'মন ও শক্তি রেকর্ড করুন',
    descriptionEn: 'Rate mental wellness and daily energy level',
    descriptionBn: 'মানসিক অবস্থা ও শারীরিক শক্তি সংরক্ষণ করুন',
    glyph: '☯',
  ),
  CommandAction(
    trigger: '/alarm',
    titleEn: 'Set Wake Quest Alarm',
    titleBn: 'অ্যালার্ম নির্ধারণ করুন',
    descriptionEn: 'Schedule math/movement challenge morning alarm',
    descriptionBn: 'চ্যালেঞ্জসহ সকালের অ্যালার্ম সেট করুন',
    glyph: '⏰',
  ),
  CommandAction(
    trigger: '/plan',
    titleEn: 'Open Time-Block Planner',
    titleBn: 'দৈনিক পরিকল্পনা খুলুন',
    descriptionEn: 'Energy-aware time blocking and Eat-the-Frog',
    descriptionBn: 'শক্তিভিত্তিক সময় পরিকল্পনা পরিচালনা করুন',
    glyph: '▦',
  ),
];

class CommandPalette extends StatefulWidget {
  final bool isBangla;
  final ValueChanged<String> onSelectCommand;

  const CommandPalette({
    super.key,
    this.isBangla = false,
    required this.onSelectCommand,
  });

  static Future<String?> show(BuildContext context, {bool isBangla = false}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommandPalette(
        isBangla: isBangla,
        onSelectCommand: (cmd) => Navigator.pop(ctx, cmd),
      ),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  List<CommandAction> _filteredCommands = kDayBookCommands;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = kDayBookCommands;
      } else {
        _filteredCommands = kDayBookCommands.where((cmd) {
          return cmd.trigger.toLowerCase().contains(query) ||
              cmd.titleEn.toLowerCase().contains(query) ||
              cmd.titleBn.contains(query) ||
              cmd.descriptionEn.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              const Text(
                '/',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLime,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isBangla ? 'কমান্ড প্যালেট' : 'COMMAND PALETTE',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.isBangla ? 'কমান্ড খুঁজুন...' : 'Type a command or filter...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.accentLime),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Commands List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredCommands.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.border,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final cmd = _filteredCommands[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cmd.glyph,
                        style: const TextStyle(
                          color: AppColors.accentLime,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          cmd.trigger,
                          style: const TextStyle(
                            color: AppColors.accentLime,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.isBangla ? cmd.titleBn : cmd.titleEn,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      widget.isBangla ? cmd.descriptionBn : cmd.descriptionEn,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      widget.onSelectCommand(cmd.trigger);
                    },
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
