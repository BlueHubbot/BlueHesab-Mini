# Risks and Assumptions (v2)

**Status:** v2 (2026-10-26). IDs R-001…R-012 are kept from the pack (meaning unchanged, status and mitigation updated); R-013 and later are new. Statuses: `OPEN`, `MITIGATED` (a control exists in the documents), `ACCEPTED`, `CLOSED`. The Lead reviews this table at every milestone.

| ID | Risk | Impact | Mitigation | Status |
|---|---|---|---|---|
| R-001 | Framework may not fit all platforms | High | spike with pass criteria (`SPIKE_PLAN.md`, ADR-0009); reopen ADR-0002 on failure | OPEN until the spike report |
| R-002 | Local AI differs by device and hardware | High | AI is v0.4; provider-neutral contract; benchmark on our tasks (`AI_TOOL_CONTRACT.md`, `LOCAL_MODEL_SETUP.md`) | MITIGATED by scope |
| R-003 | Persian OCR may be inadequate | High | not in v0.1; labeled synthetic evaluation set before any OCR work | OPEN (later) |
| R-004 | License conflicts (the project license vs dependencies) | High | Apache-2.0 (ADR-0007); license scan in CI (SP-11); GPL/AGPL reference-only (`OPEN_SOURCE_AUDIT.md`) | MITIGATED |
| R-005 | Sync conflicts or deletion may lose data | High | no sync in v0.x (ADR-0005/0006); backup file is the bridge | MITIGATED by scope |
| R-006 | Calendar and numerals vary by platform | Medium | one central date/number layer, DT-05 vectors, goldens | OPEN until the spike |
| R-007 | Background reminders are constrained per OS | Medium | no reminders in v0.1; per-platform prototype before `tasks` (NOTIF-001) | MITIGATED by scope |
| R-008 | Scope delays the MVP | High | MVP_SCOPE with explicit exclusions; MVP profile (ADR-UI-009); milestones M0–M3 | OPEN |
| R-009 | Health or location data raises the privacy burden | High | modules v0.5 or later; separate privacy design first | MITIGATED by scope |
| R-010 | A local backup can be lost | High | backup UX with reminders (BR-4 candidate), clear explanation; cloud only after its own design | OPEN |
| R-011 | Plugins and packages change under us | Medium | pinned versions, CI, upgrade policy, dependency audit | OPEN |
| R-012 | H200 server availability is unconfirmed | Medium | MVP does not depend on it; Q-01 answers needed first | OPEN |
| R-013 | Bank SMS formats are diverse and unknown (Q-06) | High | deterministic rule packs per bank, 3–5 banks first, anonymized or synthetic corpus, zero kind inversions as a hard gate (S-05) | OPEN |
| R-014 | Unsigned Windows and macOS builds scare users (Q-07) | Medium | honest install guide, checksums, free open-source signing programs to be checked | OPEN |
| R-015 | Agent workflow failures: loops, cost, drift, unattended wrong merges | High | circuit breakers CB-1…9, task packets, author ≠ reviewer, Advisor at gates; auto wake-up still unverified (Q-03) | OPEN |
| R-016 | Usage or token limits of agent tools stall the work | Medium | short digests, small packets, STATUS as the single resume point, local coding model later (Q-01, Q-02), spend cap (Q-12) | OPEN |
| R-017 | The UI constitution is large (about 930 rules) for a free project | High | MVP profile with declared reductions and non-negotiables (ADR-UI-009) | OPEN until ADR-UI-009 is accepted |
| R-018 | Persian and bidirectional text bugs (digits, mixed LTR, number alignment) | Medium | central formatters, `BidiText`, `NumericCell`, goldens, AMT rows | OPEN until the spike |
| R-019 | Spec gaps and contradictions found late | Medium | `docs_check`, `docs/design/SPEC_ERRATA.md`, escalation rule AG-08 | MITIGATED |
| R-020 | Single owner and few contributors (bus factor) | Medium | everything in files; contributor guide; agents read digests; no knowledge only in chat | ACCEPTED |

## Assumptions to validate
- Commercial use may matter later; the license (Apache-2.0) allows it.
- The core works without an account; the local store is authoritative until a sync design exists.
- The first release contains fewer modules than the final product.
- Cloud features are optional and come later, if at all.
- A real Android phone (4 GB RAM or less) will be available as the reference device (PV-01). This is not confirmed with the owner yet (Q-09); until it is, the gate records "reference device pending" and no release candidate is tagged (ADR-UI-009).
