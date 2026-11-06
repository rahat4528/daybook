# ADR-0012: Student Mode & Spaced Repetition (SuperMemo SM-2) Flashcard Architecture

## Status
Accepted

## Context
DayBook's design philosophy as a personal life operating system recognizes that Bangladeshi developers and university students juggle academic coursework, semester exam schedules, assignment deliverables, and spaced repetition memorization (algorithms, vocabulary, system architecture, foreign languages).

The requirements specify:
1. **Academic Tracking**: Semester-based courses (credits, codes, instructors, room numbers), assignments with weights and deadlines, and exams with seat numbers, countdowns, and room assignments.
2. **Spaced Repetition Algorithm**: Implementation of the proven SuperMemo SM-2 algorithm to schedule flashcard intervals deterministically offline without third-party cloud dependencies.
3. **Bangla-First Academic Terminology**: Support for both English and Bangla terminology (কোর্স, পরীক্ষা, অ্যাসাইনমেন্ট, ফ্ল্যাশকার্ড, ডেক, পুনরাবৃত্তি).
4. **Single Event Log Integration**: Flashcard review sessions must log study count and duration to `entries` so that the Day Page, Day Score, and nightly reflection automatically reflect academic effort.

## Decisions

### 1. SuperMemo SM-2 Mathematical Specification
We implement the standard, mathematically rigorous SuperMemo SM-2 interval algorithm:
- Initial Easiness Factor: $EF_0 = 2.5$, with an absolute floor $EF_{\min} = 1.3$.
- Quality rating $q \in [0, 5]$:
  - $q \ge 3$: Successful recall.
    - $I(1) = 1$ day
    - $I(2) = 6$ days
    - $I(n) = \text{round}(I(n-1) \cdot EF)$ for $n > 2$.
    - Repetition counter increments ($n \leftarrow n + 1$).
  - $q < 3$: Recall failure (blackout).
    - Repetition counter resets ($n \leftarrow 0$).
    - Interval resets ($I \leftarrow 1$ day).
- Easiness Factor update:
  $$EF' = EF + (0.1 - (5 - q) \cdot (0.08 + (5 - q) \cdot 0.02))$$
  Clamped to $\max(1.3, EF')$.

### 2. Exam Urgency & Day Page Interop
When an exam is within 7 days ($d \le 7$), the exam is surfaced as an urgent priority. Study blocks are automatically suggested for the student's daily plan.

### 3. Review Session Logging
Completing a deck review session creates an immutable event in the single event log:
```json
{
  "deckId": "deck_algorithms",
  "deckTitle": "Data Structures & Algorithms",
  "cardsReviewed": 12,
  "averageScore": 4.2,
  "durationMinutes": 15
}
```
with `EntryType.taskCompleted` or dedicated academic focus tag.

### 4. Zero Data Collection & Offline-First Guarantee
All courses, exam dates, syllabus notes, and flashcard content remain 100% on the local device, fully usable with zero network connectivity.

## Consequences
- Students get a unified academic command center inside DayBook.
- Spaced repetition is deterministic, offline, and mathematically verified through unit tests.
- Single event log captures study habits seamlessly into daily pages.
