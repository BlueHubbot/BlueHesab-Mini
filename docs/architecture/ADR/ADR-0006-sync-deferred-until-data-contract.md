# ADR-0006: Defer bidirectional sync until data contracts are ready
- **Status:** ACCEPTED (product owner, 2026-10-26, Q-15)
- **Date:** 2026-10-23
- **Owner:** Data architect
- **Approver:** Product owner

## Context
Sync creates conflict, deletion, migration, encryption and recovery risks.

## Options
Ship bidirectional sync immediately; ship one-way backup; defer sync while delivering local-first core and export.

## Proposed decision
Defer bidirectional sync until stable IDs, versions, tombstones, conflict policy, encryption/key recovery, account deletion and cross-version migration are specified and tested.

## Consequences
MVP scope is smaller and data-loss risk lower. Multi-device sync is delayed. Export/backup should still be designed early.

## Revisit trigger
Core local-first workflows and a reviewed sync protocol are ready.

## Update 2026-10-26 (status stays PROPOSED until the owner accepts it with the batch, Q-15)
- **What exists now:** a local data contract (`docs/architecture/DATA_MODEL.md`: DD-01…11, MG-01…05, invariants I-01…I-12). It is not a sync contract: version metadata, tombstone propagation, conflict policy, encryption and key recovery, account deletion and cross-version migration are still unspecified, so the deferral stands.
- **Roadmap:** sync is listed under "later, optional" in `docs/product/MODULE_ROADMAP.md` and `docs/IMPLEMENTATION_ROADMAP.md`. It needs its own design and a security review before any code (D3 for the owner).
- **Risk register:** R-005 (sync conflicts or deletion may lose data) is mitigated by scope.
