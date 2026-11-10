# ADVISOR_REPLY-007 — `worst` set: exact data for W-09 charts 2–4 and W-12
- Replies to: ESC-007 (lives on PR #38, branch `agent/tester-T-025-fixture-text`) · Date: 2026-11-10 · By: Advisor (scheduled run)
- Read (on the PR branch): `10-style-guide-and-fixtures.md` DS-02, DS-04, DS-06, DS-07, tables 10-2-ب (row 1), 10-2-ت (W-01, W-02, W-05, W-09, W-12), 10-3-الف rows `ResponsiveList`, `ChartContainer`; `lib/fixtures/src/worst_set.dart`, `fixture_set.dart` (keys `lunch_with_colleagues`, `food`, `cash`); T-022 non-goals; T-025; ADVISOR_REPLY-006 Action 3; AUTONOMY_AND_ESCALATION §D2. Highest erratum id on `main` and open PRs: SE-15.
- Checked chart 2 by script: values (toman) −987654321012345, −808080808101010, −628507295189675, −448933782278339, −269360269367004, −89786756455668, 89786756455667, 269360269367003, 448933782278338, 628507295189674, 808080808101009, 987654321012345. No value is 0; sign changes between m = 6 and 7; m = 12 already equals W-01 exactly; max 15 digits, minor (×10) inside int64 (DS-07).

## Decision
**A**, with these exact values (to be written into an erratum):
1. **Chart 2:** one series, 12 months; `value(m) = W-02 + floor((m − 1) × 2 × |W-01| ÷ 11)` toman (numerator ≥ 0, so floor = toward zero); m = 12 is W-01 (the formula gives it; keep the explicit pin as a test assertion).
2. **Chart 3:** same shape as chart 1: 5 series × 12 months, every value 0 toman.
3. **Chart 4:** one series, one point, m = 1, value W-01.
4. **W-12:** rows i = 0…199. Even i: title W-05, amount 320 000 toman (table 10-2-ب row 1). Odd i: title and key of table 10-2-ب row 1 («ناهار با همکاران», `lunch_with_colleagues`), amount W-01. All rows: expense, category `food`, account `cash`, local date = 2 Aban 1405 − i days at the DS-01 time of day (i = 199 is 19 Farvardin 1405, so all rows stay in 1405). Order = i ascending (dates descending). Row keys `w12_000`…`w12_199`. W-12 rows are a list-only set: not part of any DS-03 total or DD-06 balance check.

## Why
1. DS-02 wants one shared set; option C lets two M2 agents invent two different "worst" lists, the exact drift AG-05/AG-08 guard against.
2. A keeps the spec words: chart 2 really goes from W-02 to W-01 through zero (12 points like chart 1); W-12 really "alternates W-05 and W-01", and each row still has both fields, with long title and long amount on different rows so DS-04 measures both overflows.
3. B's W-12 drops the alternation the table names; B's chart 2 (two points) does not exercise axis labels in between.
4. Values are integer-only and in int64 (DS-07, MN-01); no new token, component or rule.
5. Class D2 (spec gap, test data). No ADR, gate, scope, money behaviour, licence or spend: not D3.

## Actions
| # | File(s) | Owner hat |
|---|---|---|
| 1 | `docs/design/SPEC_ERRATA.md`: new SE row (next free number) for table 10-2-ت W-09 charts 2–4 and W-12, interim rule = Decision 1–4 of this reply | Product/Contracts |
| 2 | `docs/design/ui-spec/10-style-guide-and-fixtures.md` table 10-2-ت rows W-09, W-12: exact values, only when that erratum is closed in a spec PR | Product/Contracts |
| 3 | After Action 1 is on `main`: follow-up task adds `w09Chart2…4` and `w12Rows` to `lib/fixtures/src/worst_set.dart` with tests (12 chart-2 values above, no zero, sign change at 6→7; 60 zeros; one point; 200 rows, parity of title/amount, dates strictly descending, first 2 Aban, last 19 Farvardin, int64 bound) | Tester / Debugger |
| 4 | PR #38 (T-025) needs no change and may merge as is: it follows the AG-16 default and leaves these items out | Reviewer / Lead |

## Follow-ups
- Until Action 1 merges, the ESC-007 default holds: no test or golden uses W-09 charts 2–4 or W-12.
- Lead sets `Status: CLOSED` on ESC-007 when Actions 1 and 3 merge.
- The PF-02 profiling run (ML-04) uses W-12 as defined here; if 200 rows prove too few to stress scrolling on the reference device, raise a new ESC, do not grow the set inside a task.

NEEDS_OWNER: no
