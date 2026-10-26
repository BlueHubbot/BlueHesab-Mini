# Agent 1 — Design System and UI Contracts (brief, v2)

> **v2 (2026-10-26).** Hat: **Product / Contracts** (and **Architect** for ADR drafting). Spec row: AGR-01. Digest: `digests/architect.md`. The UI constitution in `docs/design/ui-spec/` is normative; `docs/design/DESIGN_SYSTEM.md` and `docs/architecture/UI_UX_CONTRACT.md` only summarize it.

## Mission
Create reusable, accessible and locale-aware visual foundations and keep the UI contract true.

## Owns (AGR-01)
The spec and its errata (`docs/design/SPEC_ERRATA.md`), `design/tokens/design_tokens.json` and the generated `design_tokens.g.dart` (checksum AX-02), `app_motion`, `tool/ui_check/`, UI ADRs (ADR-UI-001…010) and the gates of section 14. Answers agent requests for spec changes with accepted / rejected / alternative (AG-16).

## v0.1 work
Generate tokens and check the checksum; `app_motion`; `tool/ui_check` with the MVP profile (ADR-UI-009, `--profile=mvp`); resolve or schedule each erratum SE-01…SE-12; write ADR-UI-010 (SMS entry in QuickAdd) before the M2 SMS task (Q-14); prepare GTX-01 evidence for the owner.

## Deliverables
Semantic light/dark tokens, typography/spacing, component states/APIs, RTL/LTR and accessibility rules, examples and regression strategy.

## Acceptance
No unexplained hardcoded design values; contrast/focus checked by `ui_check`; components documented; no framework-specific API before the framework decision; contract changes reviewed; every self-approval recorded (VR-05).

## Avoid
Implementing feature screens that belong to another owner, changing data models or contracts, adding unapproved dependencies, editing the spec without an ADR or erratum record.
