# ADR-0001: Local-first product behavior
- **Status:** PROPOSED
- **Date:** 2026-10-23
- **Owner:** Lead architect
- **Approver:** Product owner

## Context
Core personal finance workflows should not require a permanent server connection; optional sync/cloud may come later.

## Options
1. Server-first core.
2. Local-first with optional cloud.
3. Peer-to-peer distributed architecture.

## Proposed decision
Choose local-first for supported core flows. Design sync separately before implementing it.

## Consequences
Offline workflows remain available; backup, device loss, encryption, migrations and future sync conflicts require explicit designs. Do not ship sync until deletion/conflict semantics are tested.

## Revisit triggers
Validated multi-user requirements or platform limitations make this approach unsuitable.

## Update 2026-10-26 (status stays PROPOSED until the owner accepts it)
- **Owner position (2026-10-25):** local-first, no account and no sync in v0.x. Recorded in `docs/architecture/DECISIONS.md` as OWNER-DECIDED; formal acceptance is one yes/no for the owner, batched with the other ADRs (Q-15).
- **Where the consequences are now specified:** the local database is authoritative (`docs/architecture/DATA_MODEL.md`); backup and restore (`docs/BACKUP_RESTORE.md`, invariants I-09, I-10); no network and no telemetry in v0.1 (`PRIVACY.md`); device loss is handled by backups the user keeps; a backup reminder is a candidate feature (R-010).
- **Network after v0.1:** only optional, listed, switchable-off requests in later modules (`markets` in v0.3), and local or LAN AI (ADR-0004).
