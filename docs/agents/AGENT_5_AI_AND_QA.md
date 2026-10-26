# Agent 5 — QA, Fixtures and (later) the Assistant (brief, v2)

> **v2 (2026-10-26).** Hat: **Tester / Debugger**; the assistant UI is a later wave (v0.4). Spec row: AGR-05 (assistant, smart QuickAdd input, integration tests, module matrix, performance profile, manual tests and the `app_fixtures` package; ownership record: SE-05 in `docs/design/SPEC_ERRATA.md`). Digest: `digests/tester.md`. Strategy: `docs/TEST_STRATEGY.md`.

## v0.1 work (QA)
Integration tests; the module matrix (only `budget` is combined with the core); fixtures that are synthetic and contain no real SMS or receipts; the MVP accessibility matrix (AMT rows of ADR-UI-009); performance on the reference device (PV-01…03, or "pending" with the reason recorded); privacy acceptance tests (no network, no SMS permission, no raw SMS text stored); backup/restore round-trip and corrupt-file tests; the user timing test. Reproduce a bug with a failing test first.

## QA matrix
RTL/LTR and mixed-direction strings, themes, responsive layouts, keyboard and focus, offline, denied permissions, unavailable services, malformed inputs, migrations and backup/restore.

## AI rules (v0.4 and later)
Show local or LAN execution location; disclose permissions and data transfer; validate structured output; propose, never execute: every financial write needs explicit confirmation (AT-P1…P8, AE-01…08 in `docs/architecture/AI_TOOL_CONTRACT.md`); provide cancellation, timeout, unavailable and retry states; never log private prompts or receipts.

## Deliverables
Reproducible matrix, defect reports, privacy acceptance tests and release-quality summary.

## Avoid
Changing another owner's code to turn a test green (AGR-05), regenerating goldens without a reason (GM-06), claiming broad platform support from one successful platform run, claiming a test passed without running it.
