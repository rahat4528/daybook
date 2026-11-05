import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../domain/models/capture_item.dart';
import '../../domain/services/banglish_parser.dart';
import '../../domain/services/inbox_service.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/tasks_and_goals_repository.dart';
import '../widgets/universal_quick_capture_sheet.dart';

class InboxScreen extends StatefulWidget {
  final bool isBangla;
  final InboxService inboxService;
  final TasksAndGoalsRepository tasksRepo;
  final EntriesRepository entriesRepo;

  const InboxScreen({
    super.key,
    this.isBangla = false,
    required this.inboxService,
    required this.tasksRepo,
    required this.entriesRepo,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    widget.inboxService.addListener(_onInboxChanged);
  }

  void _onInboxChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.inboxService.removeListener(_onInboxChanged);
    super.dispose();
  }

  void _triageToTask(CaptureItem item) {
    final parsed = BanglishParser.parse(item.rawText);
    widget.inboxService.convertToTask(
      item.id,
      tasksRepo: widget.tasksRepo,
      entriesRepo: widget.entriesRepo,
    );
    _showTriageToast(
      widget.isBangla
          ? 'কাজে রূপান্তরিত হয়েছে: ${parsed.title}'
          : 'Converted to Task: ${parsed.title}',
    );
  }

  void _triageToExpense(CaptureItem item) {
    final exp = widget.inboxService.convertToExpense(
      item.id,
      entriesRepo: widget.entriesRepo,
    );
    _showTriageToast(
      widget.isBangla
          ? 'খরচে সংরক্ষিত: ${exp['amount']} ৳ (${exp['category']})'
          : 'Converted to Expense: ${exp['amount']} BDT (${exp['category']})',
    );
  }

  void _triageToNote(CaptureItem item) {
    final note = widget.inboxService.convertToRichNote(
      item.id,
      entriesRepo: widget.entriesRepo,
    );
    _showTriageToast(
      widget.isBangla
          ? 'নোটে সংরক্ষিত: ${note.title}'
          : 'Saved as Note: ${note.title}',
    );
  }

  void _archiveCapture(CaptureItem item) {
    widget.inboxService.archiveCapture(item.id);
    _showTriageToast(
      widget.isBangla ? 'আর্কাইভ করা হয়েছে' : 'Capture archived',
    );
  }

  void _showTriageToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface2,
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary),
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
  Widget build(BuildContext context) {
    final unprocessed = widget.inboxService.getUnprocessedCaptures();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              widget.isBangla ? 'ইনবক্স ট্রায়াজ' : 'INBOX TRIAGE',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: unprocessed.isNotEmpty
                    ? AppColors.accentLime
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${unprocessed.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: unprocessed.isNotEmpty ? Colors.black : AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.inboxService.canUndo)
            IconButton(
              icon: const Icon(Icons.undo, color: AppColors.accentLime),
              tooltip: widget.isBangla ? 'পূর্বাবস্থায় ফেরান' : 'Undo',
              onPressed: () => widget.inboxService.undoLastTriage(),
            ),
        ],
      ),
      body: unprocessed.isEmpty
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
                    child: const Text('📥', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isBangla ? 'ইনবক্স খালি!' : 'Inbox Zero!',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isBangla
                        ? 'শেয়ার শিট বা কুইক অ্যাড থেকে আসা সব তথ্য প্রক্রিয়া করা হয়েছে।'
                        : 'All incoming captures from Share sheet & Quick Add are triaged.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: unprocessed.length,
              itemBuilder: (context, index) {
                final item = unprocessed[index];
                final parsed = BanglishParser.parse(item.rawText);

                return Dismissible(
                  key: Key(item.id),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentLime.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentLime),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.accentLime),
                        const SizedBox(width: 8),
                        Text(
                          widget.isBangla ? 'কাজ হিসেবে সেভ' : 'Convert to Task',
                          style: const TextStyle(
                            color: AppColors.accentLime,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.isBangla ? 'খরচ হিসেবে সেভ' : 'Convert to Expense',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('৳', style: TextStyle(color: AppColors.accentLime, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      _triageToTask(item);
                    } else {
                      _triageToExpense(item);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source Tag & Timestamp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.source.name.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(item.createdAt),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Raw Text
                        Text(
                          item.rawText,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Suggested Parsed Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '${parsed.intentType.glyph} ${parsed.intentType.labelEn}',
                                style: const TextStyle(
                                  color: AppColors.accentLime,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (parsed.dueDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '📅 ${parsed.dueDate!.day}/${parsed.dueDate!.month}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (parsed.amount != null && parsed.amount! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '৳ ${parsed.amount}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons Bar
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.check, size: 16, color: AppColors.accentLime),
                              label: Text(
                                widget.isBangla ? 'কাজ' : 'Task',
                                style: const TextStyle(color: AppColors.accentLime, fontSize: 12),
                              ),
                              onPressed: () => _triageToTask(item),
                            ),
                            TextButton.icon(
                              icon: const Text('৳', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              label: Text(
                                widget.isBangla ? 'খরচ' : 'Expense',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                              ),
                              onPressed: () => _triageToExpense(item),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_note, size: 16, color: AppColors.textSecondary),
                              label: Text(
                                widget.isBangla ? 'নোট' : 'Note',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              onPressed: () => _triageToNote(item),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.archive_outlined, size: 18, color: AppColors.textSecondary),
                              tooltip: widget.isBangla ? 'আর্কাইভ' : 'Archive',
                              onPressed: () => _archiveCapture(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentLime,
        foregroundColor: Colors.black,
        tooltip: widget.isBangla ? 'নতুন ক্যাপচার' : 'Quick Capture',
        onPressed: () {
          UniversalQuickCaptureSheet.show(
            context,
            isBangla: widget.isBangla,
            inboxService: widget.inboxService,
            tasksRepo: widget.tasksRepo,
            entriesRepo: widget.entriesRepo,
          );
        },
        child: const Icon(Icons.add, size: 28),
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
