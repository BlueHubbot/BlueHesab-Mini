# ADR-0003: Local storage and migrations
- **Status:** PROPOSED
- **Date:** 2026-10-23
- **Owner:** Data architect
- **Approver:** Lead architect

## Context
Need durable finance records, migrations, export/restore and possible future sync.

## Options
SQLite binding; platform-specific stores; IndexedDB plus native adapters; abstraction with per-platform drivers.

## Proposed direction
Evaluate SQLite-family storage for native platforms and explicitly define a browser strategy. Do not assume one plugin behaves identically everywhere.

## Required questions
Stable IDs; monetary precision; timestamps/timezones; migration transactions; backup consistency/encryption; attachments; concurrency; browser quotas/eviction; export versioning; future sync metadata.

## Acceptance evidence
Migration tests, offline CRUD, restart, backup/restore round-trip, corrupt backup handling and platform integration tests.

## Update 2026-10-26 (status stays PROPOSED until the spike confirms the driver)
- **Direction:** a SQLite-family database on all four targets; Drift is the leading candidate (MIT license verified, see `docs/research/OPEN_SOURCE_AUDIT.md`); SQLCipher-style encryption is optional and later. The web demo stores no finance data, so no browser storage strategy is needed (ADR-0009).
- **The required questions are answered in `docs/architecture/DATA_MODEL.md` and related documents:**

| Question | Answer |
|---|---|
| Stable IDs | UUIDv7 as lowercase `TEXT`, generated on the client; `clientRequestId` for idempotency (I-05) |
| Monetary precision | `BigInt` minor units as decimal `TEXT`, at most 18 digits (DD-01…05, I-01) |
| Timestamps and time zones | UTC ISO-8601 instants, separate `yyyy-MM-dd` date-only fields, Jalali as display and boundary rule (DT-05 vectors, I-08) |
| Migration transactions | forward-only, one transaction, recovery copy first, tested from the previous fixture and from empty (MG-01…04) |
| Backup consistency and encryption | validated before any change, recovery point, canonical JSON hash (I-09, I-10); encrypted backup is a v0.2 design item |
| Attachments | none in v0.1; stored apart from the database when they arrive (`docs/DATA_GOVERNANCE.md`) |
| Concurrency | a single app process uses the database; concurrent read/write is a spike criterion (SP-05); module tables are private to their module (MG-05) |
| Browser quotas and eviction | not applicable: web is a demo with no user data |
| Export versioning | `format_version` of the backup file and `schema_version` are independent (`docs/RELEASE_AND_VERSIONING.md` §1) |
| Future sync metadata | IDs, `updated_at` and soft-delete `deleted_at` exist; version vectors and tombstone propagation are deferred (ADR-0005/0006) |
