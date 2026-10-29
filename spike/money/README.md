# spike/money — T-002: money, SQLite, migration, export round trip

**Task:** `docs/agents/tasks/T-002.md`, `docs/agents/tasks/T-006.md` · **Answers:** SP-02, SP-05 (`docs/architecture/SPIKE_PLAN.md`) · **Owner:** Builder-Domain · **Status:** evidence, not product (`spike/README.md`).

## What is here
| File | Purpose | Rule IDs |
|---|---|---|
| `lib/src/money.dart` | `Money` = `BigInt` minor units + currency; canonical TEXT form, 18-digit limit | DD-01…DD-04, I-01, NM-06 |
| `lib/src/money_format.dart` | the number island formatter and input parser (Persian/Latin digits, toman/rial) | MN-02, MN-03, NM-01…NM-05 |
| `lib/src/canonical_json.dart`, `lib/src/sha256.dart` | canonical JSON (sorted keys, no whitespace) and the backup checksum | DD-02, I-09 |
| `lib/src/backup_format.dart` | backup document: build and validate before any write | I-09, I-10, RKX-01 |
| `lib/src/schema.dart`, `lib/src/spike_database.dart` | schema v1 → v2 through drift without code generation | MG-01, MG-03, MG-04, ADR-0003 |
| `lib/src/recovery.dart` | recovery copy before a migration, keep the last 3 | MG-02 |
| `lib/src/money_store.dart`, `lib/src/backup_io.dart` | write/read money rows; export and restore in one transaction | DD-02, I-10 |
| `test/` | all checks; `test/core_test.dart` also runs in Chrome | |
| `lib/src/backup_upgrade.dart` | T-006: restore of an older-schema backup through a staging database migrated by the same MG-01 steps | BACKUP_RESTORE §4 steps 2, 6, 7; I-10 |
| `test/older_backup_test.dart`, `test/concurrency_test.dart` | T-006: v1 backup → v2 database; two connections on one file (WAL) | SP-05, ADR-0003 |
| `test/fixtures/schema_v1_fixture.sql` | frozen v1 database, made by `tool/make_fixture.py` (synthetic data) | MG-04 |

The schema is a subset of `docs/architecture/DATA_MODEL.md` §5 (currencies, accounts, transactions; v2 adds `transactions.external_ref`, its index and `idempotency`). The money `CHECK` constraints are copied verbatim. The backup carries only `accounts` and `transactions`.

## Run
```
cd spike/money
flutter pub get --enforce-lockfile
flutter analyze
flutter test                                       # VM: real SQLite through drift
flutter test --platform chrome test/core_test.dart # web: formatting, JSON, checksum only
```
CI: `.github/workflows/spike-money.yml` (Linux, macOS, Windows, Chrome; analyzer; no-float check; license scan of this lockfile).

## Results per OS
Flutter 3.47.8 (Dart 3.13.7), drift 2.35.3, sqlite3 3.8.0. Each line is the job's own annotation in CI run [40539889130](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40539889130).

| Target | Runner | SQLite | Result |
|---|---|---|---|
| Linux (VM tests) | ubuntu-24.04 | 3.54.1 | `00:01 +32: All tests passed!` |
| macOS (VM tests) | macos-15 (15.7.9) | 3.54.1 | `00:04 +32: All tests passed!` |
| Windows (VM tests) | windows-2025 (Server 2025, build 26100) | 3.54.1 | `00:06 +32: All tests passed!` |
| Web demo, Chrome (`test/core_test.dart`, formatting/JSON/checksum only) | ubuntu-24.04 | n/a | `00:01 +21: All tests passed!` |
| Analyzer, no-float check | ubuntu-24.04 | | `No issues found!` · `2 tests passed` |
| License scan of `pubspec.lock` | ubuntu-24.04 | | `42 packages · 0 failing` (drift MIT, sqlite3 MIT, the rest BSD-3-Clause/Apache-2.0/SDK) |
| Android emulator (integration test, real file) | ubuntu-24.04, API 35 / Android 15 x86_64, KVM | 3.54.1 | `00:01 +2: All tests passed!` |
| iOS simulator (integration test, real file) | macos-15, iOS 26.2 | 3.54.1 | `00:19 +2: All tests passed!` |

The device test (`device_app/integration_test/money_device_test.dart`) repeats the round trip and the v1 -> v2 / failing-step rollback / recovery-copy checks; the frozen-fixture comparison runs on the three desktop OSes. The same SQLite 3.54.1 comes from the `sqlite3` build hook on all five native targets.

## Findings for SPIKE_REPORT (SP-02, SP-05)
1. **drift does not run migrations in a transaction by itself** (drift docs, migrations / step by step / Transactions). MG-01 therefore needs an explicit `transaction()` around all pending steps; the spike does that and tests a failing step (whole upgrade rolled back, next open upgrades again).
2. **Write `PRAGMA user_version` inside that transaction.** drift writes the version only after the migration callback returns; if the app dies between the commit and that write, the next open would run the step again on a migrated schema. Writing it inside the transaction closes the gap.
3. **`schema_migrations` with a checksum per step** catches an edited released step on the next open (test "a changed released step is detected on open").
4. **TEXT affinity protects storage.** A value bound as an integer by mistake is stored as text by a `TEXT` column, and the `GLOB`/`length` checks of DD-02 still apply. The real risk is in transport (RKX-01): the web test shows that a JSON number loses the 18-digit value in the browser, while a string never does. Backups reject money that is not a string.
5. **No code generation needed for the spike.** drift's `customStatement`/`customSelect` and a hand-written `GeneratedDatabase` are enough; build_runner/drift_dev (and their dependency tree) can wait for the product decision in ADR-0003.
6. **The SQLite library comes from a build hook.** `package:sqlite3` 3.x (a transitive dependency of drift) downloads prebuilt SQLite from its GitHub release at build time and checks it against sha256 values shipped in the package. Builds therefore need network access to GitHub or a mirror (`url_pattern` user define). For Security and License review: SQLite itself is public domain; record it in the audit with the binary source.
7. **Encryption is feasible without changing the code (report only).** The same hook can bundle SQLite3MultipleCiphers or SQLCipher instead (`hooks: user_defines: sqlite3: source: sqlite3mc` or `sqlcipher`). Both have their own licenses, and the SQLCipher build links OpenSSL on Android, Linux and Windows; this is the input for DQ-4 / ADR-0003, not a decision.
8. **SHA-256 is hand-written here on purpose.** `package:crypto` is a transitive dependency already, but using it directly needs its own audit row (CB-9), which T-002 cannot add (docs are a forbidden path). The spike implementation is checked against the FIPS 180-4 vectors and an independent Python result; for promotion, replace it with `package:crypto` once the row exists.
9. **The recovery copy reads `user_version` from the file header** (offset 60) without opening a connection, and refuses to copy when a `-wal` or `-journal` file is left over.

## T-006 findings (SP-05 remainder: concurrency, older-schema restore)
Evidence: CI run [40932304041](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40932304041) (commit `dc28d65`), `All tests passed` with 42 tests on Linux (`00:03 +42`), Windows (`00:11 +42`) and macOS. Two connections = two drift background isolates (`NativeDatabase.createInBackground`) on one file, `journal_mode = WAL`, `busy_timeout = 5000` (read back as 5000 on every OS).

| Observation | Linux | macOS | Windows |
|---|---|---|---|
| Write on A while B holds a manual `BEGIN DEFERRED` read | ok (2 ms) | ok (36 ms) | ok (57 ms) |
| B's snapshot inside that read after A commits | unchanged (stable) | unchanged | unchanged |
| Write on A while B is inside a drift `transaction()` that only read | `database is locked` after 75 ms | after 6.8 s | after 5.1 s |
| Write on A while B holds `BEGIN IMMEDIATE` | locked after 64 ms | after 7.2 s | after 5.0 s |
| Second writer with a Dart-side retry (25 ms steps) after A commits at +300 ms | done at 303 ms, 3 retries | done at 346 ms, 0 retries | done at 344 ms, 0 retries |
| Read-then-write after the other connection committed | `database is locked` (SQLITE_BUSY_SNAPSHOT), rolled back | same | same |

10. **Readers never block the writer in WAL, and a deferred read is a true snapshot.** An export can therefore read on its own connection inside `BEGIN DEFERRED … COMMIT` while the app keeps writing (BACKUP_RESTORE §3 step 2 "single read transaction").
11. **drift's `transaction()` takes the write lock at its start** (behaves like `BEGIN IMMEDIATE` in these runs), even when the block only reads. A read-only drift transaction on one connection blocks every writer on the others. Snapshot reads on a second connection must use a manual `BEGIN DEFERRED`, not `transaction()`.
12. **`busy_timeout` is not portable here.** macOS and Windows wait the full timeout; on Linux the same build gives up after ~64 ms although `PRAGMA busy_timeout` reads 5000. Cause not established (the Dart VM's signals interrupting SQLite's sleep is a guess, not evidence). The product must not rely on SQLite's busy wait: either one writing connection for the whole app (recommended input for ADR-0003, matching its "single app process" row) or a Dart-side retry on `database is locked`.
13. **A read transaction that later writes fails after another commit, with any timeout** (SQLITE_BUSY_SNAPSHOT). Write transactions must take the write lock first (drift's default already does, finding 11) or run on the single writer.
14. **WAL and MG-02 fit together.** While a WAL connection is open the `-wal` file exists and the header `user_version` can be stale, so `copyForRecovery` refuses; after the last connection closes no `-wal`/`-shm` is left and the copy (still in WAL mode) opens with all rows. The recovery copy must stay before the first open, as it is now.
15. **Older backups restore through the migrations, not a second upgrader.** A v1 file (written by the v1 code from the frozen fixture: `schema_version` 1, no `external_ref`) is validated against the v1 field set, written into a staging database built by migration step 1, upgraded by the same MG-01 code (`user_version` 2, history [1, 2]), checked (`integrity_check`, `foreign_key_check`), and copied into the target in one transaction (`ATTACH`). 999999999999999999, 1, −999999999999999999 and the name with ZWNJ stay exact; re-export is a valid v2 file with the same data plus `external_ref: null`. Non-empty target, a v1 file carrying a v2 field, a newer file (MG-03) and duplicate ids all leave the target unchanged and no staging file behind (I-10). Replace (clear + insert) and the recovery point of BACKUP_RESTORE §4 steps 3–5 stay product work.
16. Android/iOS were not re-run for T-006: the code path is the same drift/SQLite 3.54.1 as T-002's device runs; the Linux-only busy-wait finding is a reason to check Android (also Linux-based) in the promoting task.

## Open questions
- Display of the minor digits for non-IRR currencies (always two digits, or trim zeros?) has no rule ID; the spike shows all `minorDigits` and does not decide.
- SE-08 (overflow message or silence) is unchanged: the parser throws `RangeError` above 18 digits and leaves the UI reaction open.
- Android and iOS ran on an emulator and a simulator, not on physical devices.
- The device harness lockfile (`device_app/pubspec.lock`) is not license-scanned: `spike_money` is a path dependency without an audit row, and the harness adds only the SDK `integration_test` tree.

## Python reference for the checksum test
`test/core_test.dart` compares the checksum with a value computed independently in Python 3 on the same sample: `json.dumps(body, sort_keys=True, separators=(",", ":"), ensure_ascii=False)`, then `hashlib.sha256` of the UTF-8 bytes.
