# ADR-0006: Wake Quest Alarm Engine, Multi-Challenge Chain, and Sleep Health

## Context
Standard mobile alarm apps fail on aggressive Android OEM battery savers (Xiaomi MIUI/HyperOS, Samsung OneUI, Oppo ColorOS, RealmeUI, Vivo FuntouchOS). Furthermore, traditional alarms encourage mindless snoozing or instant dismissal. DayBook Part 4 introduces "Wake Quest": a mission-driven, multi-stage wake-up engine backed by Android's highest-priority alarm primitive (`AlarmManager.setAlarmClock()`), a foreground media service, full-screen lockscreen override, and cognitive/physical challenges that require verified wakefulness before dismissing.

## Decision

### 1. Alarm Clock Scheduling & Lockscreen Overlay
- Use `AlarmManager.setAlarmClock()` exclusively, accompanied by `AlarmManager.AlarmClockInfo` containing a `PendingIntent` to the full-screen `AlarmActivity`.
- This ensures the Android system treats the alarm as a user-visible alarm clock (visible in the status bar and lockscreen widget), exempting it from normal Doze throttling.
- `AlarmActivity` uses flags:
  - `setShowWhenLocked(true)`
  - `setTurnScreenOn(true)`
  - `FLAG_KEEP_SCREEN_ON`
  - High audio stream: `AudioManager.STREAM_ALARM` with audio focus gain.
- Receivers for `BOOT_COMPLETED`, `LOCKED_BOOT_COMPLETED`, `TIME_SET`, `TIMEZONE_CHANGED`, and `MY_PACKAGE_REPLACED` reload and re-register active alarms from persistent storage.

### 2. Challenge Interface & Chaining Pipeline
All wake challenges conform to the unified `WakeChallenge` interface:
```dart
abstract class WakeChallenge {
  AlarmChallengeType get type;
  bool get isCompleted;
  ChallengeDifficulty get difficulty;
  ChallengeResult verify(dynamic input);
  void reset();
}
```
Supported challenges:
- **Math**: Easy (2-term addition/subtraction), Medium (multiplication + addition), Hard (multiplication + parentheses + modulo).
- **Simon 3x3 Memory**: Visual light sequence on a 3x3 grid (4, 6, 8 steps). Mistakes immediately replay the sequence with subtle haptic feedback.
- **Movement**: Step counter integration with fallback accelerometer magnitude filtering ($20, 30, 50$ steps).
- **QR / Barcode**: Verifies SHA-256 match against a registered code (e.g., toothpaste, bathroom door, coffee canister).
- **On-Device AI Vision**: Target detection (e.g. coffee mug, toothbrush, book) with a confidence threshold ($>0.75$) sustained across consecutive frames with required camera motion vector to defeat static photo spoofing.
- **Typing**: Bengali or English motivational affirmations typed character-by-character.
- **Voice Phrase**: Spoken affirmation with automatic fallback to typed confirmation.
- **Daily Intention**: User enters their primary priority for the day, which automatically writes a journal entry to the Day Page.

**Chaining**: An alarm can define a chain of $1$ to $3$ challenges. Advancing through the chain unlocks the next challenge; completing the final challenge stops the foreground alarm service and triggers a morning TTS greeting.

### 3. Safety Escape Hatch
To ensure users are never trapped by device camera failures, sensor errors, or software bugs:
- If a user fails challenges 5 consecutive times, OR if 15 minutes have elapsed since the alarm began sounding, an "Emergency Safe Dismiss" button unlocks.
- Activating the emergency dismiss requires holding a high-friction button for 5 seconds and logging an `alarm_escape_hatch_used` audit entry in the event log.

### 4. Sleep & Wake Analytics
- `SleepLog`: Tracks bedtime, wake time, subjective rating (1-5 stars), sleep debt relative to a configurable daily sleep goal (default: 8h).
- `Wake Score`: Normalized score (0-100) combining time from ring to first challenge attempt, number of snoozes, and time from dismissal to completion of the morning intention or first task block.

### 5. OEM Battery & Autostart Guidance
- Device-specific guidance screens provide deep links to OEM system settings for Xiaomi (Autostart + No Restrictions), Samsung (Never Sleeping Apps), Oppo/Realme (Allow Background Activity), and Vivo (High Background Power Consumption).

## Consequences
- **Positive**: 100% reliable wake-up across diverse hardware; users arrive at their day awake and intentional; zero trapped user incidents via fail-safe escape hatch.
- **Compliance**: Uses standard Android SDK APIs for `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`, and `USE_FULL_SCREEN_INTENT`, compliant with Google Play target SDK 34/35 policies.
