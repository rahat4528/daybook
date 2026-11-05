# Daybook: AI Personal Assistant & Daily Operating System
## Product Architecture, Engineering Specification & Roadmap

---

### 1. Executive Summary & Vision

**Daybook** is a comprehensive daily operating system designed for focused, disciplined, and mindful individuals. It transcends ordinary to-do apps by combining:
1. **Intelligent Eisenhower Task Management**: Dynamic priority scoring balancing urgency, importance, and deadlines.
2. **Deterministic Daily Time-Blocking**: Algorithmic scheduling of waking hours with automatic rollover of unfinished blocks.
3. **Fail-Safe Smart Alarm Engine**: High-reliability wake-up system requiring challenge verification (Math, Memory Sequence, Step Counter, QR Code verification, and On-Device Object Scan).
4. **Dynamic Living Weather Sky**: Real-time canvas reflecting exact solar positioning (dawn, daytime, golden hour, dusk, midnight) and meteorological conditions.
5. **Bilingual AI Companion (বাংলা + English)**: On-device & proxied natural language assistant with structured tool execution (`create_task`, `set_alarm`, `plan_day`, `save_memory`).
6. **Adaptive Long-Term Personal Memory**: Fact & preference retention engine that shapes daily briefings and personalizes coaching.
7. **Bimodal Daily Rituals**: Morning Briefing (actionable kick-off) and Evening Reflection (gratitude, metrics, and rollover).

---

### 2. Core Architectural Layers

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
│  - TaskScoringService (Urgency/Importance Math)        │
│  - DayPlannerService (Slot Fitting & Rollover)         │
│  - AlarmLifecycleService (Safety & Snooze Policies)   │
│  - WeatherSceneEngine (Solar Calculations & WMO Maps)  │
│  - AssistantToolService (Deterministic Actions)        │
│  - MemoryVaultService (Keyword + Recency Ranking)      │
│  - BriefingService (Template-Driven Offline Briefings) │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│               Data & Persistence Layer                 │
│  - AppRepository (Offline-First Persistent Storage)    │
│  - Platform Channels (AlarmManager, Audio Stream, VAD) │
│  - External Weather & AI Proxies                       │
└────────────────────────────────────────────────────────┘
```

---

### 3. Key Design Tenets

* **Reliability First**: Alarms and critical reminders must execute deterministically without dependency on network or fragile state.
* **Offline Independence**: Core daily operations (planning, alarm challenges, task tracking, memories, briefings) work 100% offline.
* **Bilingual Equality**: English and Bengali (বাংলা) receive first-class UX, typography, and numerical representations (`০-৯`).
* **Privacy by Design**: Memories and journal entries reside strictly on the user's device unless explicitly synced.

