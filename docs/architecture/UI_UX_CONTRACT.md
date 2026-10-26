# BlueHesab Mini — UI/UX Contract (v2: summary and pointers)

**Status:** v2 (2026-10-26). **Non-normative summary.** The normative text is the UI constitution in `docs/design/ui-spec/` (index: its `README.md`) and `design/tokens/design_tokens.json`. This file only states the principles in one page and says where each rule lives. If this page and the spec differ, the spec wins; report the difference (`AGENTS.md`, escalation). It replaces the v1 draft of the pack, whose token table and component list are now owned by the spec and the tokens file (no values are repeated here, so they cannot drift).

## Principles
1. One product across platforms: responsive layout, shared concepts and contracts. Window classes Compact, Medium, Expanded, Large (spec section 5).
2. Local-first supported core workflows (ADR-0001, ADR-0009).
3. UI talks to application/use-case interfaces only; never to the database, the network or an AI model (CM-01, AGENTS.md hard rules).
4. Modules are independently enabled and leave no trace when off or not built (DM-01, `MODULE_CONTRACT.md`).
5. Persian RTL is complete in v0.1; LTR layout is tested from v0.1 and English texts arrive in v0.3. Dates, numbers and currency are locale-aware through central formatters (spec section 3).
6. Accessibility is part of acceptance (spec sections 7 and 11, AMT rows).
7. Shared contracts change only through review and an ADR (AD-01…AD-07).

## Visual direction
Minimal, professional and personal: calm, precise, restrained semantic color, subtle borders, almost no shadows, light/dark/system themes, one design system. Identity and motion rules: spec sections 1 and 4. Values: tokens file only.

## Where to find things
| Topic | Spec section / file |
|---|---|
| Identity, DayRing, three-tier information pattern | `01-identity.md`, `06-quickadd-and-three-tier.md` |
| Tokens (color, spacing, radius, type, motion, contrast pairs) | `02-tokens.md`, `A-appendix-tokens.md`, `design/tokens/design_tokens.json` |
| Typography, RTL, numbers, dates, charts direction | `03-typography-rtl.md` |
| Motion | `04-motion.md` |
| Navigation, destinations, Home, disabled modules | `05-navigation-home-modules.md` |
| QuickAdd | `06-quickadd-and-three-tier.md`, `07-components/7-11-quickadd-assembly.md` |
| Components (states, APIs, tests) | `07-components/` (inventory table 7-0) |
| Assistant UI | `08-assistant-ui.md` (v0.4; not built in v0.1) |
| Copy catalog and tone | `09-tone-and-copy.md` |
| Style Guide, fixtures | `10-style-guide-and-fixtures.md` |
| Machine checks, goldens, accessibility and performance tests | `11-testing-and-machine-checks.md` |
| Risks and UI ADRs | `12-risks-and-adrs.md` |
| Agent protocol and page task card | `13-agent-protocol.md` |
| Order of work and gates | `14-execution-order-and-gates.md` |

## What v0.1 builds
The MVP profile (ADR-UI-009) lists exactly what exists in the build: destinations Home, Accounting, Reports, Settings and Budget; QuickAdd types expense, income and transfer; the components named in `docs/product/MVP_SCOPE.md` §3; pages in `docs/design/PAGE_INVENTORY.md`. Not built in v0.1 (and so absent from the app): Tasks, Health, Car, Markets, Assistant, SyncStatus, OfflineBanner, AIActionCard, global search, attachments. Items that are not built are reported as `NOT_IN_BUILD` at each gate, never silently skipped.

## Page anatomy and states
Every destination page starts from its information map (HI-01, TCF-03) and uses only the page parts the spec defines (`PageHeader`, `FilterBar`, summary and list areas, state components). Every page defines loading, empty and error states (ST rows). v0.1 has no sync and no network: states such as saved-locally/sync-pending, syncing, conflict and offline do not exist yet.

## Forms and feedback
Forms keep recoverable input and show field-level errors; destructive actions need confirmation or an undo; success appears only after the use case returned and the data is persisted (SV-01); currency, date and percentage use the central formatters; color is never the only status cue (CM-11).

## Architecture boundary
UI calls application interfaces. Routing, state management and charting choices are separate decisions (ADR-0009 lists candidates; ADR-UI-005/006/007 cover icons, charts and framework spike criteria).

## Acceptance checklist (every UI change)
- [ ] Rule IDs of the spec cited in the PR; `ui_check` stages green once the tool exists
- [ ] Token-only styling; no Persian string in code (catalog only)
- [ ] Light and dark; RTL (and LTR overflow tests at scale 1.0 and 2.0 per ADR-UI-009)
- [ ] Loading, empty and error states
- [ ] Keyboard/accessibility semantics
- [ ] Money only through `CurrencyAmount` and the central formatter
- [ ] Tests and goldens per `docs/TEST_STRATEGY.md`
- [ ] ADR and migration notes for any shared-contract change
- [ ] Dependency/license review for any new package
