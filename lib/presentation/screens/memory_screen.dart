import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/memory_item.dart';
import '../../domain/services/ai_assistant_service.dart';

class MemoryScreen extends StatefulWidget {
  final AIAssistantService assistantService;
  final bool isBangla;

  const MemoryScreen({
    super.key,
    required this.assistantService,
    this.isBangla = false,
  });

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  MemoryKind _selectedFilter = MemoryKind.fact;
  final TextEditingController _addMemoryController = TextEditingController();

  @override
  void dispose() {
    _addMemoryController.dispose();
    super.dispose();
  }

  void _showAddMemoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          widget.isBangla ? 'নতুন স্মৃতি যোগ করুন' : 'Add Personal Memory',
          style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isBangla
                  ? 'গোপনীয়তা নিশ্চিত: পাসওয়ার্ড বা সংবেদনশীল তথ্য স্বয়ংক্রিয়ভাবে ফিল্টার করা হবে।'
                  : 'Privacy safe: Passwords or financial identifiers are automatically scrubbed.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addMemoryController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.isBangla ? 'যেমন: আমি ভোরে পড়ার অভ্যাস পছন্দ করি...' : 'e.g. Prefers studying early in the morning...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              widget.isBangla ? 'বাতিল' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: AppColors.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              final text = _addMemoryController.text.trim();
              if (text.isNotEmpty) {
                widget.assistantService.addMemory(text, kind: _selectedFilter);
                _addMemoryController.clear();
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: Text(
              widget.isBangla ? 'সংরক্ষণ' : 'Save',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.errorRed),
        ),
        title: Text(
          widget.isBangla ? 'সব স্মৃতি মুছে ফেলবেন?' : 'Clear All Memories?',
          style: AppTypography.headingMedium.copyWith(color: AppColors.errorRed),
        ),
        content: Text(
          widget.isBangla
              ? 'এটি আপনার সব সংরক্ষিত স্মৃতি স্থায়ীভাবে মুছে ফেলবে। এটি আনডু করা যাবে না।'
              : 'This will permanently delete all stored personal memories. This cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              widget.isBangla ? 'বাতিল' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.assistantService.clearAllMemories();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(
              widget.isBangla ? 'মুছে ফেলুন' : 'Clear All',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMemories = widget.assistantService.memories;
    final filtered = allMemories.where((m) => m.kind == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text(
          widget.isBangla ? 'স্মৃতি ভল্ট' : 'Personal Memory Vault',
          style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.errorRed),
            tooltip: widget.isBangla ? 'সব মুছুন' : 'Clear All',
            onPressed: allMemories.isNotEmpty ? _confirmClearAll : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.bg,
        onPressed: _showAddMemoryDialog,
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          // Filter Tabs (Fact, Preference, Episodic)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface1,
            child: Row(
              children: [
                _buildFilterChip(MemoryKind.fact, widget.isBangla ? 'তথ্য (Fact)' : 'Fact'),
                const SizedBox(width: 8),
                _buildFilterChip(MemoryKind.preference, widget.isBangla ? 'পছন্দ (Pref)' : 'Preference'),
                const SizedBox(width: 8),
                _buildFilterChip(MemoryKind.episodic, widget.isBangla ? 'সারসংক্ষেপ' : 'Episodic'),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.psychology_outlined, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            widget.isBangla ? 'কোনো স্মৃতি সংরক্ষিত নেই' : 'No memories saved yet',
                            style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isBangla
                                ? 'অ্যাসিস্ট্যান্ট কথোপকথন বা নিচের + বাটন দিয়ে স্মৃতি যোগ করুন।'
                                : 'Memories are proposed during chat or created manually via the + button.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          border: Border.all(
                            color: item.isPinned ? AppColors.accentLime : AppColors.border,
                            width: item.isPinned ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (item.isPinned) ...[
                                        const Icon(Icons.push_pin, size: 14, color: AppColors.accentLime),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.isBangla ? 'পিন করা' : 'PINNED',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.accentLime,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        item.kind.name.toUpperCase(),
                                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.text,
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: item.isPinned ? AppColors.accentLime : AppColors.textSecondary,
                                size: 20,
                              ),
                              tooltip: item.isPinned ? 'Unpin' : 'Pin',
                              onPressed: () {
                                widget.assistantService.togglePinMemory(item.id);
                                setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                              tooltip: 'Delete',
                              onPressed: () {
                                widget.assistantService.deleteMemory(item.id);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(MemoryKind kind, String label) {
    final isSelected = _selectedFilter == kind;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accentLime,
      backgroundColor: AppColors.surface2,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.bg : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = kind;
          });
        }
      },
    );
  }
}
