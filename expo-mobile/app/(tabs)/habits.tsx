import React, { useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Colors, Spacing, Radius } from '../../shared/theme/tokens';
import { useHabitStore } from '../../modules/habits/habit-notification-store';

export default function HabitsTabScreen() {
  const { habits, loadHabits, handleNotificationAction } = useHabitStore();

  useEffect(() => {
    loadHabits();
  }, []);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.headerTitle}>HABITS FROM NOTIFICATIONS</Text>
      <Text style={styles.headerSubtitle}>Actionable Categories • Zustand • MMKV</Text>

      {/* Interactive Notification Action Simulator */}
      <View style={styles.noticeBox}>
        <Text style={styles.noticeTitle}>INTERACTIVE LOCK SCREEN ACTIONS</Text>
        <Text style={styles.noticeDesc}>
          When habit reminders trigger, tap Done or Snooze 30m directly from the push banner.
        </Text>
      </View>

      <Text style={styles.sectionTitle}>ACTIVE HABITS & STREAKS ({habits.length})</Text>
      {habits.map(h => (
        <View key={h.id} style={styles.habitCard}>
          <View style={styles.habitInfo}>
            <Text style={styles.habitName}>{h.name}</Text>
            <Text style={styles.habitStreak}>🔥 {h.streakCount} Day Streak • ❄️ {h.freezeTokens} Freezes</Text>
          </View>
          <View style={styles.actionRow}>
            <TouchableOpacity
              style={styles.snoozeBtn}
              onPress={() => handleNotificationAction('ACTION_SNOOZE', h.id)}
            >
              <Text style={styles.snoozeText}>⏱ Snooze</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.doneBtn}
              onPress={() => handleNotificationAction('ACTION_DONE', h.id)}
            >
              <Text style={styles.doneText}>✓ Done</Text>
            </TouchableOpacity>
          </View>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.bg },
  content: { padding: Spacing.md },
  headerTitle: { fontSize: 20, fontWeight: '900', color: Colors.textPrimary },
  headerSubtitle: { fontSize: 11, color: Colors.accentLime, marginBottom: Spacing.md },
  noticeBox: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.accentLimeBorder,
    marginBottom: Spacing.lg,
  },
  noticeTitle: { color: Colors.accentLime, fontSize: 11, fontWeight: 'bold' },
  noticeDesc: { color: Colors.textSecondary, fontSize: 12, marginTop: 4 },
  sectionTitle: { fontSize: 12, fontWeight: 'bold', color: Colors.textSecondary, marginBottom: 8 },
  habitCard: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  habitInfo: { flex: 1 },
  habitName: { color: Colors.textPrimary, fontSize: 15, fontWeight: 'bold' },
  habitStreak: { color: Colors.accentLime, fontSize: 11, marginTop: 4 },
  actionRow: { flexDirection: 'row', gap: 6 },
  snoozeBtn: {
    backgroundColor: Colors.surface2,
    paddingVertical: 8,
    paddingHorizontal: 10,
    borderRadius: Radius.button,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  snoozeText: { color: Colors.textSecondary, fontSize: 11, fontWeight: 'bold' },
  doneBtn: {
    backgroundColor: Colors.accentLime,
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: Radius.button,
  },
  doneText: { color: '#000000', fontSize: 11, fontWeight: 'bold' },
});
