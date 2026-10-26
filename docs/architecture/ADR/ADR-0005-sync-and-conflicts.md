# ADR-0005: Optional sync and conflicts
- **Status:** PROPOSED
- **Date:** 2026-10-23
- **Owner:** Data architect
- **Approver:** Product owner

## Context
Optional cloud backup/multi-device sync is desired, but offline writes create conflict/deletion questions.

## Options
No sync in MVP with export; one-way backup; bidirectional sync with versioned records and conflict resolution.

## Proposed direction
Keep sync out of the first implementation slice until identity, versioning, conflict policy, encryption and deletion semantics are specified. Design export/backup early.

## Required questions
Concurrent edits; tombstones; migrations across clients; auto-mergeable fields; cloud opt-out/account deletion; portability; encryption/key recovery.

## Revisit trigger
Validated MVP and user demand justify multi-device sync.

## Update 2026-10-26 (status stays PROPOSED)
- **Decision of record is ADR-0006:** sync is deferred; this ADR keeps the open design questions. Owner position (2026-10-25): no sync in v0.x.
- **Between devices, the backup file is the bridge:** export on one device, restore on another (`docs/BACKUP_RESTORE.md`).
- **Groundwork already in the data contract** so a later sync needs no rewrite: client-generated UUIDv7 IDs, `updated_at`, soft delete with `deleted_at`, forward-only migrations with checksums (`docs/architecture/DATA_MODEL.md`).
- **Still unspecified, on purpose:** concurrent edit policy, tombstone propagation, per-field merge, encryption and key recovery, account deletion. See "Before any sync ships" in `docs/DATA_GOVERNANCE.md`.
