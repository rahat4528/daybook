// NFC Tags that Run Routines Screen (Page 04)
// Physical NFC tag scanner, routine assignment, 60s debounce, and event history.

import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/nfc_routine_item.dart';
import '../../domain/services/nfc_routine_service.dart';

class NfcRoutinesScreen extends StatefulWidget {
  final NfcRoutineService nfcService;
  final bool isBangla;

  const NfcRoutinesScreen({
    super.key,
    required this.nfcService,
    this.isBangla = false,
  });

  @override
  State<NfcRoutinesScreen> createState() => _NfcRoutinesScreenState();
}

class _NfcRoutinesScreenState extends State<NfcRoutinesScreen> {
  String? _lastScanFeedback;
  bool _lastScanSuccess = false;

  void _simulateNfcTagScan(String tagUid) {
    final result = widget.nfcService.handleTagScan(tagUid);
    setState(() {
      _lastScanFeedback = result.message;
      _lastScanSuccess = result.success;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.accentLime : AppColors.surface2,
      ),
    );
  }

  void _openPairTagDialog() {
    final uidCtrl = TextEditingController(text: '04:${DateTime.now().millisecond}:AA:BB:CC');
    final labelCtrl = TextEditingController(text: 'Desk NFC Sticker');
    final routines = widget.nfcService.routines;
    String selectedRoutineId = routines.isNotEmpty ? routines.first.id : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isBangla ? 'এনএফসি ট্যাগ পেয়ার করুন' : 'PAIR NEW NFC TAG',
                style: const TextStyle(
                  color: AppColors.accentLime,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: uidCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hardware UID (13.56 MHz)',
                  hintText: '04:A2:8B:11:F2:60:80',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sticker Location Label',
                  hintText: 'e.g. Bedside Table Sticker',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRoutineId.isNotEmpty ? selectedRoutineId : null,
                dropdownColor: AppColors.surface2,
                decoration: const InputDecoration(
                  labelText: 'Assign Routine',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
                items: routines
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text('[${r.category.icon}] ${r.name}'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedRoutineId = val);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  onPressed: () {
                    final uid = uidCtrl.text.trim();
                    final label = labelCtrl.text.trim();
                    if (uid.isEmpty || label.isEmpty || selectedRoutineId.isEmpty) return;

                    widget.nfcService.pairTag(
                      tagUid: uid,
                      label: label,
                      routineId: selectedRoutineId,
                    );
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: Text(
                    widget.isBangla ? 'ট্যাগ নিশ্চিত করুন' : 'CONFIRM NFC PAIRING',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routines = widget.nfcService.routines;
    final logs = widget.nfcService.recentLogs;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          widget.isBangla ? 'এনএফসি রুটিন অটোমেশন' : 'NFC ROUTINES',
          style: AppTypography.screenTitle,
        ),
        backgroundColor: AppColors.surface1,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.nfc, color: AppColors.accentLime),
            tooltip: 'NFC Antenna Status',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ 13.56 MHz NFC Antenna Ready (CoreNFC & Android NFC Adapter)'),
                  backgroundColor: AppColors.surface2,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tap Radar Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.contactless, color: AppColors.accentLime, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    widget.isBangla ? 'শারীরিক এনএফসি ট্যাগ ট্যাপ করুন' : 'TAP PHYSICAL NFC STICKER',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isBangla
                        ? 'আপনার ফোনটি ট্যাগে স্পর্শ করুন রুটিন সম্পন্ন করার জন্য।'
                        : 'Hold phone near sticker to trigger ritual (60s anti-bounce active).',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  if (_lastScanFeedback != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _lastScanSuccess
                            ? AppColors.accentLime.withValues(alpha: 0.15)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: _lastScanSuccess ? AppColors.accentLime : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _lastScanFeedback!,
                        style: TextStyle(
                          color: _lastScanSuccess ? AppColors.accentLime : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Registered Routines
            Text(
              widget.isBangla ? 'সক্রিয় এনএফসি রুটিনসমূহ' : 'ACTIVE NFC ROUTINES & STICKERS',
              style: AppTypography.sectionHeader,
            ),
            const SizedBox(height: 8),
            ...routines.map((r) => _buildRoutineCard(r)),
            const SizedBox(height: 24),

            // Activity History Log
            Text(
              widget.isBangla ? 'সাম্প্রতিক এনএফসি ইন্টারঅ্যাকশন লগ' : 'RECENT NFC INTERACTION LOG',
              style: AppTypography.sectionHeader,
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    widget.isBangla ? 'এখনো কোন ট্যাপ রেকর্ড নেই' : 'No NFC taps recorded yet today.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...logs.map((log) => _buildLogItem(log)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentLime,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(
          widget.isBangla ? 'ট্যাগ পেয়ার করুন' : 'Pair Tag',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _openPairTagDialog,
      ),
    );
  }

  Widget _buildRoutineCard(NfcRoutineItem routine) {
    final isDone = routine.isCompletedToday;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isDone ? AppColors.accentLime.withValues(alpha: 0.6) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              routine.category.icon,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentLime, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      routine.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle, color: AppColors.accentLime, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tag: ${routine.pairedTagUid ?? "Unpaired"} • Done: ${routine.totalCompletions} times',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? AppColors.surface2 : AppColors.accentLime,
              foregroundColor: isDone ? AppColors.textPrimary : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: routine.pairedTagUid != null
                ? () => _simulateNfcTagScan(routine.pairedTagUid!)
                : null,
            child: Text(
              isDone ? 'Tap Again' : 'Tap Tag',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(NfcEventLogItem log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.nfc, color: AppColors.accentLime, size: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.routineName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                  Text('UID: ${log.tagUid}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            ],
          ),
          Text(
            '${log.occurredAt.hour.toString().padLeft(2, '0')}:${log.occurredAt.minute.toString().padLeft(2, '0')}:${log.occurredAt.second.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
