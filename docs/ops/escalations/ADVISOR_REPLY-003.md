# ADVISOR_REPLY-003 — MC-08 / MC-01 "allowed in" vs. token files in `lib/design/tokens/`
- Replies to: ESC-003 (lives on PR #25, branch `agent/contracts-T-016-ui-check-rules`) · Date: 2026-11-03 · By: Advisor (scheduled run)
- Rule IDs read: MC-01, MC-05, MC-07, MC-08 (table 11-2-a), VR-02, VR-03, VR-07 (`11-testing-and-machine-checks.md`); MX-03 and the §4-2 `context.motion` sample (`04-motion.md`); TK-01; ADR-UI-011 §3; AG-02 (via `SPEC_ERRATA.md` header). Code checked: `tool/ui_check/src/generator.dart:269-270` (PR #25), `lib/design/tokens/design_tokens.g.dart` (14 × `Duration(milliseconds:`, PR #25), `lib/design/tokens/theme_derivation.dart` and `contrast_guard.dart` (PR #21).

## Decision
**A, with a narrower MC-01 scope.**
- **MC-08:** "allowed in" += the generated token file `design_tokens.g.dart` (same pattern as MC-01, MC-05, MC-07). `app_motion` stays the only place that builds animations and reads motion for UI (`context.motion`, MX-03).
- **MC-01:** "allowed in" += exactly two named files, `lib/design/tokens/theme_derivation.dart` and `lib/design/tokens/contrast_guard.dart`, on the condition that they stay pure Dart (no `package:flutter` import, no `Color`/`Colors.`, no widget). Not the whole `lib/design/tokens/` directory: a directory-wide cell would let a future widget file there escape MC-01 (VR-03 "no hidden exemption").
- **B and C rejected:** they reshape correct code around a text pattern and rework PR #21, with no gain in what the rule protects (no raw colours/durations in UI).

## Why
1. MC-01/05/07 already list the generated file; MC-08 omitting it reads as an omission, and §4-2 values come from appendix A via that file (TK-01), so the generator cannot avoid `Duration(milliseconds:`.
2. ADR-UI-011 §3 (accepted) needs a live contrast guard on user-picked colours; MC-01 predates it. Pure-int RGB computation is not UI colour usage.
3. Naming two files (not a folder) keeps the exception visible and checkable, as VR-03 requires.
4. Note for the checker: `0xFF` channel masks in these files are not colours; MC-01 should match colour-shaped hex (6/8 digits, or `Color(0x`), so masks need no exception. The one real colour literal, `scrim` `0x000000` in `theme_derivation.dart:178`, is covered by the named-file exception (D2-derived role, ADVISOR_REPLY-002).

## Actions
| # | File(s) | Owner hat |
|---|---|---|
| 1 | Add a new erratum entry (next free SE number) to `docs/design/SPEC_ERRATA.md` (MC-08 += generated token file; MC-01 += the two named pure-Dart files; interim rule = this reply), then amend the two cells of table 11-2-a per AG-02 with reason "ADVISOR_REPLY-003" | Product/Contracts (Agent 1), on PR #25 or a follow-up PR |
| 2 | `tool/ui_check/src/rules_stage.dart`: MC-08 skips `design_tokens.g.dart`; MC-01 skips only the two named files and still flags them if they import `package:flutter` or use `Color(`/`Colors.`; add VR-07(a) bad/good samples for both new cells | Product/Contracts (T-016) |
| 3 | The MC-01 part takes effect only once PR #21 lands those files; until then only the MC-08 part is live | Product/Contracts |
| 4 | After actions 1–2 are green, wire `ui_check rules` as a blocking CI step (VR-02) before the first M1 UI component task | Builder-Platform (`.github/**`) |

## Follow-ups
- Agent 1 approval required by VR-03 is given by this D2 reply plus that new erratum entry; no owner decision needed.
- If T-013 later moves the guard into a Flutter-facing file, that file gets no MC-01 exception; it must call the pure functions.
- Lead sets `Status: CLOSED` on ESC-003 after action 1 is merged.

NEEDS_OWNER: no
