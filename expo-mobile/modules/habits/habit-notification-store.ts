// Habit & Interactive Notification Subsystem (Page 03)
// Preserved Tools: Expo, TypeScript, expo-notifications, Zustand, MMKV

import { create } from 'zustand';
import { MMKV } from 'react-native-mmkv';
import * as Notifications from 'expo-notifications';

export const habitStorage = new MMKV({ id: 'daybook-habits' });

export interface HabitItem {
  id: string;
  name: string;
  targetCount: number;
  reminderHour: number;
  reminderMinute: number;
  streakCount: number;
  freezeTokens: number;
}

interface HabitState {
  habits: HabitItem[];
  loadHabits: () => void;
  saveHabit: (habit: HabitItem) => void;
  handleNotificationAction: (actionId: string, habitId: string) => void;
}

export const useHabitStore = create<HabitState>((set, get) => ({
  habits: [],
  loadHabits: () => {
    const raw = habitStorage.getString('habits:list');
    if (raw) {
      set({ habits: JSON.parse(raw) });
    } else {
      const defaultHabits: HabitItem[] = [
        { id: 'h1', name: '💧 Drink 2L Water', targetCount: 1, reminderHour: 9, reminderMinute: 0, streakCount: 4, freezeTokens: 1 },
        { id: 'h2', name: '📖 Read 15m', targetCount: 1, reminderHour: 21, reminderMinute: 30, streakCount: 12, freezeTokens: 2 },
        { id: 'h3', name: '⚡ Morning Workout', targetCount: 1, reminderHour: 7, reminderMinute: 0, streakCount: 7, freezeTokens: 0 },
      ];
      habitStorage.set('habits:list', JSON.stringify(defaultHabits));
      set({ habits: defaultHabits });
    }
  },
  saveHabit: (habit) => {
    const current = get().habits;
    const exists = current.findIndex(h => h.id === habit.id);
    let updated: HabitItem[];
    if (exists >= 0) {
      updated = [...current];
      updated[exists] = habit;
    } else {
      updated = [habit, ...current];
    }
    habitStorage.set('habits:list', JSON.stringify(updated));
    set({ habits: updated });
  },
  handleNotificationAction: (actionId: string, habitId: string) => {
    const habits = get().habits;
    const target = habits.find(h => h.id === habitId);
    if (!target) return;

    if (actionId === 'ACTION_DONE') {
      const today = new Date().toISOString().split('T')[0];
      const completionKey = `habit:${habitId}:${today}`;
      if (habitStorage.getBoolean(completionKey)) return; // Idempotent check

      habitStorage.set(completionKey, true);
      const updated = habits.map(h =>
        h.id === habitId ? { ...h, streakCount: h.streakCount + 1 } : h
      );
      habitStorage.set('habits:list', JSON.stringify(updated));
      set({ habits: updated });
    } else if (actionId === 'ACTION_SNOOZE') {
      // Reschedule local reminder 30 minutes in future
      Notifications.scheduleNotificationAsync({
        content: {
          title: `⏱ Snoozed Reminder: ${target.name}`,
          body: 'Tap Done when complete.',
          categoryIdentifier: 'HABIT_ACTION',
          data: { habitId },
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
          seconds: 1800, // 30 minutes
        },
      });
    }
  },
}));

export async function configureHabitNotificationCategories() {
  await Notifications.setNotificationCategoryAsync('HABIT_ACTION', [
    {
      identifier: 'ACTION_DONE',
      buttonTitle: '✓ Done',
      options: { opensAppToForeground: false },
    },
    {
      identifier: 'ACTION_SNOOZE',
      buttonTitle: '⏱ Snooze 30m',
      options: { opensAppToForeground: false },
    },
  ]);
}
