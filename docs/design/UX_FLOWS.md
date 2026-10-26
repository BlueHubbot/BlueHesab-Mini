# Core UX Flows (v2)

**Status:** v2 (2026-10-26) replaces the pack's v1 (which assumed sync and OCR in the first release). Flows A–F are in v0.1; G–H are later and are listed so that nothing built earlier blocks them. Exact UI rules: spec sections 5–8; capture details: `docs/architecture/CAPTURE_PIPELINE.md`; backup details: `docs/BACKUP_RESTORE.md`.

## A — Record an expense (the 3-second flow)
Tap QuickAdd → type the amount (defaults for account, category and date come from `GetQuickAddDefaults`, SD-01…06) → tap «ثبت». The use case commits locally, then the Toast confirms with «واگرد». No intermediate dialog (QE-01, QE-03). If the user has no account, the account chip says «ساخت حساب» and the primary button stays disabled until one exists (SD-05). A failed save keeps what the user typed and shows the reason (QX-16, IDP-04); a second tap never duplicates (IDP-01…05).

## B — Record from a bank SMS (paste or share)
Tap the header icon «چسباندن پیامک» (or share the text from the messages app on Android) → the app parses it on the device with deterministic rules → QuickAdd opens with the chips filled and a small «از پیامک» row. Anything uncertain (amount or kind) is left empty and marked, never guessed. The user reviews and taps «ثبت»; nothing is saved before that tap (CAPT-001). Not a financial message, unknown format or too-long text show an inline message and a manual path (CPX-02…05). The original text is never stored. Needs ADR-UI-010 before the M2 task.

## C — Change language, theme, digits or unit
Settings → Appearance → choose theme, digit mode, display unit (toman or rial), calendar, week start. Strings, direction and formatters update immediately; stored values do not change (I-02). English texts arrive in v0.3; until then the language row does not exist.

## D — Backup and restore
Backup: Settings → Backup → «ساخت پشتیبان» → the app explains that the file is not encrypted → writes the file through the system dialog → shows counts, size and checksum prefix. Restore: pick a file → the app validates structure, checksum and version → shows a preview of what will be replaced → asks for confirmation → makes a recovery point → replaces → reports the result. A bad file changes nothing (I-10, CORE-004).

## E — First run
At most three pages: welcome and privacy, unit and theme, create the first account (can be skipped; QuickAdd will ask again at the first save). No account sign-up, no permission requests.

## F — Budget
Budget is on by default. On the Budget page set a monthly limit overall or per category; Home then shows the budget arc and progress. Settings → Modules turns the module off or on: off hides everything it contributed and keeps its data (DM-01, DM-03, I-11).

## G — AI-assisted entry (v0.4, not built in v0.1)
Free text or voice → the assistant proposes a structured draft with provenance → the user edits and confirms → normal domain validation and commit. Execution location (on-device, LAN) is always visible; nothing is saved without confirmation (AT-P1…P8, AI-01).

## H — Receipt OCR (v0.4 or later, not built in v0.1)
Pick or capture an image → candidate fields with confidence → user review → explicit confirmation. Image retention follows the user's setting. Requires the benchmark on synthetic Persian receipts first (`docs/architecture/AI_TOOL_CONTRACT.md`).
