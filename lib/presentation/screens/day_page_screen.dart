import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_tokens.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/repositories/entries_repository.dart';
import '../../domain/models/day_page.dart';
import '../../domain/models/journal_entry.dart';
import '../../domain/services/nightly_summary_service.dart';

class DayPageScreen extends StatefulWidget {
  final EntriesRepository repository;
  final DateTime initialDate;
  final bool isBangla;

  const DayPageScreen({
    super.key,
    required this.repository,
    required this.initialDate,
    this.isBangla = false,
  });

  @override
  State<DayPageScreen> createState() => _DayPageScreenState();
}

class _DayPageScreenState extends State<DayPageScreen> {
  late DateTime _currentDate;
  late String _dayKey;
  late DayPageModel _dayPage;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _gratitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _dayKey = _formatKey(_currentDate);
    _loadDay();
  }

  String _formatKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _loadDay() {
    setState(() {
      _dayPage = widget.repository.getDayPage(_dayKey, fallbackDate: _currentDate);
      _titleController.text = _dayPage.title ?? '';
      _reflectionController.text = _dayPage.reflectionNote ?? '';
      _gratitudeController.text = _dayPage.gratitudeNote ?? '';
    });
  }

  void _saveMetadata() {
    widget.repository.saveDayPageMetadata(
      dayKey: _dayKey,
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      reflectionNote: _reflectionController.text.trim().isEmpty ? null : _reflectionController.text.trim(),
      gratitudeNote: _gratitudeController.text.trim().isEmpty ? null : _gratitudeController.text.trim(),
    );
    _loadDay();
  }

  void _toggleStar() {
    widget.repository.saveDayPageMetadata(
      dayKey: _dayKey,
      isStarred: !_dayPage.isStarred,
    );
    _loadDay();
  }

  void _deleteEntry(JournalEntry entry) {
    widget.repository.deleteEntry(entry.id);
    _loadDay();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTokens.surface2,
        content: Text(
          widget.isBangla ? 'এন্ট্রি মুছে ফেলা হয়েছে' : 'Entry removed',
          style: const TextStyle(color: AppTokens.textPrimary),
        ),
        action: SnackBarAction(
          label: widget.isBangla ? 'পূর্বাবস্থায় ফেরান' : 'Undo',
          textColor: AppTokens.accentLime,
          onPressed: () {
            widget.repository.undo();
            _loadDay();
          },
        ),
      ),
    );
  }

  void _showAddNoteDialog({bool isMoment = false}) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTokens.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            side: const BorderSide(color: AppTokens.border),
          ),
          title: Text(
            isMoment
                ? (widget.isBangla ? 'পিন করা মুহূর্ত যোগ করুন' : 'Pin Special Moment')
                : (widget.isBangla ? 'নোট লিখুন' : 'Add Note to Day'),
            style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: textController,
            maxLines: 3,
            style: const TextStyle(color: AppTokens.textPrimary),
            decoration: InputDecoration(
              hintText: widget.isBangla ? 'এখানে বিস্তারিত লিখুন...' : 'Enter details here...',
              hintStyle: const TextStyle(color: AppTokens.textSecondary),
              filled: true,
              fillColor: AppTokens.surface1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTokens.accentLime),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                widget.isBangla ? 'বাতিল' : 'Cancel',
                style: const TextStyle(color: AppTokens.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.accentLime,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusPill)),
              ),
              onPressed: () {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  widget.repository.insertEntry(
                    JournalEntry(
                      id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
                      type: isMoment ? EntryType.momentPinned : EntryType.manualNote,
                      ts: DateTime.now(),
                      payload: {'note': text, 'title': text},
                      dayKey: _dayKey,
                      isPinned: isMoment,
                    ),
                  );
                  Navigator.pop(ctx);
                  _loadDay();
                }
              },
              child: Text(
                widget.isBangla ? 'সংরক্ষণ' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMoodEnergyDialog() {
    int selectedMood = 4;
    int selectedEnergy = 4;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTokens.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                side: const BorderSide(color: AppTokens.border),
              ),
              title: Text(
                widget.isBangla ? 'মুড ও শক্তি চেক-ইন' : 'Mood & Energy Check-in',
                style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isBangla ? 'মুড রেটিং (১-৫)' : 'Mood Rating (1-5)',
                    style: const TextStyle(color: AppTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (index) {
                      final val = index + 1;
                      final isSel = selectedMood == val;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedMood = val),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppTokens.accentLime : AppTokens.surface1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? AppTokens.accentLime : AppTokens.border),
                          ),
                          child: Text(
                            '$val',
                            style: TextStyle(
                              color: isSel ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.isBangla ? 'শক্তি রেটিং (১-৫)' : 'Energy Rating (1-5)',
                    style: const TextStyle(color: AppTokens.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (index) {
                      final val = index + 1;
                      final isSel = selectedEnergy == val;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedEnergy = val),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppTokens.accentLime : AppTokens.surface1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? AppTokens.accentLime : AppTokens.border),
                          ),
                          child: Text(
                            '$val',
                            style: TextStyle(
                              color: isSel ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    widget.isBangla ? 'বাতিল' : 'Cancel',
                    style: const TextStyle(color: AppTokens.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.accentLime,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    widget.repository.insertEntry(
                      JournalEntry(
                        id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
                        type: EntryType.moodEnergyCheckin,
                        ts: DateTime.now(),
                        mood: selectedMood,
                        energy: selectedEnergy,
                        payload: {'mood': selectedMood, 'energy': selectedEnergy},
                        dayKey: _dayKey,
                      ),
                    );
                    Navigator.pop(ctx);
                    _loadDay();
                  },
                  child: Text(
                    widget.isBangla ? 'নিশ্চিত করুন' : 'Confirm',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _generateNightlySummary() {
    widget.repository.generateAndSaveNightlySummary(_dayKey, isBangla: widget.isBangla);
    _loadDay();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale(isBangla: widget.isBangla);
    final dateDisplay = DateFormat('EEEE, MMMM d, yyyy').format(_dayPage.date);
    final score = _dayPage.computeDayScore();

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: Text(
          locale.dayPage,
          style: const TextStyle(
            color: AppTokens.accentLime,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _dayPage.isStarred ? Icons.star : Icons.star_border,
              color: _dayPage.isStarred ? AppTokens.accentLime : AppTokens.textSecondary,
            ),
            tooltip: locale.starDay,
            onPressed: _toggleStar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Day Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTokens.surface1,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateDisplay,
                          style: const TextStyle(
                            color: AppTokens.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            color: AppTokens.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.isBangla ? 'দিনের শিরোনাম যোগ করুন...' : 'Add day title...',
                            hintStyle: const TextStyle(color: AppTokens.textSecondary),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _saveMetadata(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTokens.surface2,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(color: AppTokens.accentLime),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: AppTokens.accentLime,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          locale.dayScore,
                          style: const TextStyle(
                            color: AppTokens.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Toolbar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _actionChip(
                    icon: Icons.note_add_outlined,
                    label: locale.addNote,
                    onTap: () => _showAddNoteDialog(isMoment: false),
                  ),
                  const SizedBox(width: 8),
                  _actionChip(
                    icon: Icons.push_pin_outlined,
                    label: locale.pinnedMoment,
                    onTap: () => _showAddNoteDialog(isMoment: true),
                  ),
                  const SizedBox(width: 8),
                  _actionChip(
                    icon: Icons.sentiment_satisfied_alt_outlined,
                    label: widget.isBangla ? 'মুড' : 'Mood',
                    onTap: _showMoodEnergyDialog,
                  ),
                  const SizedBox(width: 8),
                  _actionChip(
                    icon: Icons.auto_awesome,
                    label: widget.isBangla ? 'সারসংক্ষেপ' : 'Summary',
                    onTap: _generateNightlySummary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline Header
            Text(
              widget.isBangla ? 'দিনের ঘটনাবলী (টাইমলাইন)' : 'DAY TIMELINE',
              style: const TextStyle(
                color: AppTokens.accentLime,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Timeline Entries List
            if (_dayPage.entries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTokens.surface1,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppTokens.border),
                ),
                child: Center(
                  child: Text(
                    widget.isBangla
                        ? 'আজকের পৃষ্ঠায় এখনো কোনো ঘটনা লিপিবদ্ধ হয়নি।'
                        : 'No events recorded for this day yet.',
                    style: const TextStyle(color: AppTokens.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dayPage.entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final entry = _dayPage.entries[index];
                  return _buildTimelineItem(entry);
                },
              ),
            const SizedBox(height: 28),

            // Nightly 3-Line Summary Card
            Container(
              padding: const EdgeInsets.all(18),
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
                        locale.nightlySummary,
                        style: const TextStyle(
                          color: AppTokens.accentLime,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTokens.textSecondary, size: 18),
                        onPressed: _generateNightlySummary,
                        tooltip: 'Regenerate',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dayPage.nightlySummary ??
                        (widget.isBangla
                            ? 'দিনের সব কাজ শেষে সারসংক্ষেপ প্রস্তুত করতে রিফ্রেশ আইকনে চাপ দিন।'
                            : 'Tap refresh to synthesize your offline 3-line daily summary.'),
                    style: const TextStyle(
                      color: AppTokens.textPrimary,
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Evening Reflection & Gratitude
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTokens.surface1,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NightlySummaryService.getRandomReflectionPrompt(isBangla: widget.isBangla),
                    style: const TextStyle(
                      color: AppTokens.textSecondary,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reflectionController,
                    maxLines: 2,
                    style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: widget.isBangla ? 'আজকের প্রতিফলন...' : 'Evening reflection...',
                      hintStyle: const TextStyle(color: AppTokens.textSecondary),
                      filled: true,
                      fillColor: AppTokens.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTokens.border),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _saveMetadata(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    locale.gratitude,
                    style: const TextStyle(
                      color: AppTokens.accentLime,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _gratitudeController,
                    style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: widget.isBangla ? 'একটি কৃতজ্ঞতার বাক্য...' : 'One gratitude line...',
                      hintStyle: const TextStyle(color: AppTokens.textSecondary),
                      filled: true,
                      fillColor: AppTokens.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTokens.border),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _saveMetadata(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.surface2,
                        foregroundColor: AppTokens.accentLime,
                        side: const BorderSide(color: AppTokens.border),
                      ),
                      onPressed: _saveMetadata,
                      child: Text(
                        widget.isBangla ? 'সংরক্ষণ' : 'Save Reflection',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.surface1,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          border: Border.all(color: AppTokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTokens.accentLime, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(JournalEntry entry) {
    IconData icon;
    switch (entry.type) {
      case EntryType.alarmDismissed:
        icon = Icons.alarm_on_outlined;
        break;
      case EntryType.taskCompleted:
        icon = Icons.check_circle_outline;
        break;
      case EntryType.habitLogged:
        icon = Icons.repeat;
        break;
      case EntryType.focusSession:
        icon = Icons.timer_outlined;
        break;
      case EntryType.stepMilestone:
        icon = Icons.directions_walk;
        break;
      case EntryType.weatherChange:
        icon = Icons.cloud_outlined;
        break;
      case EntryType.expenseLogged:
        icon = Icons.account_balance_wallet_outlined;
        break;
      case EntryType.moodEnergyCheckin:
        icon = Icons.bolt;
        break;
      case EntryType.momentPinned:
        icon = Icons.push_pin;
        break;
      case EntryType.manualNote:
        icon = Icons.edit_note;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isPinned ? AppTokens.accentLime.withValues(alpha: 0.6) : AppTokens.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.timeFormatted,
            style: const TextStyle(
              color: AppTokens.textSecondary,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 14),
          Icon(
            icon,
            size: 18,
            color: entry.isPinned ? AppTokens.accentLime : AppTokens.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayText(isBangla: widget.isBangla),
                  style: TextStyle(
                    color: AppTokens.textPrimary,
                    fontSize: 13.5,
                    fontWeight: entry.isPinned ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (entry.mood != null || entry.energy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Mood: ${entry.mood}/5  •  Energy: ${entry.energy}/5',
                      style: const TextStyle(color: AppTokens.accentLime, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTokens.textSecondary, size: 16),
            onPressed: () => _deleteEntry(entry),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
