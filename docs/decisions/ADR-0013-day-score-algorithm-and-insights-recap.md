# ADR-0013: Deterministic Day Score Algorithm & Weekly/Monthly Recap Insights

## Status
Accepted

## Context
DayBook rejects arbitrary or gamified "vanity metrics" that reward mindless button clicking. Instead, it provides a transparent, scientifically balanced **Day Score** ($S \in [0, 100]$) and analytical recaps that reflect meaningful life execution across focus, discipline, habits, and self-reflection.

The score must:
1. Compute deterministically from the local single event log (`entries`) and domain repositories.
2. Maintain clear weight allocations so the user always understands why a score was awarded.
3. Provide weekly and monthly aggregate trajectories without requiring any cloud server computation.
4. Export clean monochrome line-art recap cards adhering strictly to the design system (pure OLED black `#000000`, bold lime `#B6FF00`, white typography).

## Decisions

### 1. Mathematical Day Score Formulation
The total score $S$ is computed as the sum of 5 distinct life pillars:
$$S = \text{round}\left(S_{\text{tasks}} + S_{\text{wake}} + S_{\text{focus}} + S_{\text{habits}} + S_{\text{reflection}}\right)$$
Clamped strictly to $[0, 100]$.

Pillar Breakdown:
1. **Tasks Execution (30%)**:
   $$S_{\text{tasks}} = 30 \times \min\left(1.0, \frac{N_{\text{completed}}}{\max(1, N_{\text{total}})}\right)$$
2. **Wake Quest Discipline (20%)**:
   - Completed challenge on time with zero snoozes: $+20$ pts
   - Completed challenge with snooze: $+10$ pts
   - Missed / disabled: $+5$ pts (baseline)
3. **Deep Focus Minutes (25%)**:
   $$S_{\text{focus}} = 25 \times \min\left(1.0, \frac{M_{\text{focus}}}{90}\right)$$
   (Full score achieved at 90 minutes of Pomodoro/deep focus).
4. **Habit Consistency (15%)**:
   $$S_{\text{habits}} = 15 \times \min\left(1.0, \frac{H_{\text{done}}}{\max(1, H_{\text{total}})}\right)$$
5. **Nightly Reflection (10%)**:
   $+10$ pts if evening review / journal entry is recorded for the day.

### 2. Score Classification
- **$\ge 85$**: Mastery Day (অসাধারণ দিন)
- **$70 - 84$**: Solid Productive Day (ফলপ্রসূ দিন)
- **$50 - 69$**: Steady Progress (স্থিতিশীল দিন)
- **$< 50$**: Recovery / Rest Day (বিশ্রাম ও প্রস্তুতি)

### 3. Weekly Trajectory & Energy Distribution
The analytics engine computes 7-day rolling averages, identifies peak energy hours (morning vs afternoon vs evening), and tracks focus-to-distraction ratio.

### 4. Shareable Line-Art Recap
Renders a high-contrast monochrome card with lime accents displaying:
- Day Key and Bengali date
- Day Score circular gauge
- Key metrics: Tasks completed, Focus minutes, Habits streak, Sky condition
- Grounded signature quote / nightly reflection summary

## Consequences
- Transparent and motivating productivity feedback grounded in actual user logs.
- 100% offline calculation with zero server latency or privacy exposure.
