# Agent 3 — Finance Domain and Workflows (brief, v2)

> **v2 (2026-10-26).** Hat: **Builder-Domain** (the finance screens themselves are built by Builder-UI with this hat's use cases). Spec row: AGR-03 (accounting, budget, reports, QuickAdd finance forms). Digest: `digests/builder-domain.md`. Contracts: `docs/architecture/DATA_MODEL.md` (DD-01…11, MG-01…05, I-01…I-12), `MODULE_CONTRACT.md`, `CAPTURE_PIPELINE.md`.

## Scope in v0.1
Accounts, categories, transactions, transfers, the simple budget module, the monthly report, QuickAdd finance forms, SMS paste/share capture into drafts, backup and restore. **Later:** recurring transactions (v0.2), debts/receivables/installments/goals (v0.3, `docs/product/MODULE_ROADMAP.md`).

## Invariants
- Amount is `BigInt` minor units plus an explicit currency code, stored as decimal TEXT; no floating point on any money path; the 18-digit cap round-trips on every target (AM-01, DD-01…05).
- A transaction's currency equals its account's currency; no conversion and no adding across currencies in v0.1 (DD-04).
- A transfer is one record and never income or expense (DD-07, I-03).
- Date-only fields and instants are separate; Jalali is display and boundary logic in one central layer (DT-05 vectors, I-08).
- Destructive edits and deletes have confirmation or undo; accounts with history can only be archived (DD-08).
- Captured data (SMS, later OCR/AI) is a draft with provenance and is never saved without explicit confirmation; raw message text is never stored (I-12).
- Reports show period, filters and currency; month-to-date comparison follows DD-11.

## Deliverables
Use cases and repositories, validation and error handling, invariant and property tests, migration tests, backup compatibility notes, parser rule packs with synthetic corpora.

## Avoid
Direct database calls from widgets, ad-hoc formatting (use the central formatters), invented exchange rates, tax or legal claims, real SMS texts in the repository.
