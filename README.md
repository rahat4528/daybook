# 🌅 Daybook — AI Daily Operating System & Life Companion

<div align="center">

[![CI Build](https://github.com/rahat4528/daybook/actions/workflows/ci.yml/badge.svg)](https://github.com/rahat4528/daybook/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Web%20%7C%20Android%20%7C%20Windows-blue)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)

*A privacy-first, bilingual personal daily operating system designed for disciplined, focused, and intentional living.*

</div>

---

## 🌟 Overview

**Daybook** goes beyond standard to-do lists by uniting intentional daily structure, reliable wake-up alarms, real-time environmental context, and an empathetic bilingual AI companion. 

Built with **Flutter** and **Dart**, Daybook operates **100% offline-first**: all tasks, memory records, alarm challenge engines, and morning briefings function without external network dependencies.

---

## 🚀 Key Architectural Pillars

### 1. 🎯 Intelligent Eisenhower Task Management
- **Dynamic Priority Scoring**: Tasks rank by an algorithmic score computed from Eisenhower quadrant weights, proximity to deadline, overdue penalties, and quick-win bonuses (<25 mins).
- **Categorization & Subtasks**: Supports Work, Study, Health, Personal, Finance, and Creative categories with subtask percentage tracking and automatic parent task completion.
- **Recurrence Engine**: Automated scheduling for Daily, Weekday-only, Weekly, and custom-day recurring commitments upon completion.

### 2. ⏱️ Deterministic Daily Time-Blocking Planner
- **Gap-Fitting Scheduling Algorithm**: Automatically maps active priority tasks into open time windows between wake time and sleep time.
- **Conflict Prevention**: Respects fixed calendar blocks, meals, and meetings with automatic 10-minute cognitive buffer intervals.
- **One-Tap Rollover**: Seamlessly rolls uncompleted blocks into tomorrow's schedule during evening reflections.

### 3. ⏰ High-Reliability Smart Alarm & Multi-Modal Challenge Resolvers
- **Anti-Over-Sleep Verification**: Alarms require active challenge completion before muting:
  - 🧮 **Math Equations**: Easy, medium, and hard algebraic equations with multi-round verification.
  - 🧩 **Memory Sequence (Simon-Style)**: 3×3 grid pattern recall with difficulty scaling.
  - 🚶 **Movement & Step Counter**: Tracks physical walking steps to wake up your body.
  - 📷 **QR Code Verification**: Forces you to get out of bed to scan a physical code (e.g. bathroom mirror).
  - 👁️ **On-Device AI Camera Vision**: Real-time object verification framework.
- **Fail-Safe Ramp & Volume Protection**: Volume ramps gradually from 20% to 100% over 60 seconds with strict 15-minute emergency cutoffs and configurable snooze limits.
- **OEM Battery Killers Whitelist**: Onboarding instructions for Xiaomi (HyperOS/MIUI), Samsung (One UI), Oppo/Realme (ColorOS), and Vivo (Funtouch OS).

### 4. ☀️ Dynamic Living Weather Sky Canvas
- **CustomPainter Solar Engine**: Computes exact solar altitude, solar angles, and sky phases (`Dawn`, `Morning`, `Afternoon`, `Golden Hour`, `Dusk`, `Midnight`).
- **Meteorological Particles**: Real-time celestial rendering (twinkling star clusters at night, corona glow sun, drifting clouds, and rain streaks).
- **WMO Code Mapping**: Translates Open-Meteo meteorological condition codes into aesthetic atmospheric gradients.

### 5. 🤖 Bilingual AI Companion (বাংলা + English)
- **Natural Language Tool Execution**: AI invokes deterministic app services through structured tools:
  - `create_task` — adds and prioritizes tasks
  - `plan_day` — calculates gap-fitted time blocks
  - `set_alarm` — schedules wake-up alarms with challenge settings
  - `save_memory` — registers long-term user preferences
- **Speech Push-to-Talk Simulation**: Interactive voice interface supporting Bengali (`bn_BD`) and English (`en_US`).

### 6. 🧠 Adaptive Personal Memory Vault
- **Habit & Context Retention**: Secure local vault storing user preferences, routines, and episodic summaries.
- **Recency & Relevance Search**: Pinned memories receive priority injection into daily briefings and coaching prompts.

### 7. 🌅 Bimodal Daily Rituals
- **Morning Briefing**: Weather forecast, motivational daily quote, first upcoming alarm, and top 3 mission priorities.
- **Evening Reflection**: Completed vs pending metrics, 5-tier mood scoring, reflection journaling, and task rollover.

---

## 🏛️ System Architecture

```
┌────────────────────────────────────────────────────────┐
│             Presentation & Visual Canvas               │
│  - Living Dynamic Sky (CustomPainter + Solar Engine)   │
│  - Task Board (Eisenhower, Today, Upcoming, Completed) │
│  - Day Planner (Timeline Canvas & Time Blocks)         │
│  - Smart Alarm & Multi-Modal Challenge Resolvers       │
│  - Bilingual Chat Assistant (Bangla & English)         │
│  - Personal Memory Vault & Visual Progress Rings       │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│                 Domain Services Layer                  │
│  - TaskService (Eisenhower Priority Math & Recurrence) │
│  - PlannerService (Gap-Fitting Scheduler & Rollover)   │
│  - AlarmChallengeEngine (Math, Simon, Step, QR, Ramp)  │
│  - WeatherSceneEngine (Solar Calculations & WMO Maps)  │
│  - MemoryVaultService (Keyword + Recency Ranking)      │
│  - BriefingService (Template-Driven Offline Briefings) │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│               Data & Persistence Layer                 │
│  - AppRepository (Offline-First State Management)      │
│  - Platform Channels (AlarmManager, Audio Stream, VAD) │
│  - External Weather & AI Proxies                       │
└────────────────────────────────────────────────────────┘
```

---

## 📂 Repository Directory Layout

```
daybook/
├── .github/workflows/ci.yml       # GitHub Actions CI build & test automation
├── docs/BLUEPRINT.md              # Engineering specification and product roadmap
├── lib/
│   ├── core/
│   │   ├── constants/             # Default configurations, storage keys, timings
│   │   ├── enums/                 # TaskPriority, TaskStatus, RecurrenceType, etc.
│   │   └── localization/          # English & Bangla string tables and digit converters
│   ├── data/
│   │   └── app_repository.dart    # Offline-first state manager & pre-seeded demo data
│   ├── domain/
│   │   ├── models/                # TaskItem, AlarmItem, DailyPlanBlock, ChatMessage, etc.
│   │   └── services/              # TaskService, PlannerService, AlarmChallengeEngine, etc.
│   ├── presentation/
│   │   ├── screens/               # TasksScreen, PlannerScreen, AlarmScreen, AssistantScreen, etc.
│   │   └── widgets/               # WeatherSkyBackground, DailyProgressRing, TaskCard, etc.
│   └── main.dart                  # Application entry point & responsive dashboard shell
└── test/
    ├── domain/models_test.dart    # Domain serialization and algorithmic unit tests
    ├── domain/services_test.dart  # Business logic and challenge generation unit tests
    ├── presentation/ui_test.dart  # CustomPainter and widget interaction tests
    └── widget_test.dart           # App shell smoke and navigation tests
```

---

## 🛠️ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.47.7`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.13.5`)
- Google Chrome (for web testing) or Android Studio / SDK (for Android APK)

### Quick Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/rahat4528/daybook.git
   cd daybook
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run all 30 automated tests:**
   ```bash
   flutter test
   ```

4. **Launch Web application:**
   ```bash
   flutter run -d chrome
   ```

5. **Build production Web distribution:**
   ```bash
   flutter build web --release
   ```

---

## 🧪 Automated Test Coverage Summary

| Test Suite | Tests | Description |
|---|:---:|---|
| `test/domain/models_test.dart` | 9 | Model serialization, dynamic priority scoring, recurring weekdays, and solar sky phases |
| `test/domain/services_test.dart` | 14 | TaskService, Planner gap-fitting, Simon memory sequences, Math equations, QR verification, and volume ramp |
| `test/presentation/ui_test.dart` | 6 | CustomPainter canvas rendering, dual progress rings, task card interactions, and challenge modals |
| `test/widget_test.dart` | 1 | App root smoke test and cross-screen bottom navigation |
| **Total** | **30** | **100% Passed** |

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
