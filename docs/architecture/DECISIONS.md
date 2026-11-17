# Architecture Decisions Register (v2)

Single index of decisions and their status. Details live in ADRs (`docs/architecture/ADR/`). A decision is `PROPOSED` until an ADR with evidence, alternatives, consequences, owner and approval exists; owner decisions below are `OWNER-DECIDED` (2026-10-25) and get formal ADR acceptance later. Supersede accepted decisions with a new ADR; never rewrite history. The owner's answers to escalations are appended in the log at the bottom.

| Topic | Current position | Status | Reference / evidence needed |
|---|---|---|---|
| License | Apache-2.0 | ACCEPTED | ADR-0007 |
| Agent workflow | Lead sole contact, hats one at a time, Advisor at gates, git as bus | ACCEPTED (auto wake-up verified 2026-10-26) | ADR-0008, `AUTONOMY_AND_ESCALATION.md`, Q-03 |
| Product behavior | Local-first, no sync in v0.x | ACCEPTED | ADR-0001, 0005, 0006 |
| Platforms | Build 4 OS from day 1; release Android/Windows/macOS first; iOS after paid Apple account; web = demo only | ACCEPTED (framework conditional on spike) | ADR-0009 |
| MVP scope | Finance core + QuickAdd + Home + simple budget + monthly report + SMS paste/share + backup | OWNER-DECIDED | `MVP_SCOPE.md` |
| MVP gate profile | Lighter gates, same safety guarantees | ACCEPTED | ADR-UI-009 |
| SMS entry UI | Header button, provenance row, uncertainty handling | PROPOSED (ADR to write) | ADR-UI-010, Q-14 |
| Money | `BigInt` minor units (IRR = rial), stored as decimal TEXT, shown as toman or rial | OWNER-DECIDED | `DATA_MODEL.md` |
| Dates | UTC instants, `yyyy-MM-dd` dates, Jalali display via central layer; Jalali arithmetic in-house behind the calendar port (no `shamsi_date` dependency) | OWNER-DECIDED (2026-11-16; ADR-UI-004 to be written by the Architect) | `DATA_MODEL.md`, `SPIKE_REPORT.md` §4 #3 |
| UI direction | Minimal + professional + personal; UI constitution is source of truth | ACCEPTED as spec; ADR-UI-001…008 PROPOSED | `docs/design/ui-spec/` |
| Spec errata | 12 known gaps in the UI constitution are registered with interim rules; only Product/Contracts edits the spec (AG-02) | OPEN | `docs/design/SPEC_ERRATA.md` |
| Theme / locale | Light/dark/system; Persian first, RTL | Direction agreed | tokens, font and calendar tests |
| Navigation | Destination catalog; bottom nav (Compact/Medium), sidebar/top bar (Expanded/Large) | Spec | spec §5 |
| Framework | Flutter (go after the M0 spike); state and routing: Riverpod + go_router | ACCEPTED (2026-11-16) | ADR-0002, ADR-0009, `SPIKE_REPORT.md` §4 #1, #4 |
| Local storage | drift + `package:sqlite3` hook, one writer connection; no database encryption in v0.1 (SQLite3MultipleCiphers evaluated in a later spike) | ACCEPTED (2026-11-16) | ADR-0003, `SPIKE_REPORT.md` §4 #2 |
| Module model | Core + optional modules via `ModuleRegistry`; MVP has only `budget` | PROPOSED | `MODULE_CONTRACT.md` |
| Capture (SMS/OCR/voice) | Deterministic parser first; one `CaptureDraft`; never auto-save | PROPOSED | `CAPTURE_PIPELINE.md` |
| AI | Provider-neutral, local/LAN only, propose-never-execute | PROPOSED | ADR-0004, `AI_TOOL_CONTRACT.md` |
| Local coding model (H200) | Not chosen; benchmark on our tasks | OPEN | Q-01, Q-02, `LOCAL_MODEL_SETUP.md` (H3) |
| OCR | PaddleOCR vs Tesseract fas | OPEN | benchmark on synthetic receipts |
| Speech | whisper.cpp candidate | OPEN | latency, license, packaging |
| Notifications | Platform adapter | OPEN | with `tasks` module |
| Distribution | GitHub Releases + Pages landing; unsigned builds with honest notes | PROPOSED | `DISTRIBUTION_PLAN.md`, Q-07 |
| Repo visibility | Public (owner made it public on 2026-10-26) | OWNER-DECIDED | Q-04 (closed) |
| Product name | **Rewi** (Persian: «رِوی», kasra under ر; owner-confirmed 2026-10-31). Repository and code identifiers keep `BlueHesab-Mini` / `bluehesab_mini` until a rename task | OWNER-DECIDED (2026-10-31) | chat; rename task to be planned |
| Visual identity v2 | Geometric silhouette fox mascot «Rewi» (7 poses), fox-in-sun logo, four themes from the owner's reference photos (Ivory, Plum, Clay, Glow), Alexandria for Persian headings, Vazirmatn for all digits and body, Archivo Expanded / SF / Inter for Latin | ACCEPTED (ADR-UI-011, 2026-11-01); tokens via T-012, engine via T-013 | `design/brand/`, ADR-UI-011 |
| Third-party code | No reuse before audit; GPL/AGPL reference-only | POLICY | `OPEN_SOURCE_AUDIT.md` (H1) |
| Telemetry | None | POLICY | `PRIVACY.md` |

## Owner decision log
| Date | Decision | Source |
|---|---|---|
| 2026-10-25 | Apache-2.0; repo `BlueHubbot/BlueHesab-Mini`; local path `~/Documents/GitHub/BlueHesab-Mini` | chat |
| 2026-10-25 | No paid Apple account for now; 4 OS built from day 1; first release Android/Windows/macOS; web demo only | chat |
| 2026-10-25 | MVP profile with lighter gates; SMS paste/share inside MVP; agents one at a time; BigInt TEXT money | chat |
| 2026-10-26 | Doc groups produced in order: S0+Medium-A, Extra, Medium-B | chat |
| 2026-10-26 | Doc groups High and Max (final consistency audit) produced on the owner's command | chat |
| 2026-10-26 | Q-04: repository is public (owner switched it before merge of the docs pack) | chat |
| 2026-10-26 | Q-12: spend cap = Claude Pro plan plus at most USD 15 extra usage per month (owner set the limit in claude.ai settings); Advisor scheduled runs: 2 per day (3 allowed); default effort `high`, `xhigh`/`max` only when a task packet says so | chat |
| 2026-10-26 | No external AI API provider for now: Lead, Advisor and builders run as Claude sessions on the owner's subscription; H200 stays optional (L2) | chat |
| 2026-10-26 | Q-15: ADR-0009 and ADR-UI-009 accepted, with ADR-0001/0005/0006 in one batch (Lead's recommendation) | chat |
| 2026-10-26 | Merging is delegated to the Lead/Integrator when the owner is away: merge only with CI green, mergeable, docs-only or reviewed per autonomy level, and a recorded check; independent review of PR #1 waived by the owner (docs pack already audited in DOCS-X1) | chat |
| 2026-10-31 | Style Guide web demo (tokens slice) may be published on GitHub Pages as a development page (not a release); T-010 written by the Lead, to run after the open PRs #12–#14 | chat |
| 2026-10-31 | Product name changed to **Rewi** (was BlueHesab / آبی‌حساب). Visual identity v2 proposed on the design canvas; the first token palette (Tailwind-like blue/slate) is rejected; T-010 stays on hold until the owner picks the theme(s) | chat |
| 2026-10-31 | Persian spelling of the name: «رِوی» (with kasra under ر) | chat |
| 2026-11-01 | Themes: all four (Ivory, Plum, Clay, Glow) ship and the user picks; an automatic mode switches by time of day; a custom theme can be built from our curated palette or freely, guarded by contrast checks (ADR-UI-011, accepted) | chat |
| 2026-11-16 | ESC-002 / ADVISOR_REPLY-002 Action 4: the 28 PROPOSED status/module colours (4 themes × success, warning, danger, info, accent-health, accent-tasks, accent-car) in the v3 candidate table on PR #21 (branch `agent/contracts-T-012-tokens-v2`) are approved as proposed | chat |
| 2026-11-16 | SPIKE_REPORT §4: #1 Flutter go (ADR-0002 accepted); #2 drift + hook, one writer connection, no encryption in v0.1 (ADR-0003 accepted); #3 in-house Jalali arithmetic behind the port (ADR-UI-004 to be drafted); #4 Riverpod + go_router accepted (M5 noted in the audit rows); #6 Windows: zip for development builds, installer decided before GTX-06 | chat |
| 2026-11-16 | SPIKE_REPORT §4 #5 (reference phone, Q-09): open, the owner names the phone later; SP-07 (real phone), SP-08 and the cold-start number wait | chat |
| 2026-11-16 | Font (ESC-001, ADR-UI-003): run the SP-03 Vazirmatn evaluation first (ADVISOR_REPLY-001 Decision A), then the Architect drafts ADR-UI-003 for acceptance | chat |
