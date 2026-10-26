# Agent Operating Model (v2, replaces the five-agent stub)

**Status:** PROPOSED, consistent with ADR-0008 (accepted core). Details of authority, escalation and automation: `AUTONOMY_AND_ESCALATION.md`. Runtime habits and effort levels: `RUNBOOK.md`.

## Governance
One **Lead** is the single point of contact with the product owner and the keeper of `docs/ops/STATUS.md`. Specialists work as **hats**, one active builder at a time. An independent **Advisor** reviews at gates and on escalation. The Lead does not overwrite specialist work; specialists do not redefine shared architecture or the UI constitution.

## Roles
Lead/Orchestrator · Architect · Product/Contracts · Builder-UI · Builder-Domain · Builder-Platform · Tester/Debugger · Security & License · Docs & Bridge · Integrator.
Mapping to the UI spec's agents (AGR-01…05): Agent 1 = Product/Contracts (+ Architect for ADR drafting), Agent 2 = Builder-UI (shell, home, settings), Agent 3 = Builder-Domain (accounting, budget, reports, QuickAdd finance forms, capture), Agent 4 = Builder-UI for life modules (later waves), Agent 5 = Tester/Debugger (integration, matrix, fixtures, performance) and, later, the assistant. Path boundaries per hat are in `AUTONOMY_AND_ESCALATION.md` §1.

## Task packet (required)
Stored as `docs/agents/tasks/T-XXX.md` with the spec's TCF fields: understanding summary (AG-06), owner and scope (AGR row, allowed/forbidden paths, who consumes the output), requirement/rule IDs, objective and non-goals, dependencies and contract versions, acceptance criteria with evidence, tests to run, branch/worktree name, time/token budget (for CB-2), deliverables and handoff format. A packet without acceptance criteria is not started.

## Isolation rules
- One branch/worktree per active task: `agent/<role>-<task-id>-<slug>`. No shared mutable worktree.
- Only the Integrator merges, via reviewed PR. Shared contracts have one owner.
- Never reset, stash, checkout over or force-push another agent's work.
- Verify root (`pwd`), branch and `git status` before mutating commands. Stop on unexpected state; report instead of cleaning (CB-3).
- Agents run sandboxed (container/VM) with only the repo mounted and no secrets.

## Git rules
Small, scoped commits; PR to `main` only; PR text names requirement/rule IDs, tests run (real output), risks, screenshots for UI, migrations. Never commit secrets, private data, real SMS/receipts, model binaries or build output. Commit messages and branches in English.

## Review rule
Author ≠ reviewer. Reviewer is a fresh session with the Reviewer prompt and reads the PR, packet and cited rule IDs only. Tester runs tests independently of the builder. Contract, ADR and gate work additionally goes to the Advisor (per autonomy level).

## Conflict protocol
Stop editing the contested file → tell the Lead with intended changes → Lead assigns one owner or creates a contract → integrate with an explicit plan → run tests and review the diff → record the handoff. Two sessions on one file: the newer stops (CB-8).

## Status vocabulary
`NOT_STARTED`, `IN_PROGRESS`, `BLOCKED` (with ESC id), `READY_FOR_REVIEW`, `CHANGES_REQUESTED`, `MERGED`, `DONE`.
`DONE` = merged, tests green with evidence, docs/STATUS updated, handoff written.

## Relation to the earlier role briefs
`LEAD_ARCHITECT.md` and `AGENT_1…5_*.md` stay valid as detailed briefs for the matching hats (see mapping above). For token economy, agents read the short digests in `docs/agents/digests/` first (planned, H8) and open the long briefs only when a task needs them. `TASK_TEMPLATE.md` and `HANDOFF_TEMPLATE.md` remain the templates for task packets and handoffs.
