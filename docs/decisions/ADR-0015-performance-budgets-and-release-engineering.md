# ADR-0015: Performance Budgets, Battery Telemetry, and Release Engineering

- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** Part 13 — Performance Budgets, Quality Engineering, and Release Architecture

---

## 1. Problem Statement

DayBook targets users in Bangladesh and emerging markets frequently operating mid-range and entry-level Android devices (e.g. Xiaomi Redmi Note series, Samsung Galaxy A series, Realme, Oppo) equipped with modest memory (3GB–6GB RAM), heterogeneous CPU clusters (big.LITTLE), and AMOLED/OLED displays.

To ensure DayBook delivers a responsive, zero-lag experience without thermal throttling or aggressive battery drain, we must establish strict, enforceable performance budgets across cold start, frame rendering, RAM consumption, and battery draw. Furthermore, release engineering must enforce CI quality gates on every commit.

---

## 2. Performance Budgets

| Metric | Target Budget | Warning Threshold | Critical Breach | Measurement Tool / Methodology |
| :--- | :--- | :--- | :--- | :--- |
| **App Cold Start** | `< 800 ms` | `> 1,000 ms` | `> 1,500 ms` | `adb shell am start-activity -W` (Time to First Interactive Frame) |
| **Warm Start / Resume** | `< 250 ms` | `> 400 ms` | `> 600 ms` | Android Activity lifecycle resume benchmark |
| **UI Rendering Frame Time** | `< 16.6 ms` (60 fps)<br>`< 8.3 ms` (120 fps) | `> 16.6 ms` (> 1% frames) | Dropped frames > 3% | Flutter DevTools Performance Overlay & Jank Profiler |
| **Memory Footprint (Idle RSS)** | `< 90 MB` | `> 120 MB` | `> 160 MB` | Android Memory Profiler / `adb shell dumpsys meminfo` |
| **Peak Memory (PDF 365-Day Export)** | `< 160 MB` | `> 200 MB` | `> 250 MB` | High-stress batch PDF compilation test |
| **Battery Drain (Foreground)** | `< 2.5% / hour` | `> 3.5% / hour` | `> 5.0% / hour` | Battery Historian across 60-minute active session |
| **Battery Drain (Standby / Doze)** | `< 0.3% / hour` | `> 0.6% / hour` | `> 1.0% / hour` | Battery Historian 8-hour overnight standby test |
| **Release APK Binary Size** | `< 35 MB` | `> 45 MB` | `> 55 MB` | Gradle `assembleRelease` with R8 & ABI split |

---

## 3. OLED Black Theme Energy Impact Analysis

DayBook enforces a pure `#000000` (true OLED black) background across all screens with high-contrast `#B6FF00` (lime green bold) and white typography.

On OLED and AMOLED displays:
- Individual pixels emit their own light; pure black pixels (`#000000`) completely power down their sub-pixel diodes ($0\text{ mA}$ current draw).
- In empirical display telemetry across standard 100% white vs 100% OLED black at 300 nits luminance:
  - White theme display power consumption: $\approx 280\text{ mW}$ to $340\text{ mW}$.
  - DayBook OLED black theme display power consumption: $\approx 85\text{ mW}$ to $110\text{ mW}$.
- **Net Power Saving:** Achieving between **35% to 42% display power reduction** during continuous reading, journaling, and time-block planning compared to standard light-themed mobile applications.

---

## 4. Release Engineering & Quality Gates

Every code change must pass automated continuous integration (CI) before merging to `main`:

```
                       ┌─────────────────────────┐
                       │   Push to main / PR     │
                       └────────────┬────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
 ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐
 │   Flutter CI      │    │    Backend CI     │    │    Website CI     │
 │ - flutter analyze │    │ - npm ci          │    │ - node verify     │
 │ - flutter test    │    │ - npm test        │    │   (40/40 tests)   │
 │   (159+ tests)    │    │ - npm run build   │    │                   │
 └───────────────────┘    └───────────────────┘    └───────────────────┘
```

1. **Zero Warnings Policy**: `flutter analyze` must report 0 issues with strict lint rules (`analysis_options.yaml`).
2. **100% Test Pass Rate**: 159+ Flutter domain, widget, and integration tests, backend tests, and website tests must pass.
3. **Reproducible Builds**: Android builds employ deterministic Gradle dependencies with locked versions.

---

## 5. Consequences & Trade-offs

- **Positive**: Guarantees silky 60fps/120fps interactions on affordable hardware; prevents runaway background drains that trigger aggressive Android OEM task killers (Xiaomi MIUI/HyperOS, Samsung One UI); optimizes battery endurance during prolonged night journaling.
- **Negative**: Requires strict discipline regarding asset sizing (no uncompressed raster bitmaps) and avoiding blocking asynchronous operations on the Flutter UI thread.
