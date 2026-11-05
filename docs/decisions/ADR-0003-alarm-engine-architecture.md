# ADR-0003: Native Kotlin Wake Quest Alarm Engine Architecture

## Status
Accepted

## Context
DayBook's signature Wake Quest feature requires alarms to trigger deterministically on time, every time, surviving Doze mode, deep device standby, lock screens, and aggressive Chinese OEM background cleaners (Xiaomi MIUI/HyperOS, Oppo/Realme ColorOS, Vivo Funtouch OS, Samsung One UI). Pure Flutter background tasks (like standard WorkManager or timer plugins) are insufficient for life-critical wake-up alarms.

## Decision
We build a dedicated native Kotlin module in `android/app/src/main/kotlin/.../alarm/` communicating with Flutter via high-speed Platform Channels (`MethodChannel` and `EventChannel`):

1. **Scheduling**: Use `AlarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(...), pendingIntent)`. `setAlarmClock` is the highest-priority alarm API in the Android OS, displaying the system clock icon on the lock screen and bypassing standard Doze restrictions.
2. **Execution Chain**:
   - `AlarmReceiver` receives the broadcast, acquires a temporary `WakeLock` (tag: `DayBook:AlarmWakeLock`, timeout: 3 minutes).
   - Starts `AlarmForegroundService` with notification priority `PRIORITY_MAX` and audio stream `AudioManager.STREAM_ALARM`.
   - Posts a full-screen intent launching `AlarmActivity` over the lock screen with `setShowWhenLocked(true)`, `setTurnScreenOn(true)`, and `FLAG_KEEP_SCREEN_ON`.
3. **Resilience & Re-registration**:
   - A multi-intent `BootCompletedReceiver` listens to:
     - `ACTION_BOOT_COMPLETED`
     - `ACTION_LOCKED_BOOT_COMPLETED` (Direct Boot support)
     - `ACTION_TIME_CHANGED`
     - `ACTION_TIMEZONE_CHANGED`
     - `ACTION_MY_PACKAGE_REPLACED`
   - Re-registers all active alarms immediately upon OS wake without waiting for the Flutter engine to spin up.
4. **Safety Escape Hatch**:
   - Alarm sound ramps progressively (20% to 100% over 60s).
   - Mandatory fail-safe hard cutoff after 15 minutes of continuous unaddressed ringing to prevent accidental hearing or battery exhaustion.

## Consequences
- Guaranteed reliability on stock Android.
- Requires explicit user guidance for OEM autostart settings (Xiaomi, Samsung, Realme), addressed in Part 4.
