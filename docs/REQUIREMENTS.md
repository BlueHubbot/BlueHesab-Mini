# Requirements Baseline (v2)

Statuses: `PROPOSED`, `APPROVED`, `IMPLEMENTED`, `VERIFIED`, `DEFERRED`. "Release" is the first version that must satisfy it (version numbers come from `docs/product/MODULE_ROADMAP.md`). `APPROVED` means the product owner decided it on 2026-10-25 (`docs/ops/STATUS.md`); everything else waits for scope acceptance (Q-15).

Traceability: the success criteria S-01…S-08 and features F01…F16 of `docs/product/MVP_SCOPE.md` map to the rows below; the UI rule IDs (e.g. `QE-03`) live in `docs/design/ui-spec/`; the invariants I-01…I-12 live in `docs/architecture/DATA_MODEL.md`. IDs are never reused.

| ID | Requirement | Priority | Release | Acceptance evidence | Status |
|---|---|---:|---|---|---|
| CORE-001 | Core supported records work offline | P0 | v0.1 | integration test with the network disabled (S-08) | PROPOSED |
| CORE-002 | Schema migrations are versioned, forward-only and tested from the previous fixture and from empty (MG-01…05) | P0 | v0.1 | migration upgrade tests | PROPOSED |
| CORE-003 | User can export supported personal data to a file | P0 | v0.1 | export/import round trip (I-09, S-04) | PROPOSED |
| CORE-004 | Restore validates the backup before replacement, creates a recovery point, and a corrupt or newer-version file changes nothing (I-10) | P0 | v0.1 | valid/corrupt/newer restore tests | PROPOSED |
| CORE-005 | Money is `BigInt` minor units stored as decimal TEXT; the 18-digit maximum survives write, read, format, export and import on every target (DD-01…05, I-01) | P0 | v0.1 | property tests and goldens on all targets (owner decision 2026-10-25) | APPROVED |
| CORE-006 | Saves are idempotent: the same `clientRequestId` yields at most one record, across restarts and after undo (I-05, IDP-01…05) | P0 | v0.1 | use-case tests, TQ rows | PROPOSED |
| CORE-007 | Turning a module off or on never loses data; the core works with every module off; modules that are not built leave no trace (I-11, MDC-T1…T3, DM-01) | P0 | v0.1 | module matrix MMX, import-lint, absent-module scan | PROPOSED |
| UI-001 | Light, dark and system theme | P0 | v0.1 | UI tests for each mode | PROPOSED |
| UI-002 | Persian RTL complete; English LTR layout tested from v0.1, English texts in v0.3 | P0 | v0.1 | screen-level localization suite, GMX-03 overflow tests | PROPOSED |
| UI-003 | Navigation by window class: bottom bar (Compact, Medium), sidebar and top bar (Expanded, Large) | P0 | v0.1 | responsive/golden tests (spec section 5) | PROPOSED |
| UI-004 | Loading, empty and error states for every built page | P0 | v0.1 | component/screen tests | PROPOSED |
| UI-005 | The UI constitution applies under the MVP profile; every gate report states the profile and manifest hash (ADR-UI-009) | P0 | v0.1 | VR-05 reports | PROPOSED |
| UI-006 | A practiced user records a simple expense in at most 3 interactions and 3 seconds (QE-03, UT-01…04) | P0 | v0.1 | automated QE-03 test and user timing test | PROPOSED |
| FIN-001 | Amount, currency and date semantics are preserved | P0 | v0.1 | domain invariant tests | PROPOSED |
| FIN-002 | Transfers are never counted as income or expense (I-03) | P0 | v0.1 | report invariant tests | PROPOSED |
| FIN-003 | Formatting never mutates stored values (I-02) | P0 | v0.1 | formatter tests | PROPOSED |
| FIN-004 | Budget is an optional module, on by default: monthly limits overall and per category, arc and progress bar, computed in the domain (DD-09) | P1 | v0.1 | module tests, MMX combinations | APPROVED |
| FIN-005 | Month comparison uses the same elapsed period for the current month (DD-11) | P2 | v0.1 | vector tests | PROPOSED |
| CAPT-001 | SMS, OCR and AI capture create a draft only: never saved without explicit confirmation; zero income/expense inversions; OTP and promotional messages rejected (`CAPTURE_PIPELINE.md`, S-05) | P0 | v0.1 | parser gate and spy-on-repository test | APPROVED |
| CAPT-002 | No SMS-reading permission; raw message text is never stored; only hashes and last-4 hints (I-12) | P0 | v0.1 | permission manifest check, log scrubber test | APPROVED |
| AI-001 | AI financial proposals require human review (AT-P1…P8) | P0 | v0.4 (the draft rule already holds from v0.1) | interaction/policy tests | PROPOSED |
| AI-002 | Local and cloud AI use provider-neutral adapters (ADR-0004, `AI_TOOL_CONTRACT.md`) | P1 | v0.4 | adapter contract tests | DEFERRED |
| PRIV-001 | Any network use is disclosed, optional and off by default | P0 | v0.1 | consent/privacy tests (v0.1 makes no requests) | PROPOSED |
| PRIV-002 | Secrets are not committed | P0 | v0.1 | secret scanning | PROPOSED |
| PRIV-003 | No telemetry and no account; v0.1 makes no network requests (S-08) | P0 | v0.1 | static check that network packages are absent, test with the network blocked | APPROVED |
| PRIV-004 | Backup files are unencrypted in v0.1 and the UI says so; no encryption claim before design and tests | P1 | v0.1 | UI text check, `SECURITY_PRIVACY_MODEL.md` | PROPOSED |
| PLAT-001 | Android, Windows, macOS and iOS build in CI from M0; web is the demo only (ADR-0009) | P0 | v0.1 | CI matrix, spike report | APPROVED |
| PLAT-002 | v0.1 distribution through free channels: GitHub Releases for APK, Windows installer and macOS DMG, with honest notes about unsigned builds (`DISTRIBUTION_PLAN.md`) | P0 | v0.1 | release checklist (`RELEASE_AND_VERSIONING.md` §3) | APPROVED |
| MOD-001 | Modules declare capabilities and navigation metadata through the registry (`MODULE_CONTRACT.md`) | P1 | v0.1 | registry tests (MDC-A1…A7) | PROPOSED |
| SYNC-001 | Conflict behavior is specified before any sync ships | P1 | later | conflict contract tests | DEFERRED |
| NOTIF-001 | Reminder limits are documented per platform | P1 | v0.2 (with `tasks`) | platform test matrix | DEFERRED |
