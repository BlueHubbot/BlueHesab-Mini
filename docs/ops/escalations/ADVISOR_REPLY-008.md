# ADVISOR_REPLY-008 — SE-12: day-ring empty text vs. enabled modules
- Replies to: ESC-008 (lives on PR #47, branch `agent/lead-T-033-se12-esc`, task T-033) · Date: 2026-11-15 · By: Advisor · Class: D2

## Decision
**A** — the day-ring card keeps its fixed place (HM-01) but is rendered only while at least one arc-providing module is enabled (DM-01); the empty text is one complete catalog sentence per enabled provider set (KN-03), with only `budget` needed in v0.1.

## Why
- C breaks KN-03 (no sentence built from separate keys) and needs a `MODULE_CONTRACT` descriptor field; that is a contract change for a low-severity gap.
- B adds Persian copy with no spec source (AG-05) and leaves a card that can never fill when every provider is off, which conflicts with the spirit of DM-01.
- A is already the SE-12 interim rule, so closing it changes no behaviour; MDC-A4 already filters DayRing arcs from the registry by enabled state, so the host can pick the key without a new contract field (MODULE_CONTRACT line 52: "the host decides the empty state").
- Rows grow combinatorially, but KN-04 adds them only when a module ships; v0.1 needs one row.

## Actions
1. **Product/Contracts hat (Agent 1), T-033 / PR #47:** amend in one spec PR citing SE-12:
   - `01-identity.md` VI-15 and `09-tone-and-copy.md` HMX-01: the empty text is chosen by the set of enabled arc-providing modules; each set has its own full sentence. HMX-01 (budget only): «برای دیدن وضعیت امروز، یک بودجه اضافه کنید.» (the existing sentence minus «یا یک عادت»; no new wording, AG-05). Do not publish rows for unbuilt modules now (KN-04).
   - `05-navigation-home-modules.md` HM-01: «ثابت» means fixed position; the card is shown only while ≥1 arc-providing module is enabled. HM-02: with ≥1 such module enabled and no arc, show `EmptyState` per VI-15.
   - DM-01: add «متن حالت خالی» to the list of places a disabled module must leave no trace.
   - `docs/design/SPEC_ERRATA.md` SE-12: status `CLOSED` with the PR link; delete the interim rule.
   - `docs/architecture/MODULE_CONTRACT.md` budget rows (lines 77, 79): replace the "interim rule of SE-12" wording with the amended HM-01/VI-15 references. Wording only; no interface change.
2. **Builder-UI (Home task, M2):** a small host-side mapping next to the registry (MDC-A4) from enabled provider set → HMX key; no literal in widgets (CM-10).
3. **Tester:** DM-07 matrix asserts the card is absent with all providers off and that no empty sentence names a disabled module.

## Follow-ups
- When `habit` or `task` ships, Agent 1 adds the matching HMX rows (single and combined sets) in that module's task (KN-04).
- If provider count ever makes the row set unwieldy (>7), reopen as a new erratum rather than relaxing KN-03.

NEEDS_OWNER: no
