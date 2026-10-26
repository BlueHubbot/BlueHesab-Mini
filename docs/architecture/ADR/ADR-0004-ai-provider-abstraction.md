# ADR-0004: Provider-neutral AI architecture
- **Status:** PROPOSED
- **Date:** 2026-10-23
- **Owner:** AI architect
- **Approver:** Lead architect

## Context
Inference may be embedded locally, hosted by a local companion service or cloud-based. Support varies by hardware/platform.

## Options
Direct provider calls from UI; provider-neutral application interface; mandatory cloud AI.

## Proposed decision
Use a provider-neutral AI interface with capability discovery, privacy labels, cancellation/timeouts, structured errors and fallback.

## Contract
Provider/execution location; task/model capabilities; validated input/output schema; consent/data classification; cancellation/resource limits; timeout/error taxonomy; human review for consequential writes; privacy-safe logging.

## Consequences
Adapters require extra tests but reduce lock-in. Local inference is not promised on every platform.

## Update 2026-10-26 (status stays PROPOSED until the assistant starts, v0.4)
- **Scope:** the assistant is not part of v0.1 (`docs/product/MVP_SCOPE.md`). Execution is local or on the owner's LAN only; no cloud provider is planned. Mandatory cloud AI stays rejected.
- **Contract:** `docs/architecture/AI_TOOL_CONTRACT.md` makes this ADR concrete: the provider interface, read tools, `propose_transaction`, explicit user confirmation for every write (AT-P1…P8, AE-01…08), privacy-safe logging and the error taxonomy. The assistant proposes and never executes.
- **Model choice:** none is locked. The H200 server first runs benchmarks on our own tasks for the agents' coding model (Q-01, Q-02, `docs/agents/LOCAL_MODEL_SETUP.md`); the app's assistant may later point to the same server, reachable only over LAN or VPN (LM-5, AT-P6).
- **Related:** CAPTURE_PIPELINE (deterministic parser first; AI is never needed for SMS capture in v0.1).
