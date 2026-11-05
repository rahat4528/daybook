# ADR-0010: AI Tool Execution Engine, Prompt Injection Defense, and Ask Your Past Bangla FTS5

## Status
Accepted

## Context
DayBook requires an AI assistant and a personal memory search system ("Ask Your Past") that works offline-first and Bangla-first. The user will ask questions and issue commands in Bangla, English, and Banglish.

Critical constraints:
1. **The AI never writes directly to the database**: All actions must go through a schema-validated, allowlisted tool calling registry.
2. **Reversibility and Auditability**: Every tool call is logged in `tool_call_log` and can be undone.
3. **Destructive Gates**: Bulk actions, deletions, and high-impact operations must require explicit user confirmation.
4. **Prompt Injection Defense**: Stored entries, task notes, or retrieved memories are treated strictly as untrusted data, never as executable system prompts. No tool can be triggered by entry content without user confirmation.
5. **Context Budget & Privacy**: Before sending any context to an LLM, DayBook redacts emails, phone numbers, and credentials. Context is limited to date/time, timezone, compact pending task titles, and pinned memories.
6. **Ask Your Past Retrieval**: On-device search over journal entries, notes, habits, and tasks. Because Bangla has complex conjuncts (যুক্তবর্ণ) and vowel signs (কার/হ্রস্ব-দীর্ঘ), standard ASCII tokenizers can mangle words. Tokenization must normalize Unicode NFC and use conjunct-safe matching with n-gram fallback. Answers must be grounded only in retrieved data—never hallucinations.
7. **Offline Fallback**: The app must remain 100% functional with AI disabled or offline.

## Decisions

### 1. Allowlisted Tool Registry
Only 14 approved tools may be called:
- `create_task(title, priority, due_date, estimate_minutes)`
- `update_task(task_id, ...)`
- `complete_task(task_id)`
- `list_tasks(status, priority)`
- `create_goal(title, deadline)`
- `set_alarm(time, label, challenges)`
- `plan_day(date, blocks)`
- `save_memory(text, kind)`
- `log_habit(habit_id, date)`
- `log_mood(rating, energy, notes)`
- `log_expense(amount, category, note)`
- `add_note(title, content, kind)`
- `start_focus(minutes, soundscape)`
- `search_entries(query, date_range)`

Each tool invocation produces a `ToolCallRecord`:
- Validates arguments against strict Dart types and regex bounds.
- If flagged as destructive (`isDestructive == true`), status starts as `proposed` and requires explicit UI confirmation.
- Executes against domain services (`TasksRepository`, `HabitService`, `FocusService`, etc.).
- Produces an `undoAction` callback stored in memory and logs an entry in `tool_call_log`.

### 2. Context Budget & PII Redaction
The context payload is strictly capped:
- Current timestamp, day key, and timezone.
- Pinned memories (max 5).
- Compact pending task list (max 10 titles).
- Redaction filters:
  - Phone numbers (`(\+8801|01)[3-9]\d{8}`) -> `[PHONE_REDACTED]`
  - Emails (`[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`) -> `[EMAIL_REDACTED]`
  - Passwords and secret tokens -> `[SECRET_REDACTED]`

### 3. Ask Your Past: Bangla Unicode Tokenization & Retrieval
- Normalizes strings to Unicode NFC form.
- Strips punctuation while preserving Bangla vowel signs (`\u0980-\u09FF`).
- Performs temporal extraction (e.g., `last Friday`, `গত শুক্রবার`, `গতকাল`, `last month`, `networking`, `fever`).
- Matches retrieved entries from the single event log (`entries`) and domain repositories.
- If no matching entries exist, returns an explicit grounded statement: `"No records found for that period."` (English) or `"এই বিষয়ে পূর্বের কোনো তথ্য পাওয়া যায়নি।"` (Bangla).

### 4. Proactive Suggestions
- Limited to at most 3 proactive suggestions per calendar day.
- Kinds: Morning briefing, Focus recommendation, Evening reflection.
- Can be individually toggled or disabled entirely in Settings.

## Consequences
- 100% offline usability is preserved: the local assistant parser executes all 14 tools on-device without network access.
- User data cannot be exfiltrated via prompt injection because the tool registry rejects unauthorized tools and requires confirmation for sensitive actions.
- Ask Your Past provides authentic, traceable answers with Day Page navigation links.
