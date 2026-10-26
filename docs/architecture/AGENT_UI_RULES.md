# Agent UI Rules (v2)

**Status:** v2 (2026-10-26). Short operating rules for any agent that touches the UI. The detailed protocol is spec section 13 (`docs/design/ui-spec/13-agent-protocol.md`: AG-01…AG-17, AGR, AGX, TCF); `AGENTS.md` has the project-wide hard rules. This file replaces the pack's v1 and fixes its source-of-truth order.

## Source of truth (highest first)
1. `docs/design/ui-spec/` (the UI constitution) and `design/tokens/design_tokens.json`.
2. Accepted ADRs (`ADR-UI-NNN` for UI, `ADR-NNNN` for architecture). While an ADR is only PROPOSED the spec text governs.
3. `docs/product/MVP_SCOPE.md` and `docs/design/PAGE_INVENTORY.md` (what v0.1 builds).
4. Shared component API docs and tests.
`docs/architecture/UI_UX_CONTRACT.md` and `docs/design/DESIGN_SYSTEM.md` are summaries, not sources.
If two sources conflict, or a rule ID is missing: stop, record both IDs in the report's "Open questions" and escalate (AG-08); never choose silently and never invent numbers (AG-05).

## Forbidden without approval
- Changing shared token names or meaning; adding a color pair or token (needs an ADR, AD-05).
- Replacing navigation patterns; adding another design system or icon family.
- Calling the database, the network or an AI provider from a widget (CM-01).
- Writing Persian strings in code (use the catalog, CM-10) or raw colors, sizes and durations (TK-13, TY-02, MT rows).
- Changing shared routes or public component signatures.
- Adding a dependency without the license and maintenance check (`docs/research/OPEN_SOURCE_AUDIT.md`).
- Building a module, route, copy key or QuickAdd type of a module that is not in the build (DM-01, ADR-UI-009).
- Deleting or rewriting another agent's work; pushing to `main`.

## Before implementation
Have a task packet with: task and rule IDs, owning hat, allowed and forbidden paths, dependencies, platform/locale/theme impact, acceptance criteria and tests. For a destination page, also the information map (HI-01, TCF-03) approved by Product/Contracts.

## Every UI PR includes
Summary and cited rule IDs; screenshots or recordings with no private data; changed routes, components and tokens; RTL (and LTR overflow) and light/dark verification; accessibility notes; tests with real output; limitations; dependency/license changes; an ADR for any contract change.

## Ownership (spec agents mapped to hats)
| Spec agent | Hat (`AUTONOMY_AND_ESCALATION.md` §1) | Owns |
|---|---|---|
| Agent 1 | Product/Contracts (+ Architect for ADR drafting) | tokens, shared component API, `tool/ui_check`, ADRs, gate records |
| Agent 2 | Builder-UI | shell, navigation, Home, Settings |
| Agent 3 | Builder-Domain | accounting, budget, reports, QuickAdd finance forms, capture |
| Agent 4 | Builder-UI (life modules, later waves) | tasks, health, car, markets pages |
| Agent 5 | Tester/Debugger (assistant later) | integration tests, matrix, fixtures, performance, manual-test runs |
Ownership does not bypass review: author ≠ reviewer.

## Merge gates
Scoped PR; relevant CI green with real output; a reviewer other than the author (fresh session); Product/Contracts approval for shared-contract changes; gate reports state the profile and manifest hash (ADR-UI-009). Resolve conflicts by coordination (conflict protocol in `AGENT_OPERATING_MODEL.md`), never by force-overwriting.
