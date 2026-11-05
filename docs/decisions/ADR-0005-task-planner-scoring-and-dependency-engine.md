# ADR-0005: Task Planner Scoring, Dependency Resolution, and Energy-Aware Scheduling

## Context
In Part 3 of DayBook, the app introduces an intelligent, offline-first daily planner, goal management system, and dependency-aware task engine.
Traditional to-do applications present flat lists that lead to decision fatigue. DayBook transforms tasks into a deterministic schedule between a user's wake time and sleep time:
1. Tasks have Eisenhower priority ratings, estimated durations, due dates, tags, and dependencies ("blocked by").
2. The planner automatically fits tasks into available schedule blocks while respecting fixed routines and meetings.
3. High-friction, cognitive tasks must align with peak energy hours ("Eat the Frog" principle).
4. Unforeseen disruptions require a fast, non-destructive "Reset My Day" flow to reschedule remaining tasks without guilt.
5. All algorithms must run entirely offline, be 100% deterministic, and support both Bangla and English interfaces.

## Decisions

### 1. Deterministic Planner Scoring Function
Tasks are prioritized for daily scheduling using a composite score:
$$\text{Score} = w_p \cdot P + w_u \cdot U + w_e \cdot E - w_b \cdot B$$
Where:
- $P \in [25, 100]$: Eisenhower base score (P1 Urgent & Important = 100, P2 Important Not Urgent = 75, P3 Urgent Not Important = 50, P4 Neither = 25).
- $U \in [0, 50]$: Urgency boost based on proximity to due date (due today = +50, due tomorrow = +25, overdue = +75).
- $E \in [0, 30]$: "Eat the frog" bonus for high-effort tasks needing focus.
- $B \in \{0, \infty\}$: Dependency penalty. If a task has unfinished prerequisite tasks in `blockedByTaskIds`, its score is suppressed and it cannot be scheduled ahead of its blockers.

### 2. Energy-Aware Peak Slot Allocation
When scheduling:
- High-cognitive/high-duration tasks ($P1$ or estimate $\ge 45$ min) are matched to the user's peak energy window (default: morning 9:00 AM – 1:00 PM).
- Lower-energy routines, administrative tasks ($P3/P4$ or estimate $< 30$ min) are placed in afternoon trough hours.
- Each block generated displays an explainability reason (e.g., *"Scheduled during peak energy window"* / *"শীর্ষ শক্তি সময়ে নির্ধারিত"*).

### 3. Buffer Blocks & Overload Warning
- A 10-minute buffer block is automatically injected after intense focus blocks ($\ge 45$ min).
- If $\sum \text{Estimated Minutes} > \text{Available Work Minutes}$, an **Overload Warning** is triggered, displaying the exact deficit and suggesting non-urgent tasks to roll over.

### 4. "Reset My Day" Reshuffle with Undo
When the user triggers "Reset My Day":
- Completed blocks are preserved.
- Passed uncompleted blocks are swept up and re-fitted from `Current Time + 10 mins` until `Sleep Hour`.
- An Undo token is created so the user can restore their previous plan with one tap.

### 5. Dependency Graph Enforcement
A task with `blockedByTaskIds` cannot be marked completed until all blocker tasks are completed. The UI renders a lock badge and displays the blocker task titles.

## Status
Accepted and active for Part 3 implementation.
