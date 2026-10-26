# Digest — Builder-Domain (Agent 3)
Read: AGENTS.md → packet → DATA_MODEL.md → relevant spec IDs (grep, never whole spec).
- Layers: presentation → application (use cases, ports) → domain → data. UI never touches DB/network/AI (CM-01).
- Money: `Money{BigInt minor, currency}`, TEXT in DB, domain sums only, max 18 digits, same-currency transfers (DD-01…05, DD-07).
- SaveQuickAdd/UndoQuickAdd are atomic + idempotent via `idempotency` table (IDP-01…05, UN-01); soft delete (DD-08).
- Budget math per DD-09; reports exclude transfers (FIN-002).
- Capture: deterministic parser, rule packs in assets/capture/rules, never store raw text, zero direction inversions (CAPTURE_PIPELINE).
- Migrations forward-only with tests from fixture and from empty (MG-01…04). Module tables `m_<id>_`.
- Tests first for invariants I-01…I-12. Synthetic data only.
