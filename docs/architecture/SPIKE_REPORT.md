# SPIKE_REPORT — M0 spike results (draft)

**Status:** DRAFT (2026-11-04) · **Owner:** Architect · **Approver:** product owner (D3) · **Plan:** `docs/architecture/SPIKE_PLAN.md` · **Task:** `docs/agents/tasks/T-017.md`
Every number below is quoted from the spike README or CI run cited in the same row; nothing is re-measured here (AG-05). This draft proposes, it decides nothing: ADR status, library choices and `KEEP` promotions wait for the owner.

## خلاصه‌ی فارسی
- از ۱۲ پرسش spike، **۸ مورد قبول** (SP-01، SP-02، SP-04، SP-05، SP-06، SP-09، SP-11، SP-12)، **۳ مورد نیمه** (SP-03: فونت روی لینوکس/مک/ویندوز قبول، golden با حروف فارسی واقعی و نگاه روی ۲ گوشی مانده؛ SP-07: روی شبیه‌ساز قبول، گوشی واقعی مانده؛ SP-10: DMG و zip بدون امضا قبول، نصب‌کننده‌ی ویندوز مانده) و **۱ مورد منتظر** (SP-08 نیازمند گوشی مرجع، Q-09). هیچ موردی شکست نخورد.
- شواهد برای ادامه با Flutter کافی است؛ پیشنهاد: ADR-0002 پذیرفته شود (تصمیم با صاحب محصول).
- تصمیم‌های آماده برای صاحب محصول در §4 آمده: چارچوب، پایگاه داده و رمزگذاری، کتابخانه‌ی تقویم شمسی، state و مسیریابی، حداقل نسخه‌ها و گوشی مرجع، قالب نصب‌کننده‌ی ویندوز.
- این پیش‌نویس پس از ادغام PR #24 (فونت) و اجرای گوشی واقعی نهایی می‌شود.

## 1. Results per question
Flutter 3.47.8 (Dart 3.13.7) pinned in every run. Result values: PASS (criterion met), PARTIAL (part met, rest named), PENDING (not yet run), FAIL.

| ID | Result | What was shown | Evidence |
|---|---|---|---|
| **SP-01** | PASS | CI builds APK, Windows, macOS, iOS simulator and web demo from a clean checkout: "CI با ۹ کار سبز" (T-001). Launch shown for Android (emulator cold start, T-009 P4), Windows and macOS (fresh runner, "both apps were still running after 15 s", T-009 P5), the iOS simulator (iOS 26.2 iPhone 17 Pro, "still running" after 15 s, T-021 L1) and the web demo in headless Chrome (`<flutter-view>` present, 0 console errors, T-021 L3); both T-021 checks have a negative control (L2, L4). | T-001 run [40407407136](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40407407136); `spike/T-009-platform/README.md` P4, P5; `spike/T-021-launch/README.md` L1–L4, run [42166935068](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/42166935068) |
| **SP-02** | PASS | 18-digit `BigInt` round trip exact: 999999999999999999 and 1 on Linux/macOS/Windows (`+32`), Android 15 emulator and iOS 26.2 simulator (`+2`), Chrome formatting/JSON/checksum (`+21`). A JSON number loses the 18-digit value in the browser; backups reject money that is not a string (finding 4, RKX-01). | `spike/money/README.md` "Results per OS", findings 1–9; run [40539889130](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40539889130) |
| **SP-03** | PARTIAL | Vazirmatn v33.003 on Linux, macOS and Windows (`flutter test` 11/11): coverage and weights PASS; Persian digits typed into a number field parse to the exact `BigInt`; an LTR number inside RTL text keeps its order; toy amount card at text scale 1.0 / 1.3 / 2.0 with no overflow (TY-05). Conditions: Persian digits are proportional by default and align only with `tnum`; the font line box (1.5625 × size) exceeds the token line of `title-sm`, `title`, `heading`, `display` while the ink fits every token. Not done: a golden with real Persian glyphs (T-011 G5) and the manual look on 2 devices (Q-09). | `spike/T-015-fonts/README.md`; PR #24 |
| **SP-04** | PASS | Jalali: every DT-05 vector passes for `shamsi_date` 1.0.2 and the in-house arithmetic; both agree on 81 814 days 1900-01-01…2123-12-31 on Linux/macOS/Windows/Chrome (F1, F2); both differ from ICU from 2124-03-20 (F3). Time zones: 330 offset changes and 504 samples equal the IANA 2026e reference in 7 zones (T1); Tehran +03:30 with no DST after 2022 (T2). | `spike/T-004-jalali/README.md` run [40745550988](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40745550988); `spike/T-007-timezone/README.md` run [41007730393](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/41007730393) |
| **SP-05** | PASS | drift without code generation: migration v1→v2 in one explicit transaction with `user_version` written inside it, failing step rolled back, recovery copy, older-schema backup restored through the same migrations (findings 1–3, 9, 15). Concurrency: WAL readers never block the writer (10); `busy_timeout` is not portable (Linux gives up after ~64 ms, finding 12). | `spike/money/README.md`; T-006 run [40932304041](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40932304041) |
| **SP-06** | PASS | Three fresh Linux runners produced the same 8 goldens byte for byte; compare mode on a fourth runner green; a sub-pixel change fails all 8 (G1, G2). macOS goldens are not interchangeable: 0 of 8 equal (G3). | `spike/T-011-goldens/README.md`, run 41228789660 |
| **SP-07** | PARTIAL | Emulator half: implicit `SEND text/plain` resolution, cold and warm share exact for ASCII, Persian and 4 000 characters, clipboard read only after the tap, no SMS permission, no plugin (S1–S6). Real phone not run (four items listed in that README). | `spike/T-014-share/README.md`; PR #23 |
| **SP-08** | PENDING | Needs the reference phone (Q-09). Not run. | — |
| **SP-09** | PASS | Universal release APK 42.68 MB (under the 50 MB soft flag), arm64-v8a 14.93 MB; Windows folder 25.46 MB, zip 10.89 MB; macOS `.app` 37.70 MB, DMG 17.10 MB (P1–P3). Android cold start on the emulator median 2484 ms, indicative only (P4). Desktop cold start not measured (P8). | `spike/T-009-platform/README.md`, run 41171705259 |
| **SP-10** | PARTIAL | Unsigned DMG and zip with `SHA256SUMS` installed and launched on fresh runners (P5); Gatekeeper `rejected` (ad-hoc signature, P6); Windows `NotSigned` (P7). Not done: a Windows installer (format undecided, needs an audit row). | `spike/T-009-platform/README.md` |
| **SP-11** | PASS | Every spike lockfile scanned with 0 failing: skeleton 24 packages (T-001), `spike/money` 42, Jalali 25, timezone 29, modules 38, goldens 24; T-014 `license scan` check-run green. | the READMEs above; T-001 AGENT_LOG line |
| **SP-12** | PASS | Riverpod 3.4.3 (plain `Provider`/`Notifier`, no codegen) and go_router 18.1.0: removing the budget module leaves `lib/core/` unchanged with analyzer clean and core tests green (MDC-T7, M1); module switched off live without a router rebuild (M3). `flutter_test` and `test_api` are runtime dependencies of Riverpod (M5). | `spike/T-008-modules/README.md` |

No row is FAIL, so SPIKE_PLAN "Failure handling" (reopen ADR-0002) is not triggered.

## 2. What the spikes found that the contracts did not say
1. Migrations need an explicit transaction and `user_version` inside it (money findings 1–2).
2. One writing connection for the whole app, or a Dart-side retry on `database is locked`; never SQLite's busy wait (money 11–13). Android is Linux-based and was not checked for the busy-wait behaviour (money 16).
3. drift's `transaction()` takes the write lock at its start; snapshot reads on a second connection use a manual `BEGIN DEFERRED` (money 11).
4. The SQLite binary comes from the `package:sqlite3` build hook, downloaded from GitHub with sha256 checks: builds need GitHub or a mirror (money 6).
5. `shamsi_date`'s own `addMonths` throws on 1405/06/31 + 1; month arithmetic must stay in the central port (Jalali F4). Supported range proposal 1279…1501 (F3).
6. The device's IANA zone name is not readable without a platform source (timezone T5); no rule ID decides the default. DST gap/overlap behaviour is recorded, not decided (T7).
7. Goldens only on the Linux CI image; a Mac `--update-goldens` would break CI (goldens G3).
8. Share intent needs about 50 lines of Kotlin and no plugin (share S6).
9. The on-device integration step is flaky on the CI emulator (share S8; ESC-004 answered (ADVISOR_REPLY-004), fix in follow-up task).

## 3. Disposition of spike code (`spike/README.md` rule 5)
Proposed; takes effect only when the owner accepts this report. `KEEP` means "may be moved, with its tests, by a promoting task"; nothing is promoted by this report.

| Folder | Proposal | Scope of the promoting task |
|---|---|---|
| `spike/money/` | KEEP | `Money`, formatter/parser, canonical JSON, backup format and restore, migration runner with recovery copy, older-backup upgrade → `lib/core/` (Builder-Domain, M1). Replace the hand-written SHA-256 with `package:crypto` (audit row from T-005; finding 8). |
| `spike/T-004-jalali/` | KEEP (port) | `JalaliCalendarPort`, `CentralCalendar`, `civil_date.dart` and the one implementation the owner picks (§4 item 3); the other is deleted. |
| `spike/T-007-timezone/` | KEEP | `ZoneLayer`, `instant_text.dart`; merge `civil_date.dart` with the Jalali one. Add a static check that `lib/` never imports `package:timezone/browser.dart` (T4). |
| `spike/T-008-modules/` | KEEP (if §4 item 4 accepts) | registry providers and router builder into the shell task (`lib/app/`), plus the import-lint test. |
| `spike/T-009-platform/` | KEEP (tools) | `tool/sizes.py`, `tool/cold_start.py` and the clean-install jobs → `tool/release/` and the release workflow (Builder-Platform, M3). |
| `spike/T-011-goldens/` | DELETE | Toy only; the harness shape is recorded in its README G4 for the first golden task. |
| `spike/T-014-share/` | KEEP | `MainActivity.kt`, `share_inbox.dart` and the prepare script, behind a share port, for the M2 capture task (after ADR-UI-010). |
| `spike/T-015-fonts/` | after PR #24 | — |

## 4. Decisions for the owner (D3; SPIKE_PLAN "Decisions the report must propose")
None is decided here. Each becomes an ADR update the owner accepts or rejects.

| # | Decision | Options and evidence | Architect's proposal |
|---|---|---|---|
| 1 | Framework go/no-go (ADR-0002) | Go: §1 has no FAIL; builds on all five targets, exact money, Jalali, SQLite, goldens and module registry proven. No-go would reopen ADR-0002. | Go with Flutter; accept ADR-0002. |
| 2 | DB binding and encryption (ADR-0003) | drift + `package:sqlite3` hook (proven, money 5–6). Encryption: (a) none in v0.1; (b) SQLite3MultipleCiphers via the same hook; (c) SQLCipher, which links OpenSSL on Android/Linux/Windows (money 7). Either (b) or (c) needs its own licence row. Concurrency: one writer connection. | drift + hook, one writer connection; encryption (a) for v0.1 with (b) evaluated in a later spike. |
| 3 | Jalali library (ADR-UI-004) | A `shamsi_date` 1.0.2 behind the port (dependency, 1.1.1 exists, re-audit needed, F7); B in-house arithmetic behind the same port (no dependency, needs the jalaali-js MIT notice if promoted). Both pass all vectors. | B, because it removes a dependency and the port keeps the choice reversible. |
| 4 | State and routing | Riverpod + go_router (SP-12 PASS). Open point: test-only packages in the runtime graph (M5). | Accept, with M5 recorded in the audit rows. |
| 5 | Minimum OS versions and reference device (Q-09) | No spike evidence; needs the owner's phone. Blocks SP-07 (real phone), SP-08 and the cold-start number. | Owner names one Android phone; minimum versions follow from it. |
| 6 | Windows installer (RV-2) | MSIX or Inno Setup, each needs an audit row (CB-9); today zip only. Signing for both desktop OSes is Q-07. | Zip for the first development builds; installer decided before GTX-06. |

Font (ADR-UI-003) joins this list after PR #24.

## 5. Open risks and pending items
| Item | Blocked by |
|---|---|
| Rest of SP-03: a golden with real Persian glyphs (T-011 G5), look on 2 real devices; font decision | ADR-UI-003 (owner); Q-09 |
| Real phone for SP-07 (system chooser, copy from another app, vendor skin, background task) | Q-09 |
| Performance (SP-08); reference cold start | Q-09 |
| Desktop cold start (needs a first-frame marker in `lib/`) | performance-hooks task |
| Windows installer; signing and notarisation | RV-2, Q-07 (owner) |
| Device time-zone source; DST gap/overlap rule | open question, before any feature needs local wall times |
| `busy_timeout` behaviour on Android | promoting storage task |
| CI emulator flake on the integration step | ESC-004 answered (ADVISOR_REPLY-004), fix in follow-up task |
| Build needs GitHub (SQLite binary, fonts) | mirror decision only if GitHub becomes unreachable for builds |
