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

## Findings
Filled in from the CI run.
