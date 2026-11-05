import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/enums/core_enums.dart';
import '../../domain/models/alarm_item.dart';
import '../../domain/services/alarm_health_service.dart';
import '../../domain/services/sleep_service.dart';
import 'alarm_health_screen.dart';
import 'sleep_tracker_screen.dart';
import 'wake_quest_screen.dart';

class AlarmScreen extends StatefulWidget {
  final List<AlarmItem> alarms;
  final Function(List<AlarmItem>) onAlarmsUpdated;
  final bool isBangla;

  const AlarmScreen({
    super.key,
    required this.alarms,
    required this.onAlarmsUpdated,
    this.isBangla = false,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AlarmHealthService _healthService = AlarmHealthService();
  final SleepService _sleepService = SleepService();

  void _showAddAlarmDialog() {
    int hour = 6;
    int minute = 30;
    String label = 'Morning Wake-up';
    AlarmChallengeType challenge = AlarmChallengeType.math;
    ChallengeDifficulty difficulty = ChallengeDifficulty.medium;
    SoundPack soundPack = SoundPack.classicBell;
    bool isStrictMode = false;
    bool hasPreChime = false;
    final List<int> repeatDays = [1, 2, 3, 4, 5]; // Mon-Fri default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isBangla ? 'স্মার্ট ওয়েক কোয়েস্ট সেট করুন' : 'Set Smart Alarm',
                          style: const TextStyle(
                            color: AppTokens.accentLime,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTokens.textSecondary),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<int>(
                          value: hour,
                          dropdownColor: AppTokens.surface2,
                          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                          items: List.generate(24, (i) => i).map((h) {
                            final p = h >= 12 ? 'PM' : 'AM';
                            final d = h == 0 ? 12 : (h > 12 ? h - 12 : h);
                            return DropdownMenuItem(value: h, child: Text('$d $p'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => hour = val);
                          },
                        ),
                        const Text(' : ', style: TextStyle(color: AppTokens.accentLime, fontSize: 28, fontWeight: FontWeight.bold)),
                        DropdownButton<int>(
                          value: minute,
                          dropdownColor: AppTokens.surface2,
                          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                          items: List.generate(12, (i) => i * 5).map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(m.toString().padLeft(2, '0')),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => minute = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Label input
                    TextField(
                      style: const TextStyle(color: AppTokens.textPrimary),
                      decoration: InputDecoration(
                        labelText: widget.isBangla ? 'অ্যালার্মের নাম' : 'Alarm Label',
                        labelStyle: const TextStyle(color: AppTokens.textSecondary),
                        filled: true,
                        fillColor: AppTokens.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      controller: TextEditingController(text: label),
                      onChanged: (val) => label = val,
                    ),
                    const SizedBox(height: 14),

                    // Challenge Selector
                    Text(
                      widget.isBangla ? 'ওয়েক কোয়েস্ট চ্যালেঞ্জ' : 'Wake Challenge Type',
                      style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<AlarmChallengeType>(
                      value: challenge,
                      dropdownColor: AppTokens.surface2,
                      style: const TextStyle(color: AppTokens.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTokens.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: AlarmChallengeType.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(widget.isBangla ? c.banglaDisplayName : c.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => challenge = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Sound Pack Selector
                    Text(
                      widget.isBangla ? 'সাউন্ড প্যাক ও সুর' : 'Sound Pack Tone',
                      style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<SoundPack>(
                      value: soundPack,
                      dropdownColor: AppTokens.surface2,
                      style: const TextStyle(color: AppTokens.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTokens.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: SoundPack.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(widget.isBangla ? s.banglaDisplayName : s.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => soundPack = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Difficulty & Strict Mode Switches
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ChallengeDifficulty>(
                            value: difficulty,
                            dropdownColor: AppTokens.surface2,
                            style: const TextStyle(color: AppTokens.textPrimary),
                            decoration: InputDecoration(
                              labelText: widget.isBangla ? 'কঠিনতা' : 'Difficulty',
                              labelStyle: const TextStyle(color: AppTokens.textSecondary),
                              filled: true,
                              fillColor: AppTokens.surface2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ChallengeDifficulty.values.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => difficulty = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        widget.isBangla ? 'স্ট্রিক্ট মোড (স্নুজ নিষ্ক্রিয়)' : 'Strict Mode (No Snooze)',
                        style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13.5),
                      ),
                      activeColor: AppTokens.accentLime,
                      value: isStrictMode,
                      onChanged: (val) => setModalState(() => isStrictMode = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        widget.isBangla ? 'নরম প্রাক-অ্যালার্ম চাইম (১৫ মিনিট আগে)' : 'Soft Pre-alarm Chime (15m before)',
                        style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13.5),
                      ),
                      activeColor: AppTokens.accentLime,
                      value: hasPreChime,
                      onChanged: (val) => setModalState(() => hasPreChime = val),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.accentLime,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final newAlarm = AlarmItem(
                            id: 'alm_${DateTime.now().microsecondsSinceEpoch}',
                            hour: hour,
                            minute: minute,
                            label: label.isEmpty ? 'Wake Quest' : label,
                            repeatDays: repeatDays,
                            challengeType: challenge,
                            difficulty: difficulty,
                            soundPack: soundPack,
                            isStrictMode: isStrictMode,
                            hasPreAlarmChime: hasPreChime,
                          );
                          final updated = List<AlarmItem>.from(widget.alarms)..add(newAlarm);
                          widget.onAlarmsUpdated(updated);
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          widget.isBangla ? 'অ্যালার্ম সংরক্ষণ করুন' : 'Save Alarm',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _launchWakeQuestPreview(AlarmItem alarm) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WakeQuestScreen(
          alarm: alarm,
          isBangla: widget.isBangla,
          onDismissed: () => Navigator.of(context).pop(),
          onIntentionCaptured: (intention) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTokens.surface2,
                content: Text(
                  widget.isBangla ? 'সংকল্প সংরক্ষিত: $intention' : 'Intention logged: $intention',
                  style: const TextStyle(color: AppTokens.accentLime),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: const Text(
          'Smart Alarms & Challenges',
          style: TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.nightlight_round, color: AppTokens.accentLime),
            tooltip: widget.isBangla ? 'ঘুম ট্র্যাকার' : 'Sleep Analytics',
            onPressed: () {
              final nextAlarm = widget.alarms.isNotEmpty ? widget.alarms.first : const AlarmItem(id: 'def', hour: 6, minute: 30);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SleepTrackerScreen(
                    sleepService: _sleepService,
                    isBangla: widget.isBangla,
                    nextAlarmHour: nextAlarm.hour,
                    nextAlarmMinute: nextAlarm.minute,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined, color: AppTokens.accentLime),
            tooltip: widget.isBangla ? 'অ্যালার্ম ডায়াগনস্টিক' : 'Alarm Diagnostics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AlarmHealthScreen(
                    healthService: _healthService,
                    isBangla: widget.isBangla,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppTokens.accentLime),
            onPressed: _showAddAlarmDialog,
          ),
        ],
      ),
      body: widget.alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alarm_off, size: 54, color: AppTokens.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    widget.isBangla ? 'কোনো অ্যালার্ম কনফিগার করা নেই।' : 'No alarms configured.',
                    style: const TextStyle(color: AppTokens.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.accentLime,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showAddAlarmDialog,
                    icon: const Icon(Icons.add),
                    label: Text(
                      widget.isBangla ? 'প্রথম স্মার্ট অ্যালার্ম তৈরি করুন' : 'Create First Smart Alarm',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.alarms.length,
              itemBuilder: (ctx, i) {
                final alarm = widget.alarms[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTokens.surface1,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(
                      color: alarm.isEnabled ? AppTokens.accentLime.withValues(alpha: 0.6) : AppTokens.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.timeFormatted,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: alarm.isEnabled ? AppTokens.textPrimary : AppTokens.textSecondary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                alarm.label,
                                style: const TextStyle(fontSize: 13, color: AppTokens.textSecondary),
                              ),
                            ],
                          ),
                          Switch(
                            value: alarm.isEnabled,
                            activeColor: AppTokens.accentLime,
                            activeTrackColor: AppTokens.accentLime.withValues(alpha: 0.3),
                            inactiveTrackColor: AppTokens.surface2,
                            onChanged: (val) {
                              final updated = List<AlarmItem>.from(widget.alarms);
                              updated[i] = alarm.copyWith(isEnabled: val);
                              widget.onAlarmsUpdated(updated);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Challenge badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTokens.surface2,
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              border: Border.all(color: AppTokens.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 13, color: AppTokens.accentLime),
                                const SizedBox(width: 4),
                                Text(
                                  '${alarm.challengeType.displayName} (${alarm.difficulty.name})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTokens.accentLime,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Interactive Test simulator button
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: AppTokens.accentLime),
                            onPressed: () => _launchWakeQuestPreview(alarm),
                            icon: const Icon(Icons.play_circle_outline, size: 16),
                            label: const Text('Test Challenge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTokens.textSecondary),
                            onPressed: () {
                              final updated = List<AlarmItem>.from(widget.alarms)..removeAt(i);
                              widget.onAlarmsUpdated(updated);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmDialog,
        backgroundColor: AppTokens.accentLime,
        foregroundColor: Colors.black,
        child: const Icon(Icons.alarm_add),
      ),
    );
  }
}
