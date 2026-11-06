# ADR-0011: BDT Ledger with Paisa Precision, Bengali Dhar Tracker, and People CRM

## Status
Accepted

## Context
DayBook requires a personal finance ledger and relational contacts manager designed for Bangladeshi daily life. Users transact primarily in Bangladeshi Taka (BDT) via cash and mobile financial services (bKash, Nagad, Rocket, Bank). Additionally, informal lending and borrowing (ধার / Dhar) between family and friends is ubiquitous and requires meticulous tracking of partial repayments without social awkwardness or data loss.

Requirements:
1. **Paisa Precision Reconciliation**: Floating-point rounding errors (`0.1 + 0.2 = 0.30000000000000004`) are unacceptable in a financial ledger. All monetary amounts must be stored internally as integer paisa (1 BDT = 100 paisa) and formatted with two decimal places.
2. **Account Labels**: Support `Cash`, `bKash`, `Nagad`, `Bank`. (No payment integrations or third-party bank scraping).
3. **Bengali Dhar (ধার) Tracker**: Track who owes whom (`iOwe` vs `theyOwe`), support partial repayments, and maintain an audit log of each partial installment.
4. **People & Keep-in-Touch Cadence**: Profile connections (relation, birthday, gift ideas) and enforce intentional relationship maintenance (e.g., call parents every 7 days).
5. **Regulatory & Security Disclaimer**: The app must visibly communicate: *"Personal ledger log only — not financial advice."*
6. **Data Privacy**: All ledger and people data stays strictly on-device, encrypted in SQLCipher SQLite, and offline.

## Decisions

### 1. Integer Paisa Storage
- All transactions, budgets, and loans store amounts as `int amountPaisa`.
- Conversion: `paisa = (bdt * 100).round(); bdt = paisa / 100.0`.
- Totals reconcile to the single paisa ($0.01\text{ BDT}$).

### 2. Dhar (ধার) Debt Model
- Direction: `DharDirection.theyOweMe` (Lent money) vs `DharDirection.iOweThem` (Borrowed money).
- Balance tracks `remainingPaisa = initialPaisa - sum(repayments)`.
- When `remainingPaisa == 0`, status transitions to `settled`.

### 3. People Cadence Engine
- Each person can have an optional `cadenceDays` interval (e.g. 7 days).
- Health status computed dynamically:
  - `CadenceHealth.fresh`: Contacted within period.
  - `CadenceHealth.dueSoon`: Within 24-48 hours of deadline.
  - `CadenceHealth.overdue`: Elapsed days exceeds `cadenceDays`.

### 4. CSV Export Format
- Standards-compliant RFC 4180 CSV generation with headers:
  `ID,Date,Type,Category,Account,Amount_BDT,Notes,DayKey`.

## Consequences
- Guaranteed zero rounding discrepancies across thousands of microtransactions.
- Contextual integration into the Day Page: Every expense, loan repayment, and contact interaction writes to the day's event log.
