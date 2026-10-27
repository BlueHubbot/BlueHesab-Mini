# spike/money — T-002: money, SQLite, migration, export round trip

**Task:** `docs/agents/tasks/T-002.md` · **Answers:** SP-02, SP-05 (`docs/architecture/SPIKE_PLAN.md`) · **Owner:** Builder-Domain · **Status:** evidence, not product (`spike/README.md`).

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
Filled from CI evidence when the run is green; see the PR for links.

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

## Open questions
- Display of the minor digits for non-IRR currencies (always two digits, or trim zeros?) has no rule ID; the spike shows all `minorDigits` and does not decide.
- SE-08 (overflow message or silence) is unchanged: the parser throws `RangeError` above 18 digits and leaves the UI reaction open.
- Android and iOS device runs are not part of this first CI step; they need an emulator/simulator job (integration test) in the next step of T-002.
- Concurrent read/write and restore of an older-schema backup (SP-05, BACKUP_RESTORE) are not covered yet.

## Python reference for the checksum test
`test/core_test.dart` compares the checksum with a value computed independently in Python 3 on the same sample: `json.dumps(body, sort_keys=True, separators=(",", ":"), ensure_ascii=False)`, then `hashlib.sha256` of the UTF-8 bytes.
