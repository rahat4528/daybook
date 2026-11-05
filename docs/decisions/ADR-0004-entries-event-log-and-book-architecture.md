# ADR-0004: Event Log Architecture, Day Page Synthesis, and Book PDF Export

## Context
In Part 2 of DayBook, the app introduces its signature paradigm: **the Day Page and the Book**. Rather than being a disconnected to-do list, every day is rendered as one cohesive page in a life book. Alarms, completed tasks, focus sessions, weather changes, habit checks, expenses, moods, and notes write into an append-only event log (`entries`).
Furthermore:
1. Every day features an offline 3-line nightly summary synthesized from the day's event log, reflection prompt, and gratitude line.
2. The **Book** organizes months into a bookshelf, provides page-turn navigation between days, visualizes a calendar heatmap (5-tier opacity based on Day Score), surfaces "On This Day" throwbacks (1 month and 1 year ago), manages future-dated Time Capsules, and exports PDF/Markdown/JSON books.
3. The app is Bangla-first and offline-first: all user strings must exist in Bangla and English, and export must work entirely offline without cloud dependencies.

## Decisions

### 1. Unified Event Log (`entries`) & Typed Event Kinds
All timeline events are instances of `JournalEntry` corresponding to the `entries` database table.
The event kinds include:
- `alarm_dismissed`
- `task_completed`
- `habit_logged`
- `focus_session`
- `step_milestone`
- `weather_change`
- `expense_logged`
- `manual_note`
- `mood_energy_checkin`
- `moment_pinned`

Each entry payload is JSON-serialized to allow domain-specific metadata (e.g. focus session duration, photo path, audio voice note duration, task title) while retaining strict SQL indexing on `day_key` (`YYYY-MM-DD`), `ts`, `type`, and `mood`/`energy`.

### 2. Undo Stack & Non-Destructive Mutations
Deletion of entries utilizes a reversible undo transaction. When an entry is deleted, it is placed on an undo stack with a timeout or undo token. If the user invokes "Undo", the entry is restored immediately with its original timestamp and relationships.

### 3. Offline Nightly Summary Synthesis
The 3-line nightly summary runs offline using a deterministic synthesis engine:
- Line 1: Day rhythm & focus (e.g., wake time, focus duration, completed tasks count).
- Line 2: Habit momentum & movement (e.g., habits maintained, step counts).
- Line 3: Evening reflection and mood/energy arc.
When an AI assistant key is available, an online enhancement hook can refine the prose, but offline generation is always guaranteed.

### 4. Book Heatmap & Day Score
The calendar heat view computes a daily score (0–100) based on task completion ratio, habit streak maintenance, focus hours, and reflection logging. The score maps to 5 discrete opacity levels of Lime Green (`#B6FF00` at 15%, 35%, 55%, 75%, 100%) on pure OLED black (`#000000`).

### 5. Multi-Format Book Export (PDF, Markdown, JSON)
- **PDF Export**: Generates a clean, publication-grade document with month cover page, followed by one page per day. Implements a high-contrast print-friendly variant (pure white background with black typography and crisp dark lines).
- **Bangla Support**: Bundles Unicode UTF-8 glyph support for Noto Sans Bengali / Hind Siliguri text rendering.
- **Markdown & JSON**: Generates standardized `.md` diary notebooks and portable JSON archives for backup and data sovereignty.

## Status
Accepted and verified for Part 2 implementation.

