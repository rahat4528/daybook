# ADR-0001: Android minSdk and Target Platform Policy

## Status
Accepted

## Context
DayBook targets users in Bangladesh using low-to-mid-range Android smartphones (Xiaomi/Poco, Samsung, Realme, Oppo, Vivo). The app's core value proposition is an ultra-reliable wake-up alarm engine (Wake Quest), encrypted local storage, foreground audio playback, and sensor-based movement tracking. We must select an Android `minSdk` that maximizes reach while avoiding broken platform APIs for foreground services and exact alarms.

## Decision
We set **`minSdk = 26` (Android 8.0 Oreo)** and **`targetSdk = 34` (Android 14)**.

### Rationale
1. **Foreground Service Lifecycle**: Android 8.0 (API 26) introduced mandatory Notification Channels and formalized foreground service lifecycle. Supporting earlier APIs requires complex legacy fallback paths with minimal Bangladeshi market share (<1.5% in 2026).
2. **Exact Alarm & Doze Exemption**: `AlarmManager.setAlarmClock()` behaves consistently on API 26+ and is granted implicit permission exemptions from standard Doze mode restrictions.
3. **Android Keystore & Crypto**: API 26 provides standard Android Keystore support for AES-256 GCM master key wrapping and biometric prompt APIs (`BiometricPrompt` on API 28+ with fallback).
4. **Android 14 Compatibility**: `targetSdk = 34` requires declaring `FOREGROUND_SERVICE_TYPE_SPECIAL_USE` or `MEDIA_PLAYBACK` and explicit declaration of `USE_EXACT_ALARM` and `USE_FULL_SCREEN_INTENT`.

## Consequences
- Supports >98% of active devices in Bangladesh.
- Simplifies native Kotlin codebase by removing pre-Oreo notification and service workarounds.
- Eliminates security vulnerabilities associated with legacy cryptographic providers on API <26.
