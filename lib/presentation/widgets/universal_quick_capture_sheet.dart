import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/enums/task_priority.dart';
import '../../domain/models/capture_item.dart';
import '../../domain/services/banglish_parser.dart';
import '../../domain/services/inbox_service.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/tasks_and_goals_repository.dart';
import 'command_palette.dart';

class UniversalQuickCaptureSheet extends StatefulWidget {
  final bool isBangla;
  final InboxService inboxService;
  final TasksAndGoalsRepository tasksRepo;
  final EntriesRepository entriesRepo;
  final VoidCallback? onSaved;

  const UniversalQuickCaptureSheet({
    super.key,
    this.isBangla = false,
    required this.inboxService,
    required this.tasksRepo,
    required this.entriesRepo,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    bool isBangla = false,
    required InboxService inboxService,
    required TasksAndGoalsRepository tasksRepo,
    required EntriesRepository entriesRepo,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalQuickCaptureSheet(
        isBangla: isBangla,
        inboxService: inboxService,
        tasksRepo: tasksRepo,
        entriesRepo: entriesRepo,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<UniversalQuickCaptureSheet> createState() =>
      _UniversalQuickCaptureSheetState();
}

class _UniversalQuickCaptureSheetState extends State<UniversalQuickCaptureSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  ParsedCaptureIntent? _parsedIntent;
  bool _isVoiceRecording = false;
  double _voiceAudioLevel = 0.4;
  String? _attachmentNote;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _reparse('');
  }

  void _onTextChanged() {
    final text = _textController.text;
    // Check if user just typed single slash "/" to open Command Palette
    if (text == '/') {
      Future.microtask(() async {
        if (!mounted) return;
        final chosen = await CommandPalette.show(context, isBangla: widget.isBangla);
        if (chosen != null && mounted) {
          _textController.text = '$chosen ';
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
      });
      return;
    }
    _reparse(text);
  }

  void _reparse(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedIntent = null;
      });
      return;
    }
    final parsed = BanglishParser.parse(text);
    setState(() {
      _parsedIntent = parsed;
    });
  }

  void _toggleIntentType() {
    if (_parsedIntent == null) return;
    const all = ParsedIntentType.values;
    final nextIdx = (all.indexOf(_parsedIntent!.intentType) + 1) % all.length;
    setState(() {
      _parsedIntent = _parsedIntent!.copyWith(intentType: all[nextIdx]);
    });
  }

  void _togglePriority() {
    if (_parsedIntent == null) return;
    final priorities = [TaskPriority.p1, TaskPriority.p2, TaskPriority.p3, TaskPriority.p4];
    final nextIdx = (priorities.indexOf(_parsedIntent!.priority) + 1) % priorities.length;
    setState(() {
      _parsedIntent = _parsedIntent!.copyWith(priority: priorities[nextIdx]);
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _parsedIntent?.dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentLime,
            onPrimary: Colors.black,
            surface: AppColors.surface1,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_parsedIntent?.dueDate ?? now),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentLime,
              onPrimary: Colors.black,
              surface: AppColors.surface1,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _parsedIntent = _parsedIntent?.copyWith(
            dueDate: DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            ),
          );
        });
      }
    }
  }

  void _handleVoiceDictation() {
    setState(() {
      _isVoiceRecording = !_isVoiceRecording;
      _voiceAudioLevel = 0.8;
    });

    if (_isVoiceRecording) {
      // Simulate speech-to-text dictation sample for Bengali/Banglish testing
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _isVoiceRecording) {
          final sampleDictations = [
            'Dudh kinte hobe kal shokal 9ta',
            'Rickshaw vara dilam 60 taka',
            'Read 20 pages of book tonight',
            'Office meeting ashchhe shombar 11am p1',
          ];
          final chosen = sampleDictations[DateTime.now().second % sampleDictations.length];
          _textController.text = chosen;
          setState(() {
            _isVoiceRecording = false;
          });
        }
      });
    }
  }

  void _saveCapture() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final intent = _parsedIntent ?? BanglishParser.parse(text);

    // Create raw capture item in Inbox
    final capture = widget.inboxService.createCapture(
      rawText: text,
      source: _isVoiceRecording ? CaptureSource.voice : CaptureSource.typed,
      attachmentUri: _attachmentNote,
    );

    // Auto-triage directly if intent has clear high confidence
    if (intent.intentType == ParsedIntentType.task) {
      widget.inboxService.convertToTask(
        capture.id,
        tasksRepo: widget.tasksRepo,
        entriesRepo: widget.entriesRepo,
        priorityOverride: intent.priority,
        dueOverride: intent.dueDate,
        titleOverride: intent.title,
      );
    } else if (intent.intentType == ParsedIntentType.expense) {
      widget.inboxService.convertToExpense(
        capture.id,
        entriesRepo: widget.entriesRepo,
        amountOverride: intent.amount,
        categoryOverride: intent.category,
      );
    } else if (intent.intentType == ParsedIntentType.note) {
      widget.inboxService.convertToRichNote(
        capture.id,
        entriesRepo: widget.entriesRepo,
        titleOverride: intent.title,
      );
    }

    widget.onSaved?.call();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface2,
        content: Row(
          children: [
            Text(
              intent.intentType.glyph,
              style: const TextStyle(
                color: AppColors.accentLime,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.isBangla
                    ? '${intent.intentType.labelBn} সংরক্ষিত হয়েছে: ${intent.title}'
                    : 'Captured as ${intent.intentType.labelEn}: ${intent.title}',
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: widget.isBangla ? 'বাতিল' : 'UNDO',
          textColor: AppColors.accentLime,
          onPressed: () {
            widget.inboxService.undoLastTriage();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intent = _parsedIntent;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Quick Command Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isBangla ? 'দ্রুত সংযোজন (ক্যাপচার)' : 'UNIVERSAL QUICK CAPTURE',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLime,
                  letterSpacing: 1.2,
                ),
              ),
              InkWell(
                onTap: () async {
                  final chosen = await CommandPalette.show(context, isBangla: widget.isBangla);
                  if (chosen != null && mounted) {
                    _textController.text = '$chosen ';
                    _textController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _textController.text.length),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '/',
                        style: TextStyle(
                          color: AppColors.accentLime,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isBangla ? 'কমান্ড' : 'Commands',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Voice Dictation Ripple Indicator (when active)
          if (_isVoiceRecording)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentLime),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isBangla ? 'শুনছি... কথা বলুন' : 'Listening... Speak in Bangla or English',
                    style: const TextStyle(
                      color: AppColors.accentLime,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 20 * _voiceAudioLevel,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.accentLime,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

          // Main Text Input Area
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: widget.isBangla
                  ? 'যেমন: দুধ কিনতে হবে কাল সকাল ৯টা অথবা রিকশা ভাড়া ৫০ টাকা...'
                  : 'e.g. Buy groceries tomorrow 9am or Rickshaw 50 tk...',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accentLime),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Live Interactive Parsed Preview Chips
          if (intent != null)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // 1. Intent Chip (Tappable to cycle intent)
                ActionChip(
                  avatar: Text(
                    intent.intentType.glyph,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  label: Text(
                    widget.isBangla ? intent.intentType.labelBn : intent.intentType.labelEn,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: AppColors.accentLime,
                  onPressed: _toggleIntentType,
                ),

                // 2. Due Date / Time Chip (Tappable to open picker)
                if (intent.dueDate != null)
                  ActionChip(
                    avatar: const Icon(Icons.schedule, size: 14, color: AppColors.textPrimary),
                    label: Text(
                      '${intent.dueDate!.day}/${intent.dueDate!.month} ${_formatTime(intent.dueDate!)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: AppColors.surface2,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: _pickDateTime,
                  ),

                // 3. Amount Chip (if expense)
                if (intent.intentType == ParsedIntentType.expense && (intent.amount ?? 0) > 0)
                  ActionChip(
                    avatar: const Text('৳', style: TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold)),
                    label: Text(
                      '${intent.amount!.toStringAsFixed(intent.amount! % 1 == 0 ? 0 : 2)} BDT',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: AppColors.surface2,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () {},
                  ),

                // 4. Priority Chip (if task, tappable to cycle)
                if (intent.intentType == ParsedIntentType.task)
                  ActionChip(
                    label: Text(
                      intent.priority.label.split(':').first,
                      style: TextStyle(
                        color: intent.priority == TaskPriority.p1
                            ? AppColors.errorRed
                            : AppColors.accentLime,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: AppColors.surface2,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: _togglePriority,
                  ),

                // 5. Category Chip
                if (intent.category != null)
                  Chip(
                    label: Text(
                      intent.category!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: AppColors.surface2,
                    side: const BorderSide(color: AppColors.border),
                  ),
              ],
            ),
          const SizedBox(height: 12),

          // Bottom Bar: Attachment Icons + Voice Button + Save Button
          Row(
            children: [
              // Voice Dictation Button
              IconButton(
                icon: Icon(
                  _isVoiceRecording ? Icons.mic : Icons.mic_none,
                  color: _isVoiceRecording ? AppColors.accentLime : AppColors.textSecondary,
                ),
                tooltip: widget.isBangla ? 'ভয়েস দিয়ে বলুন' : 'Voice Dictation',
                onPressed: _handleVoiceDictation,
              ),

              // Checklist format toggle
              IconButton(
                icon: const Icon(Icons.check_box_outlined, color: AppColors.textSecondary),
                tooltip: widget.isBangla ? 'চেকলিস্ট' : 'Checklist',
                onPressed: () {
                  if (!_textController.text.startsWith('[] ')) {
                    _textController.text = '[] ${_textController.text}';
                  }
                },
              ),

              // Photo attachment simulated
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary),
                tooltip: widget.isBangla ? 'ছবি যুক্ত করুন' : 'Attach Photo',
                onPressed: () {
                  setState(() {
                    _attachmentNote = 'mock_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  });
                },
              ),

              const Spacer(),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  widget.isBangla ? 'বাতিল' : 'CANCEL',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),

              // Primary Save Button (Lime button with black bold text)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveCapture,
                child: Text(
                  widget.isBangla ? 'সংরক্ষণ' : 'SAVE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}
