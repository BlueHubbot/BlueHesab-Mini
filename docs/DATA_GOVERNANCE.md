# Data Governance (v2)

**Status:** v2 (2026-10-26). The data rules are made concrete in `docs/architecture/DATA_MODEL.md` (DD-01…11, MG-01…05, invariants I-01…I-12); this page states the policy they implement.

- **Identity and change:** stable client-generated IDs; explicit creation and update semantics; versioned forward-only migrations with a recovery copy first (MG-01…04). Locale and presentation never reach storage (I-02).
- **Money:** `BigInt` minor units plus an explicit currency code, stored as canonical decimal TEXT; sums only in the domain; no `double` anywhere on a money path; the 18-digit maximum is round-tripped in tests on every target (DD-01…05, I-01). A transaction's currency equals its account's currency; v0.1 has no conversion and never adds across currencies (DD-04). When conversion arrives (markets module), original and converted values stay separate and every rate carries source, time and direction (MN-06).
- **Transfers** are one record, never income or expense (DD-07, I-03).
- **Dates:** date-only fields (`yyyy-MM-dd`) are separate from instants (UTC ISO-8601); the Jalali calendar is a display and boundary rule handled by one central layer; timezone assumptions are recorded (`app.timezone`, DT-05 vectors, I-08).
- **Deletion:** soft delete with undo and a later purge; accounts with history can only be archived (DD-08).
- **Imported and captured content is untrusted:** SMS text, backup files and (later) OCR/AI output are parsed, validated and never executed. Captured data is a draft with provenance; only hashes and last-4 hints are kept, never raw message text (I-12, CAPTURE_PIPELINE).
- **Backup and restore:** validated before any change, with a recovery point (I-09, I-10, CORE-004).
- **Attachments:** none in v0.1. When they arrive, MIME and size are validated and the files are stored apart from the database.
- **Before any sync ships:** specify IDs, version metadata, tombstones, conflict rules, idempotency and account deletion (ADR-0005/0006).
- **Privacy defaults:** no telemetry, no account, no network in v0.1; every later outbound request is optional, off by default and listed in `PRIVACY.md`.
