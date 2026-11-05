import 'package:flutter/material.dart';
import '../../core/enums/core_enums.dart';
import '../../domain/models/alarm_item.dart';
import '../widgets/challenge_dialogs.dart';

class AlarmScreen extends StatefulWidget {
  final List<AlarmItem> alarms;
  final Function(List<AlarmItem>) onAlarmsUpdated;

  const AlarmScreen({
    super.key,
    required this.alarms,
    required this.onAlarmsUpdated,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  void _showAddAlarmDialog() {
    int hour = 6;
    int minute = 30;
    String label = 'Morning Wake-up';
    AlarmChallengeType challenge = AlarmChallengeType.math;
    ChallengeDifficulty difficulty = ChallengeDifficulty.medium;
    final List<int> repeatDays = [1, 2, 3, 4, 5]; // Mon-Fri default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                        const Text('Set Smart Alarm',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
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
                          items: List.generate(24, (i) => i).map((h) {
                            final p = h >= 12 ? 'PM' : 'AM';
                            final d = h == 0 ? 12 : (h > 12 ? h - 12 : h);
                            return DropdownMenuItem(value: h, child: Text('$d $p'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => hour = val);
                          },
                        ),
                        const Text(' : ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        DropdownButton<int>(
                          value: minute,
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
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Alarm Label',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: label),
                      onChanged: (val) => label = val,
                    ),
                    const SizedBox(height: 16),
                    const Text('Wake-Up Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: AlarmChallengeType.values.map((c) {
                        final isSel = challenge == c;
                        return ChoiceChip(
                          avatar: Icon(
                            c == AlarmChallengeType.math
                                ? Icons.calculate
                                : (c == AlarmChallengeType.memorySequence
                                    ? Icons.grid_view
                                    : (c == AlarmChallengeType.movement
                                        ? Icons.directions_walk
                                        : Icons.qr_code_scanner)),
                            size: 16,
                          ),
                          label: Text(c.displayName, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => challenge = c);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Challenge Difficulty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: ChallengeDifficulty.values.map((d) {
                        final isSel = difficulty == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(d.name.toUpperCase()),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setModalState(() => difficulty = d);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Repeat Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        {'name': 'M', 'day': 1},
                        {'name': 'T', 'day': 2},
                        {'name': 'W', 'day': 3},
                        {'name': 'T', 'day': 4},
                        {'name': 'F', 'day': 5},
                        {'name': 'S', 'day': 6},
                        {'name': 'S', 'day': 7},
                      ].map((item) {
                        final d = item['day'] as int;
                        final active = repeatDays.contains(d);
                        return FilterChip(
                          label: Text(item['name'] as String),
                          selected: active,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                repeatDays.add(d);
                              } else {
                                repeatDays.remove(d);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                        onPressed: () {
                          final newAlarm = AlarmItem(
                            id: 'alm_${DateTime.now().microsecondsSinceEpoch}',
                            hour: hour,
                            minute: minute,
                            label: label.isEmpty ? 'Alarm' : label,
                            repeatDays: repeatDays,
                            challengeType: challenge,
                            difficulty: difficulty,
                          );
                          final updated = List<AlarmItem>.from(widget.alarms)..add(newAlarm);
                          widget.onAlarmsUpdated(updated);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Save Alarm', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Alarms & Challenges', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: _showAddAlarmDialog,
          ),
        ],
      ),
      body: widget.alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alarm_off, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No alarms configured.'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddAlarmDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Smart Alarm'),
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
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: alarm.isEnabled
                          ? const Color(0xFF6366F1).withOpacity(0.4)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                                  color: alarm.isEnabled
                                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                      : Colors.grey,
                                ),
                              ),
                              Text(
                                alarm.label,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          Switch(
                            value: alarm.isEnabled,
                            activeColor: const Color(0xFF6366F1),
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
                              color: const Color(0xFF8B5CF6).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF8B5CF6)),
                                const SizedBox(width: 4),
                                Text(
                                  '${alarm.challengeType.displayName} (${alarm.difficulty.name})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Interactive Test simulator button
                          TextButton.icon(
                            onPressed: () async {
                              final solved = await ChallengeSimulator.launchChallenge(
                                context: context,
                                type: alarm.challengeType,
                                difficulty: alarm.difficulty,
                                qrHash: alarm.qrHash,
                              );
                              if (context.mounted && solved) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 Challenge Solved! Alarm successfully dismissed.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_circle_outline, size: 16),
                            label: const Text('Test Challenge', style: TextStyle(fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
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
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.alarm_add),
      ),
    );
  }
}
