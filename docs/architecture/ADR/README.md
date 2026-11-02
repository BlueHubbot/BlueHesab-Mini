# Architecture Decision Records

Lifecycle: `PROPOSED` → `ACCEPTED` or `REJECTED` → `SUPERSEDED`.
Do not rewrite accepted history; create a superseding ADR. A proposal is not implementation authorization.

## Two numbering namespaces (both live in this folder)
- `ADR-NNNN-short-kebab-case.md`: product and architecture decisions (framework, storage, AI, license, workflow, platforms).
- `ADR-UI-NNN`: UI/UX decisions defined in `docs/design/ui-spec/12-risks-and-adrs.md` (ADR-UI-001 … ADR-UI-008, then ADR-UI-009+). Their text, default and acceptance test live in that spec section; the accepted outcome is recorded here as `ADR-UI-NNN-short-kebab-case.md`.
A new decision never reuses a number from either namespace.

ADR-UI-NNN files follow the section list of spec rule AD-01 (context, options, decision criteria, decision, consequences, acceptance test, status) and may add the sections below.
Required sections: status/date, context, decision drivers, options, decision, reasons, consequences, security/privacy/licensing implications, evidence, revisit triggers, owner and approver.

## Index
| ADR | Topic | Status |
|---|---|---|
| ADR-0001, ADR-0005, ADR-0006 | local-first; sync deferred | ACCEPTED (2026-10-26) |
| ADR-0002 … ADR-0004 | framework, storage, AI abstraction | PROPOSED (framework/storage await the spike) |
| ADR-0007 | License: Apache-2.0 | ACCEPTED |
| ADR-0008 | Agentic workflow | ACCEPTED (some items pending) |
| ADR-0009 | Platform scope, release order, technology baseline | ACCEPTED (2026-10-26; framework conditional on the spike) |
| ADR-UI-001 … 008 | see UI spec section 12 | PROPOSED |
| ADR-UI-009 | MVP profile (reduced gates, same guarantees) | ACCEPTED (2026-10-26) |
| ADR-UI-010 | SMS entry in QuickAdd, provenance row, uncertainty marker | planned (before the M2 SMS task; Q-14) |
| ADR-UI-011 | Rewi identity, four themes, automatic and custom themes | ACCEPTED (2026-11-01) |
