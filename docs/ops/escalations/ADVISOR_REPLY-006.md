# ADVISOR_REPLY-006 — `app_fixtures`: Persian fixture text vs MC-17; DS-06 "series cross"
- Replies to: ESC-006 (lives on PR #34, branch `agent/tester-T-022-app-fixtures`) · Date: 2026-11-07 · By: Advisor (scheduled run)
- Rules read (on the PR branch): DS-02, DS-06, table 10-2 row W-09, SG-08 (`10-style-guide-and-fixtures.md`); MC-17, MC-24, VR-03 (`11-testing-and-machine-checks.md`); AGR-05, AG-15 (`13-agent-protocol.md`); SE-05, SE-09 (`SPEC_ERRATA.md`); `tool/ui_check/src/rules_stage.dart` (`_persianAllowed`); T-022 packet; AUTONOMY_AND_ESCALATION §1 (hat paths). Checked DS-06 by hand: value(s+d) − value(s) = d×10^14 + Δk×3×10^13 with Δk ≥ −d, so ≥ d×7×10^13 > 0 for every pair and month; the ESC claim holds, no two series ever cross (ranges do overlap).

## Decision
**Q1: A** — MC-17 "allowed in" gains `lib/fixtures/`, via an erratum, with an import guard. **Q2: A** — keep the DS-06 formula; strike «سری‌ها یکدیگر را قطع می‌کنند» (replace with "ranges overlap").

## Why
1. MC-17 protects CM-10 (no UI copy outside the catalog); fixture names/titles are test data, not copy, so an explicit "allowed in" cell plus a guard that UI cannot import fixtures keeps the aim. VR-03 permits this only through the row's own column with Agent 1 approval — hence an erratum, not a code-side exemption.
2. B (JSON beside the code) hides text from the checker by file type — the exact pattern VR-03/AG-15 forbid in spirit. C fills the section 9 catalog with ~80 non-product rows and breaks TN-12's catalog-vs-code mapping.
3. DS-06 formula is the precise, testable part (SG-08 checks 60 × 15 digits); "cross" is prose and no test needs it. W-09 chart 2 already covers a zero-crossing line.
4. Both are spec errata (D2), not D3; no ADR, gate, scope or spend involved.

## Actions
| # | File(s) | Owner hat |
|---|---|---|
| 1 | `docs/design/SPEC_ERRATA.md`: new SE row (next free number) for MC-17 "allowed in" += `lib/fixtures/` and DS-06 wording; interim rule = this reply; record Agent 1 approval (VR-03) | Product/Contracts |
| 2 | `tool/ui_check/src/rules_stage.dart`: extend `_persianAllowed` with `(^|/)fixtures/` under `lib/`; add the import guard as a rule line: any file in `lib/` outside `lib/fixtures/` and `lib/style_guide/` that imports `fixtures/` is a violation (cite MC-17 + the new SE id); tool tests per VR-07 (broken + clean sample for both) | Product/Contracts (owner of `tool/ui_check`, T-016) |
| 3 | After Action 2 merges: follow-up task adds the Persian text of tables 10-2-الف…ت, W-05, W-07, W-09 charts 2–4, W-12 to `lib/fixtures/` | Tester / Debugger |
| 4 | T-022 (PR #34) may merge as is: it follows the AG-16 default (numbers and dates only; DS-06 as written with a test recording "no crossing"). No change requested on PR #34 | Reviewer / Lead |
| 5 | Spec text of DS-06 in `10-style-guide-and-fixtures.md` is changed only when the erratum is closed in a Product/Contracts spec PR | Product/Contracts |

## Follow-ups
- Until Action 2 is on `main`, no Persian literal goes into `lib/fixtures/` and no golden shows fixture text (ESC-006 default stays).
- Lead sets `Status: CLOSED` on ESC-006 when Actions 1–2 merge; the DS-06 "no crossing" test then documents the corrected wording.
- If release builds can still reach `lib/fixtures/` through `lib/style_guide/` (web demo), the Style Guide task (T-010) must keep the demo entry point separate from `main.dart`; flag in T-010's packet.

NEEDS_OWNER: no
