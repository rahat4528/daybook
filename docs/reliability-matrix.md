# DayBook Reliability Matrix: OEM Alarms, Doze, & Reboot Testing

This matrix documents the verification results and manufacturer-specific configuration profiles for DayBook's Wake Quest alarm engine across targeted Android devices.

## Device Test Matrix

| OEM & Model | OS Version | AlarmManager.setAlarmClock | Lockscreen Full-Screen Intent | Post-Reboot Recovery | Doze Mode Survival | OEM Special Setting Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Google Pixel 7** | Android 14 (API 34) | Pass | Pass | Pass (BootReceiver) | Pass | None (Stock AOSP) | Verified |
| **Samsung Galaxy A53** | OneUI 6.0 (Android 14) | Pass | Pass | Pass | Pass | Add to "Never Sleeping Apps" | Verified |
| **Xiaomi Redmi Note 12** | MIUI 14 / HyperOS | Pass | Pass | Pass | Pass | Enable "Autostart" + Battery: "No restrictions" | Verified |
| **Realme 11 Pro / Oppo** | RealmeUI 4.0 / ColorOS 13| Pass | Pass | Pass | Pass | "Allow background activity" + "Auto-launch" | Verified |
| **Vivo Y35** | FuntouchOS 13 (Android 13) | Pass | Pass | Pass | Pass | "High background power consumption" allowed | Verified |

---

## OEM Specific Deep-Link Intent Configurations

### 1. Xiaomi / Redmi / POCO (MIUI / HyperOS)
- **Primary Issue**: Extreme background process killing after 10-15 minutes of screen off.
- **Remediation**:
  - `Autostart` toggle must be granted for DayBook.
  - Battery Saver set to `No restrictions` instead of `MIUI Battery Saver (recommended)`.
  - Intent targets:
    - `com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity`
    - `com.miui.powerkeeper/.ui.HiddenAppsConfigActivity`

### 2. Samsung (One UI)
- **Primary Issue**: Automatic sleeping of apps not opened for 3 days.
- **Remediation**:
  - Add DayBook to "Never sleeping apps" in `Settings > Battery > Background usage limits`.
  - Disable "Put unused apps to sleep".

### 3. Realme & Oppo (Realme UI & ColorOS)
- **Primary Issue**: Freeze app in background and restrict foreground service start.
- **Remediation**:
  - `Settings > Apps > App Management > DayBook > Battery usage > Allow background activity` & `Allow auto-launch`.

### 4. Vivo (Funtouch OS)
- **Primary Issue**: Background network and high power task suspension.
- **Remediation**:
  - `Settings > Battery > Background power consumption management > DayBook > Allow high background power consumption`.

---

## Fallback & Recovery Architecture
1. **Reboot Persistence**: Persistent state in encrypted Drift storage. `BootCompletedReceiver` queries active alarms and re-registers them via `AlarmManager.setAlarmClock()`.
2. **Audio Stream Isolation**: Foreground service utilizes `AudioAttributes.USAGE_ALARM` and requests `AUDIOFOCUS_GAIN_TRANSIENT`. Audio volume ramps smoothly from 10% to 100% over 60 seconds to avoid startling the user while guaranteeing auditory wakefulness.
3. **Escapes & Fail-safes**:
   - Max failed challenge attempts: 5.
   - Max ringing duration fail-safe: 15 minutes.
   - If reached, Emergency Stop unlocks with a 5-second hold confirmation.
