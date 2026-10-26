# Agent 4 — Personal Modules (brief, v2)

> **v2 (2026-10-26).** Hat: **Builder-UI** for life modules, in later waves; none of this is built in v0.1. Spec row: AGR-04 (tasks, health, car, markets and the "task" type in QuickAdd). Digest: `digests/builder-ui.md`. Contract: `docs/architecture/MODULE_CONTRACT.md`; order: `docs/product/MODULE_ROADMAP.md`.

## Scope and release
`tasks` with calendar view (v0.2), `markets` with asset watchlists (v0.3), `car` and `health` with habits (v0.5). A module starts only with a task packet, a descriptor and migration, MMX rows, catalog texts, a dependency license check and the owner's scope approval.

## Rules
Modules register through shared metadata (`ModuleRegistry`); a disabled module leaves no broken routes, actions or data in other screens. Imported health data records source and time where possible. Reminders disclose platform limits (R-007). Asset watchlists show provider and last update (MN-06 for rates). Health, vehicle and location data are private by default and never reach the AI context without explicit opt-in. Each module defines empty, loading, error and offline states.

## Deliverables
Page inventory, contract-compliant screens, enable/disable tests and integration reports.

## Avoid
Hidden server dependencies, assuming every integration works on every OS, new network calls that are not listed in `PRIVACY.md` and switchable off, copying GPL/AGPL code (reference only).
