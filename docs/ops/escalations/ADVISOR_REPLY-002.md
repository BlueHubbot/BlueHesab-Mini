# ADVISOR_REPLY-002 — Themes v2: where the 38 missing colour roles come from
- Replies to: ESC-002 (lives on PR #21, branch `agent/contracts-T-012-tokens-v2`) · Date: 2026-11-01 · By: Advisor (scheduled run)
- Rule IDs read: ADR-UI-011 §1 and "Consequences", T-012 packet, SE-13, VTG-01…VTG-04 (`11-testing-and-machine-checks.md`, `A-appendix-tokens.md`), AG-05, AG-08, AG-16

## Decision
**Other = B + A split, as the ESC recommends.**
- **B (derived by a written, tested rule, no owner value needed):** hover/pressed variants, `*-subtle` tints, `focus-ring`, `text-disabled`, `inverse-*`, `scrim`, elevation shadow colours. Every derived value must pass its VTG group through `contrast_guard`.
- **A (values from the owner):** `success`, `warning`, `danger`, `info` and the three module accents, per theme (4 × 7 = 28 values). Product/Contracts may attach a *proposed* guard-passing candidate table to make the owner's pass fast, labelled PROPOSED; nothing is merged until the owner approves or replaces it.
- **Clay:** keep the v2 `accent` as the fill/brand colour; for `accent`/`primary` used as text, use the guard's nearest passing shade (`#B3482F`, 4.51:1 on `surface`) as a separate role. On the Clay `background`, VTG-01 is satisfied by `on_bg_text` only (ADR-UI-011 "Consequences"); record this as an erratum rather than silently skipping the pair.
- **C is rejected** (rewrites the VTG groups and money colours, AG-02; highest risk).

## Why
1. Mechanical roles (states, tints, focus, scrim) follow from the 8 defined roles by formula; a written rule + guard is derivation, not invention (AG-05/AG-08 satisfied).
2. Income/expense/warning/danger colours carry money meaning; the owner must see and pick them (ADR-UI-011 approver is the owner).
3. Keeping the 46-role contract and 210 VTG checks keeps every later component unchanged.
4. Clay's 4.45:1 accent and mid-tone background are handled by an explicit text-variant role and a recorded exception, not by lowering thresholds.

## Actions
| # | File(s) | Owner hat |
|---|---|---|
| 1 | Write the derivation rule (mix ratios, guard step direction) in `docs/agents/tasks/T-012.md` and `docs/design/SPEC_ERRATA.md` SE-13 (Options → chosen); implement it in `tool/ui_check/**` with tests | Product/Contracts (T-012, PR #21 or a follow-up PR) |
| 2 | Add the Clay text-variant role and the Clay `background` VTG-01 exception (`on_bg_text`) as an erratum entry; amend `A-appendix-tokens.md` A-2-a per AG-02 with reason | Product/Contracts |
| 3 | Prepare `design/brand/themes-v2.json` → v3 candidate table: 28 status/module values marked PROPOSED, each with its VTG-02/03/04 ratios | Product/Contracts |
| 4 | Ask the owner to approve or replace the 28 values (one review, shown per theme on the Style Guide canvas or a table) | Lead → owner |
| 5 | After approval: write four themes into `design/tokens/design_tokens.json`, bump major version and AX-02 checksum, regenerate `design_tokens.g.dart` (MC-02), run full VTG set per theme | Product/Contracts (T-012 criteria 1 and 4) |

## Follow-ups
- Until action 4 is done, interim rule SE-13 stays: v1.1 tokens bind code; T-010 and T-013 stay blocked (safe, no screen uses v2).
- Actions 1–3 do not depend on the owner and may start now (AG-16).
- Lead sets `Status: CLOSED` on ESC-002 after action 5 lands and SE-13 is closed per its checklist.

NEEDS_OWNER: yes
