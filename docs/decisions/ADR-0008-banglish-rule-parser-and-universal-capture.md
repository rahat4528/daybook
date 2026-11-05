# ADR-0008: Banglish Rule-Based Natural Language Parser and Universal Capture Engine

## Status
Accepted

## Context
DayBook's target users are Bangladeshi professionals, students, and freelancers who frequently think and communicate in a blend of Bangla, English, and phonetic Banglish (Bangla transliterated into Latin characters, e.g. *"dudh kinte hobe kal shokal 9ta"*, *"rickshaw vara dilam 50 taka"*).

Key engineering constraints:
1. **Offline-First & Zero Latency**: The app must parse inputs instantaneously (under 10ms execution time) without network access on low-to-mid range Android devices. Relying on remote LLM calls for every keystroke or quick-add creates latency, consumes mobile data, and breaks offline reliability.
2. **Determinism & User Trust**: The parser must be predictable. Users must see real-time parsed confirmation chips (Intent, Date, Time, Amount, Priority, Category) and be able to tap any chip to override or adjust it prior to submission.
3. **Universal Capture & Android Integration**: Capture is the central entry point of the app (the center lime button on the bottom nav). It must support typed text, voice dictation with editable transcripts, rich notes (checklists, photos, audio clips, saved links), and Android's system-level `ACTION_SEND` share intent.

## Decision
1. **Rule-Based Hybrid Parser Pipeline**:
   - Implement `BanglishParser` as a pure, deterministic Dart engine using regular expressions, tokenization, phonetic lookups, and numeral normalization.
   - Support both English and Bengali script numerals (`০-৯` -> `0-9`), text-based numbers (`ek`, `dui`, `tin`... `dosh`), and currency keywords (`taka`, `tk`, `৳`, `টাকা`).
   - Extract temporal expressions across five diurnal phases (`sokal` ~ 08:30, `dupur` ~ 13:00, `bikel` ~ 16:30, `shondha` ~ 19:00, `rat` ~ 21:30), relative dates (`aj`, `kal`, `porshu`, `next week`, `ashchhe shukrobar`), and specific clock times (`9ta`, `9:30ta`, `10:15am`, `11pm`).
   - Classify intent across six core domains: `Task`, `Expense`, `Note`, `Habit`, `Mood`, and `Alarm`.
   - Maintain a golden test dataset of $\ge 100$ real-world Banglish and Bangla phrases to benchmark and verify parsing precision.
2. **Interactive Parsed Preview Chips**:
   - As the user types or speaks, the engine evaluates the input reactively and displays interactive chips above the keyboard.
   - Tapping an entity chip allows manual adjustment (e.g., changing tomorrow morning to tomorrow evening, or switching intent from Task to Note).
3. **Rich Note Types & Attachments**:
   - `RichNote` supports five distinct formats: plain markdown, interactive checklist, photo attachment metadata, local voice note duration, and web link saver with preview metadata.
4. **Inbox & Triage Architecture**:
   - Shared text, URLs, or image URIs received via Android `ACTION_SEND` land in the `captures` table with `processed_into_type = NULL`.
   - The `InboxScreen` provides a high-efficiency triage workflow (swipe right to convert to Task, swipe left to convert to Expense, tap to edit as Rich Note, or archive).
   - Once processed, the capture automatically writes an entry to that day's Page via `EntriesRepository`.
5. **Command Palette**:
   - Typing `/` anywhere in the capture or search surfaces opens executable shortcuts (`/task`, `/expense`, `/note`, `/habit`, `/mood`, `/plan`, `/alarm`).

## Consequences
- **Pros**:
  - Zero network latency, zero token cost, and 100% offline availability.
  - High user confidence due to live interactive confirmation chips and editable transcripts.
  - Seamless Android OS integration via share targets.
- **Trade-offs**:
  - Complex linguistic nuances or deeply nested clauses outside the rule grammar fall back gracefully to a generic Task or Note with the raw text preserved.
