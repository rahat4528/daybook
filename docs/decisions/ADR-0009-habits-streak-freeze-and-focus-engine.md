# ADR-0009: Habits Streak Freeze Token System, Flip-to-Focus Engine, and Wellness Logging

## Status
Accepted

## Context
Habit formation requires both accountability and compassion. Rigid streak counters penalize unavoidable life disruptions (illness, travel, power outages), causing demotivation and abandonment. Conversely, frictionless habits without consequences dilute personal discipline.

Similarly, deep work requires friction against phone notifications and distractions. Low-to-mid range devices on patchy data need focus timers that operate 100% offline, without external streaming audio dependencies, and leverage on-device hardware sensors (accelerometer) for natural "Flip-to-Focus" interaction.

## Decision
1. **Streak Freeze Token System**:
   - Each habit tracks `currentStreak`, `longestStreak`, and `freezeTokens` (capped at 2 active tokens).
   - A user earns **1 freeze token** for every 7 consecutive days of 100% scheduled habit completion.
   - If a scheduled habit is missed, a freeze token is automatically consumed to preserve the streak, recording an event with `isFreezeConsumed = true` in the single event log.
   - If no freeze tokens remain, the streak resets to 0.
   - 30-day heatmap cells are rendered using the Part 1 design tokens: 5 opacity tiers of `#B6FF00` Lime Green on `#000000` OLED Black.
2. **Focus Zone & Flip-to-Focus Engine**:
   - Focus sessions operate as an offline state machine (`idle`, `running`, `paused`, `completed`, `breakTime`).
   - Sessions link directly to existing `TaskItem`s from the task planner.
   - **Flip-to-Focus**: Uses accelerometer sensor readings ($Z \approx -9.8\text{ m/s}^2$ indicating the device is placed face down on a surface) to automatically trigger or unpause the focus timer and suppress visual screen clutter.
   - Offline soundscapes: Provides bundled/synthetic audio profiles (`Silence`, `Rain on Tin Roof`, `White Noise`, `Binaural 40Hz Focus Tone`, `Monochrome Static`).
   - Track and record distraction interruptions ($N$ times app was placed in background or paused) to compute a Focus Quality Metric ($1.0 - \text{interruptions} \times 0.1$).
   - Upon completion, logs a `focusSession` entry in `EntriesRepository`.
3. **Mood & Energy Wellness Matrix**:
   - Dual-axis 1-5 rating: Mental Mood (Rough $\to$ Radiant) and Physical Energy (Depleted $\to$ Electric).
   - Contextual factor chips (Sleep, Work, Family, Health, Social, Weather) with Bangla and English translations.
   - Single event log writes to `entries` table (`EntryType.moodEnergyCheckin`).

## Consequences
- **Pros**:
  - Streak freeze encourages long-term retention without punishing honest emergencies.
  - Flip-to-Focus provides a tactile, delightful deep work habit.
  - 100% offline functionality with zero external API calls.
  - Full single event log compliance.
