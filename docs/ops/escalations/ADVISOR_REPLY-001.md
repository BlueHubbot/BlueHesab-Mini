# ADVISOR_REPLY-001 — Vazirmatn in T-001 vs. "no font files before ADR-UI-003"
- Replies to: `ESC-001.md` (on `main`; identical copy on the open PR branches `agent/contracts-T-003-tokens` and `agent/domain-T-002-spike-money`) · By: Advisor (scheduled run) · Date: 2026-10-28

## Decision
A — the UI spec wins for M0. T-001 stays on `system` (as already merged in PR #4); Vazirmatn is evaluated in SP-03 against the §3-1 table, then the Architect drafts ADR-UI-003 for the owner. One clarification to A: during SP-03 the font files are **not committed**, even under `spike/` (§3-1 says no font file enters the repository before ADR-UI-003); the spike fetches a pinned Vazirmatn release at test time and verifies its checksum.

## Why
- Source-of-truth order (AGENTS.md): `docs/design/ui-spec/03-typography-rtl.md` §3-1 and `design_tokens.json` (`font-family-fa`/`font-family-latin` = `system`) outrank the T-001 task packet.
- §3-1 names Vazirmatn only as an evaluation candidate; AD-07 (ت) keeps `system` until ADR-UI-003 is accepted; RKX-04 (wider final font breaks AM-02 thresholds) is exactly what the §3-1 metric/tnum tests catch.
- B would accept an ADR without its acceptance evidence (ADR-UI-003 row of table 12-1-a: section 3 tables, AM-02, VR-04 goldens). C needs a spec erratum for a temporary need; fetch-at-test-time gives the same evidence without one.
- Licence is not the open point: Vazirmatn OFL-1.1 is already recorded in `OPEN_SOURCE_AUDIT.md` §A.

## Actions
- Lead: amend `docs/agents/tasks/T-001.md` Objective ("…empty RTL page with the `system` font; Vazirmatn per SP-03/ESC-001") and add `Status: CLOSED` to the first lines of `ESC-001.md` once this PR is merged.
- Lead: write the SP-03 task packet (owner hat Builder-UI or Builder-Platform): evaluate Vazirmatn against every §3-1 row (coverage incl. U+06F0–U+06F9 and `، ؛ ؟ « » ٪ ٫ ٬ −`, weights 400–700/variable, tabular digits, vertical metrics with «گچپژ یئؤ ۱۲۳۴۵۶۷۸۹۰» on all four OSes, Latin pairing, size); font fetched from a pinned URL + SHA-256 into a git-ignored path; no font file, no token change, no `TextStyle` naming the font (AD-06, TY-02).
- Architect: after SP-03, draft ADR-UI-003 (choice, build Non-Latin vs. Latin-merged, size budget, `third_party/licenses/OFL.txt`) for owner acceptance (D3).
- Builder (after acceptance, same PR per AD-07 ت): add font files + OFL text, change the two tokens, regenerate goldens (TQ-13, VR-04).

## Follow-ups
- Optional: compare one more §3-1 candidate (e.g. Estedad or IRANSansX) in SP-03 if Vazirmatn fails a row; only then is a wider evaluation needed.
- No change needed to the open PRs (T-002, T-003); their copies of ESC-001 close when they merge `main`.

NEEDS_OWNER: yes — ESC-001 is class D3 (ADR-UI-003 acceptance). Nothing is needed from the owner now: decision A only defers acceptance until SP-03 evidence; the owner decides ADR-UI-003 when the Architect's draft arrives. Owner may object to A within the normal Lead relay.
