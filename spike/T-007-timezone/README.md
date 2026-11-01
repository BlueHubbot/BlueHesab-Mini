# spike/T-007-timezone — central time-zone layer (SP-04, second half)

**Task:** `docs/agents/tasks/T-007.md` · **Answers:** SP-04 (timezone handling; the Jalali half is `spike/T-004-jalali/`) · **Rules:** DT-01, DT-02, DATA_MODEL §4 DT-A/DT-C, SD-06, T-07 · Evidence, not product (`spike/README.md`).

## What is here
- `lib/src/zone_layer.dart` — `ZoneLayer` over `package:timezone` 0.11.2 (BSD-2-Clause, audit row PROTOTYPE, T-005), embedded `latest` data. The only file that imports the package (checked by a test). Reads, offsets and "today" for an injected instant; it never reads the clock (SD-06).
- `lib/src/instant_text.dart` — DT-A stored instant text (`2026-10-24T06:55:00.000Z`), strict parse.
- `lib/src/civil_date.dart` — `CivilDate`, the `yyyy-MM-dd` stored day (DT-B).
- `tool/make_tz_fixture.py` → `test/fixtures/tz_reference.g.dart` — independent reference: Python `zoneinfo` over the system IANA database (version in the file), every offset change 2000…2035 and two samples per year for 7 zones. Dart source, so the comparison also runs in Chrome.

## Tests
| File | Runs on | Covers |
|---|---|---|
| `test/instant_text_test.dart` | VM + Chrome | DT-A format/parse, DT-B |
| `test/zone_vectors_test.dart` | VM + Chrome | DT-C "today" at Tehran midnight and across a New York DST change; Tehran +04:30 (2022) / +03:30 (2023+); unknown zone |
| `test/reference_test.dart` | VM + Chrome | DT-02 against the reference: each change at the same second, samples, no extra changes (daily scan) |
| `test/vm_evidence_test.dart` | VM | T-07 import closure without `package:http`; single import of `timezone`; version, data files and sizes; DST gap/overlap; device zone name |

CI: `.github/workflows/spike-timezone.yml`.

## Findings (SP-04, timezone half)
Evidence: CI run [41007730393](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/41007730393) on `3978932` (Flutter 3.47.8): `All tests passed!` with 23 tests on Linux (`00:00 +23`), Windows (`00:02 +23`) and macOS; Chrome job green on the three platform-neutral files; license scan 29 packages, 0 failing.

- **T1 · DT-02 agreement.** On 2000…2035 the package (embedded `latest` data) sees all 330 offset changes of the reference (Python `zoneinfo`, IANA 2026e) at the same second, agrees on all 504 yearly samples, and has no extra change in a daily scan, for `Asia/Tehran`, `Asia/Dubai`, `Asia/Kabul`, `Europe/Berlin`, `Europe/London`, `America/New_York`, `Australia/Sydney`. Same result on VM and Chrome.
- **T2 · Asia/Tehran.** +04:30 in July 2022, +03:30 from 2023 (the last DST period ended 2022-09-21 19:30 UTC). Precision for the audit row: "no DST after 2022", not "since 2022". Local midnight = 20:30 UTC.
- **T3 · Versions.** `timezone` 0.11.2 resolved (lockfile pinned); 345 zone names in `latest`. The package's embedded IANA release is older than the reference (2025c per the audit row vs 2026e): no difference in these zones and years. Refreshing tz data = a reviewed version bump, never a runtime fetch.
- **T4 · No network (T-07).** The import closure of the spike library is 12 files in 2 packages (`spike_timezone`, `timezone`) and only `dart:collection` and `dart:typed_data`; no `package:http`, no `dart:io`. In `timezone` only `lib/browser.dart` names `package:http` (the web loader of `.tzf` files); the embedded-data path never reaches it. `http` is still in the lockfile as a runtime dependency of `timezone`: the product needs a static check that `lib/` never imports `package:timezone/browser.dart` (input for SECURITY_PRIVACY_MODEL T-07).
- **T5 · Device zone.** `DateTime.now().timeZoneName` is `UTC` on Linux and `Coordinated Universal Time` on Windows: an abbreviation or display name, not an IANA name. The default of `app.timezone` (DT-C "default device zone") needs a platform source (a plugin with its own audit row, or a per-platform channel); until then the product can fall back to `Asia/Tehran` only by an explicit decision. No rule ID decides this: open question.
- **T6 · Data size.** `latest.dart` 1 131 735 B, `latest_10y.dart` 293 565 B, `latest_all.dart` 1 937 436 B (source text; `.tzf` binaries 257 744 / 66 768 / 441 320 B). Compiled size is not measured here (SP-09). `latest_10y` would not cover old dates (backup imports, history) and was not cross-checked.
- **T7 · DST gap/overlap (recorded, no decision).** `TZDateTime(Europe/Berlin, 2026-03-29 02:30)` (does not exist) → `01:30Z` (= 03:30 CEST); `2026-10-25 02:30` (exists twice) → `01:30Z` (the later, standard-time reading; Python's default `fold=0` gives the earlier `00:30Z`); New York gap 02:30 → `07:30Z`. Same on every OS. Only matters for local wall times entered by the user (reminders later); transaction dates are date-only (DT-B).
- **T8 · Platforms.** No platform code; Android/iOS not run separately (T-002's device jobs cover the Dart VM there).

## Input for the date layer (proposal only)
Keep one `ZoneLayer` next to the Jalali port, the only importer of `package:timezone` and only of `timezone.dart` + `data/latest.dart`; callers pass the instant (SD-06). Store instants with `formatInstant` (DT-A). Decide the device-zone source (T5) and the gap/overlap rule (T7) before any feature needs them.
