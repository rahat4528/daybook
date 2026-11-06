# DayBook Privacy Policy

**Effective Date:** November 6, 2026  
**Version:** 1.0.0

At **DayBook**, your personal thoughts, daily reflections, financial logs, habit streaks, and sleep schedules belong exclusively to you. DayBook is engineered from the ground up on an **offline-first, zero-knowledge architecture**.

---

## 1. Core Principles

1. **Zero-Knowledge Encryption by Default**: All journal entries, tasks, memories, debts (*dhar*), and notes are encrypted on your local Android device using **AES-256 with SQLCipher** before reaching physical storage.
2. **The Server Cannot Read Your Life**: When you choose to enable cloud sync, the DayBook backend receives only encrypted ciphertext blobs and authentication tags. Encryption keys are derived locally using PBKDF2 with 100,000 rounds and stored in the Android Hardware-Backed Keystore. The server has no decryption keys and zero plaintext visibility.
3. **No Advertising or Surveillance Tracking**: We do not sell your data, bundle third-party tracking SDKs (no Facebook SDK, no advertising IDs), or monetize your private entries.
4. **Offline Autonomy**: DayBook is 100% functional without an internet connection or backend account. Cloud sync and AI assistant capabilities are strictly opt-in.

---

## 2. Information We Process

### A. Data Stored Exclusively on Your Device
- **Daily Journal & Reflections**: All text, timestamps, energy ratings, and mood logs.
- **Tasks & Time-Blocks**: Eisenhower categories, deadlines, and recurrence rules.
- **Financial Ledger & Dhar**: Amounts, debt directions, repayment histories, and contact names.
- **Habits & Focus Metrics**: Streak counts, freeze tokens, and Pomodoro durations.
- **Biometric Authentication Data**: Biometric fingerprints and face unlock templates remain strictly within your device's Android BiometricPrompt hardware security module; DayBook never accesses raw biometric data.

### B. Data Processed When Using Optional Cloud Sync
- **Encrypted Sync Envelopes**: Base64-encoded ciphertext, initialization vectors (IV), HMAC verification tags, monotonically increasing epoch numbers, and entity IDs.
- **Account Credentials**: Email address and a cryptographically salted/hashed password (PBKDF2-SHA256 with 10,000 rounds).
- **Device Identifiers**: Pseudonymous client device IDs (`dev_xxx`) used solely to resolve multi-device sync ordering.

### C. Data Processed When Using the Optional AI Assistant
- **Transient Tool Execution**: When you invoke the AI assistant, only the minimal structured prompt context required to fulfill the specific action (e.g. `"Set an alarm for 6:30 AM"`) is sent to the backend proxy.
- **No Prompt Retention**: The backend proxy forwards prompts to the Gemini API via a secure server-side key, streams the response, and immediately discards the prompt. Prompts and completions are never logged or stored in backend databases.

---

## 3. Data Retention & Deletion

- **Local Erasure**: You can wipe all local databases and reset encryption keys instantly from **Settings > Security > Factory Reset Local Vault**.
- **Tombstone Cleanup**: Deleted entities generate encrypted tombstones to propagate deletions to your other paired devices. Tombstones are purged permanently from servers after 90 days.
- **Account Deletion**: Requesting account deletion from the app immediately deletes your user record and all associated encrypted sync blobs from the backend database.

---

## 4. Permissions Used on Android

- `SCHEDULE_EXACT_ALARM` & `USE_EXACT_ALARM`: Required for the Wake Quest alarm engine to trigger precisely at the scheduled second.
- `USE_FULL_SCREEN_INTENT`: Allows the alarm challenge screen to display over the lock screen when your wake quest rings.
- `FOREGROUND_SERVICE_SPECIAL_USE`: Maintains audio playback and sensor challenge verification while the alarm is ringing.
- `RECEIVE_BOOT_COMPLETED`: Reschedules active alarms automatically after your device restarts.
- `CAMERA`: Required only if you select QR Code or Camera Verification challenges to mute your alarm. Images are processed entirely in device memory and never saved to disk.
- `ACTIVITY_RECOGNITION`: Used only if you enable the Step Counter wake challenge.

---

## 5. Security & Vulnerability Reporting

If you discover a security vulnerability or have privacy questions, please contact our security team at:
- Email: `security@daybook.app`
- GitHub Security Advisories: [github.com/rahat4528/daybook/security](https://github.com/rahat4528/daybook/security)
