# spike/T-004-jalali — central Jalali calendar port (SP-04)

**Task:** `docs/agents/tasks/T-004.md` · **Answers:** SP-04 (Jalali half; timezones are a follow-up) · **Rules:** DT-01, DT-02, DT-03, DT-05, ADR-UI-004, ADRX-04 · Evidence, not product (`spike/README.md`).

## What is here
- `lib/src/calendar_port.dart` — `JalaliCalendarPort` (conversion, leap year, month length, weekday from Saturday) and `CentralCalendar` (rules written once on top of any port: month addition clamped to the last day, validity).
- `lib/src/shamsi_date_adapter.dart` — the port over `shamsi_date` 1.0.2 (BSD-3-Clause, audit row PROTOTYPE). The only file that imports the package (DT-05; checked by a test).
- `lib/src/reference_calendar.dart` — in-house integer arithmetic (Borkowski's break-year method), the ADRX-04 fallback.
- `lib/src/civil_date.dart` — `GregorianDate` (stored form `yyyy-MM-dd`, DT-01) and `JalaliDate` (display only).
- `tool/make_icu_fixture.js` → `test/fixtures/icu_nowruz.csv` — Nowruz and year length of Jalali years 1279…1502 from ICU's Persian calendar (generated with ICU 78.3 / Node 22; the version is in the file header).

## Tests
| File | Runs on | Covers |
|---|---|---|
| `test/dt05_vectors_test.dart` | VM + Chrome | every DT-05 vector, both implementations (AC1) |
| `test/cross_check_test.dart` | VM + Chrome | 81 814 days 1900-01-01…2123-12-31 equal, round trip, weekday; leap years 1279…1502; DT-01 parse/format (AC2, AC4) |
| `test/vm_evidence_test.dart` | VM | ICU fixture (AC3); single import of `shamsi_date` (AC4); evidence line for CI |

CI: `.github/workflows/spike-jalali.yml` (analyze + license scan, test on ubuntu/macos/windows, Chrome).

## Findings (SP-04)
- **F1 · DT-05 vectors.** All pass for both implementations on Linux, macOS, Windows and Chrome (results below).
- **F2 · Agreement.** `shamsi_date` and the in-house arithmetic agree on all 81 814 days of 1900-01-01…2123-12-31 (date, round trip, weekday), on leap years 1279…1502, and both equal the ICU fixture (Nowruz of 224 years; year length except 1502, see F3).
- **F3 · ICU vs. 33-year arithmetic.** Checked before the spike with Node's ICU over 1900-01-01…2124-12-31: Borkowski's method equals ICU on every day up to 2124-03-19; from 2124-03-20 they differ by one day, because ICU gives Jalali 1502 365 days and the arithmetic gives it 366. CI shows `shamsi_date` behaves like the arithmetic here too (2124-03-20 = 1502/12/30 in both), so both differ from ICU from that day. Far outside any v0.1 need; recorded so the central layer documents its supported range (proposal: 1279…1501, i.e. Gregorian 1900…2123).
- **F4 · Month addition.** The spec rule (clamp to the last day) lives in `CentralCalendar.addMonths`, not in the library; the library's own `addMonths` on 1405/06/31 + 1 **throws** (`DateException`), so callers must never use it directly; the port keeps the clamp in one place.
- **F5 · Platforms.** Pure integer arithmetic with every intermediate below 2^32, so the same code is exact on the VM and on the web; Android/iOS were not run separately (no platform code; the T-002 device jobs already prove the Dart VM on both).
- **F6 · Not covered.** Instants and time zones (DT-02): needs a tz-database package with an audit row (candidates to audit: `timezone`); display formatting and month/day names (copy catalog, later task).

## Input for ADR-UI-004 (proposal only; the owner decides, D3)
Option A: `shamsi_date` behind the port. Option B: the in-house reference behind the same port (no dependency; needs the jalaali-js MIT notice in `third_party/licenses/` if promoted, because its structure follows that implementation). Either way the app imports only the port; the choice can change without touching callers.

- **F7 · Version.** `pub get` reports `shamsi_date` 1.1.1 available; the audit row covers 1.0.2, so the spike pins 1.0.2. Re-audit before promotion if a newer version is wanted.

## Results per OS
CI run [40745550988](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40745550988) on `ab7380b` (Flutter 3.47.8, Dart 3.13.7):

| Job | Result | Evidence line |
|---|---|---|
| analyze + license scan | `No issues found!` · 25 packages, 0 failing | — |
| test ubuntu-24.04 | `00:00 +35: All tests passed!` | `os=linux days=81814 problems=0 icu_years=224` |
| test macos-15 | `00:01 +35: All tests passed!` | `os=macos days=81814 problems=0 icu_years=224` |
| test windows-2025 | `00:01 +35: All tests passed!` | `os=windows days=81814 problems=0 icu_years=224` |
| test web (Chrome) | `00:02 +31: All tests passed!` | VM-only file not run (dart:io) |

All three VM lines also say `shamsi_addMonths(1405/06/31,+1)=throws _DateExceptionImpl` and `2124-03-20=1502/12/30/1502/12/30` (library/in-house).
