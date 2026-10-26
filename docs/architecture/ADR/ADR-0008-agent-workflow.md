# ADR-0008: Agentic development workflow
- **Status:** ACCEPTED (core model, confirmed by product owner 2026-10-25); sections marked PENDING need verification
- **Date:** 2026-10-25
- **Owner:** Lead architect
- **Approver:** Product owner

## Context and problem
Development is done by AI agents with minimal human work. Budget is limited (subscription limits), UI spec is ~800 KB, the product handles financial data, and local models are less reliable than frontier models.

## Decision drivers
Low human effort; low token cost; safe handling of financial code; recoverability after interruptions; no overlapping work; clear accountability.

## Options considered
1. Many agents in parallel, all talking to the human.
2. One Lead as the only contact with the human, specialists working one at a time, a separate Advisor for gates.
3. Fully autonomous agents with no human gates.

## Decision
Option 2.

1. **Lead** is the only agent that communicates with the product owner. It plans, splits work into task packets and keeps `docs/ops/STATUS.md`.
2. **Roles** (hats worn one at a time, each with its own prompt and file boundaries): Lead/Orchestrator, Architect, Product/Contracts, Builders (UI, Domain, Platform), Tester/Debugger, Security & License, Docs & Bridge, Integrator. The UI spec's Agent 1–5 are a subset of these (mapping in `AUTONOMY_AND_ESCALATION.md`).
3. **One builder at a time.** One branch/worktree per task; PR only; review by a different session than the author.
4. **Advisor** (a frontier-model session) is consulted only at gates and ambiguities, through files in git (`docs/ops/escalations/ESC-NNN.md` → `ADVISOR_REPLY-NNN.md`). Messages are one page, cite rule IDs.
5. **Human gates (never automated):** accepting ADRs, passing gates GTX-01 and GTX-06, store/developer accounts and payments, legal/licensing doubts, real-money behavior, public releases.
6. **Execution models:** routine implementation and tests may run on the local H200 model; contract-heavy and gate work on a frontier model. Model choice is made by measured benchmark on our own tasks, not by name.
7. **Safety:** agents run in a sandbox (container/VM) with only the repo mounted, no secrets, no access to unrelated folders; no destructive git or shell commands outside their worktree.

## Reasons
Sequential single-builder work removes merge conflicts and fits the token budget; the Lead protects the human's attention; Advisor-at-gates keeps expensive reasoning rare; files in git make every step resumable.

## Consequences and trade-offs
Slower than full parallelism but cheaper and safer. Human involvement is reduced to short approvals, not zero. A weaker local Lead may mis-route work, so every gate and every ADR still has an independent reviewer.

## PENDING verification
- Automatic wake-up of the Advisor (scheduled task that reads the repo, replies in git, pushes) — see `OPEN_QUESTIONS.md` Q-03. Until verified: the owner sends a one-line "read" message.
- Which local model and serving stack on the H200 (Q-01, Q-02, `LOCAL_MODEL_SETUP.md`).

## Evidence and links
`docs/agents/AGENT_OPERATING_MODEL.md`, `docs/design/ui-spec/13-agent-protocol.md`, `AGENTS.md`, `docs/agents/RUNBOOK.md`.

## Revisit triggers
Budget changes; local model quality is insufficient; automation of the Advisor proves possible and reliable; repeated merge conflicts.

## Related
Requirements: AI-001; ADR-0007.
