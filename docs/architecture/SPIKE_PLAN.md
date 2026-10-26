# SPIKE_PLAN — آزمون فنی قبل از قفل‌شدن چارچوب (M0)

**Status:** PLAN · **Owner:** Architect + Builder-Platform + Tester · **Date:** 2026-10-26 · supports ADR-0002, ADR-0003, ADR-0009, ADR-UI-004/005/006/007.
**Time box:** 5 working sessions of agent time (not calendar); stop and escalate (CB-2) if exceeded by 50 %. Output: `docs/architecture/SPIKE_REPORT.md` with evidence; no production code is kept except what the report marks `KEEP`. Spike code lives in `spike/` on a branch and is deleted or promoted by task.

## خلاصه‌ی فارسی
یک برنامه‌ی خیلی کوچک روی هر چهار سیستم‌عامل ساخته می‌شود تا ثابت شود Flutter، SQLite، RTL، شمسی و مبلغ ۱۸ رقمی کار می‌کنند. اگر شکست بخورد، قبل از ساخت ویژگی‌ها ADR-0002 دوباره باز می‌شود.

## Questions the spike must answer
| ID | Question | Pass criterion | Evidence |
|---|---|---|---|
| SP-01 | Does one Flutter project build and start on Android, Windows, macOS, iOS (simulator), and web demo in CI? | 5 artifacts built by CI; app launches on each (iOS sim, others real/VM) | CI links, screenshots |
| SP-02 | Money: 18-digit `BigInt` round trip UI→domain→SQLite TEXT→export JSON→import→format | exact on all targets incl. web demo (formatting only) | test log (I-01, RKX-01) |
| SP-03 | RTL/Persian: Vazirmatn rendering, Persian digits input in a number field, mixed LTR numbers in RTL text, text scale 2.0 without overflow | golden + overflow tests green; manual look on 2 devices | goldens, notes |
| SP-04 | Jalali: chosen library passes DT-05 vectors; month arithmetic and leap years; timezone handling | all vectors pass; failures documented | test log |
| SP-05 | SQLite via drift on all native targets: open, migrate v1→v2, transaction rollback, backup file copy, concurrent read/write | scripts pass per OS | test log |
| SP-06 | Golden stability: same goldens reproduce on fixed Linux CI image across 3 runs (GM-01) | 0 diffs | CI runs |
| SP-07 | Android share intent: text/plain from another app arrives in app; clipboard read on tap | works on 1 real phone | video/log |
| SP-08 | Performance on reference phone: 200-row list scroll and one motion panel build/raster p99 ≤ 16 ms | numbers recorded (PV-02/03) | profile report |
| SP-09 | Sizes and cold start: APK, Windows, macOS bundle size; cold start time | recorded; flag if APK > 50 MB (soft) | report |
| SP-10 | Packaging/signing: unsigned Windows installer and macOS DMG build in CI; checksums; install on clean VM | documented warnings and steps | notes |
| SP-11 | Dependency/licence scan of the spike lockfile | 0 copyleft; unknown = listed | scan output |
| SP-12 | State/routing candidates (Riverpod, go_router) compile-time ergonomics with the module registry (MDC-A3) | one module registered/unregistered without core change (MDC-T7) | test |

## Plan (sequential)
1. Project skeleton, CI matrix, license scan, `ui_check` stub (SP-01, SP-11).
2. Money + SQLite + migration + export (SP-02, SP-05).
3. RTL/font/digits/goldens (SP-03, SP-06).
4. Jalali + timezone (SP-04); module registry toy (SP-12).
5. Platform: share intent, packaging, perf, size (SP-07…10). Write the report.

## Decisions the report must propose (for owner acceptance)
Framework go/no-go; DB binding and encryption option (SQLCipher yes/no); Jalali library; state/routing choice; minimum OS versions and reference device (Q-09); installer format for Windows; known risks. Each as an ADR update (D3).

## Failure handling
If a criterion fails: record cause, try one documented mitigation, otherwise mark `FAIL` and escalate. Do not switch framework inside the spike without an ESC.
