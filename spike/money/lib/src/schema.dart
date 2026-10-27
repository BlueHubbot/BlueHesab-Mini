// T-002 spike: schema v1 and v2 and their forward-only migrations
// (MG-01, MG-04, DD-02, DATA_MODEL §5).
//
// A spike subset of DATA_MODEL §5: currencies, accounts and transactions in
// v1; v2 adds `transactions.external_ref` with its index and the
// `idempotency` table (realistic ALTER TABLE + CREATE steps). Money columns
// keep the contract's CHECK constraints verbatim.
//
// test/fixtures/schema_v1_fixture.sql is a frozen copy of v1 made by
// tool/make_fixture.py; do not edit a released step, add a new version.

import 'sha256.dart';

/// One forward-only schema step (MG-01).
final class Migration {
  const Migration(this.version, this.statements);

  /// The `user_version` after this step.
  final int version;

  /// SQL statements, run in order inside the migration transaction.
  final List<String> statements;

  /// Recorded in `schema_migrations.checksum`; detects edited steps.
  String get checksum => sha256OfString(statements.join('\n;\n'));
}

/// The migrations of the spike app, version 1 first.
const List<Migration> schemaMigrations = [
  Migration(1, _v1),
  Migration(2, _v2),
];

const List<String> _v1 = [
  r'''CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL,
  checksum TEXT NOT NULL
)''',
  r'''CREATE TABLE currencies (
  code TEXT PRIMARY KEY,
  minor_digits INTEGER NOT NULL CHECK (minor_digits BETWEEN 0 AND 4)
)''',
  r'''INSERT INTO currencies (code, minor_digits) VALUES
  ('IRR', 0), ('USD', 2), ('EUR', 2), ('GBP', 2), ('AED', 2), ('TRY', 2)''',
  r'''CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_norm TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('cash','bank')),
  currency TEXT NOT NULL REFERENCES currencies(code),
  opening_balance_minor TEXT NOT NULL DEFAULT '0'
    CHECK (opening_balance_minor = '0'
        OR (opening_balance_minor GLOB '[1-9]*' AND opening_balance_minor NOT GLOB '*[^0-9]*' AND length(opening_balance_minor) <= 18)
        OR (opening_balance_minor GLOB '-[1-9]*' AND substr(opening_balance_minor, 2) NOT GLOB '*[^0-9]*' AND length(opening_balance_minor) <= 19)),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  deleted_at TEXT
)''',
  r'''CREATE UNIQUE INDEX ux_accounts_active_name
  ON accounts(name_norm) WHERE archived_at IS NULL AND deleted_at IS NULL''',
  r'''CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('expense','income','transfer')),
  amount_minor TEXT NOT NULL
    CHECK (amount_minor GLOB '[1-9]*' AND amount_minor NOT GLOB '*[^0-9]*' AND length(amount_minor) <= 18),
  currency TEXT NOT NULL REFERENCES currencies(code),
  account_id TEXT NOT NULL REFERENCES accounts(id),
  to_account_id TEXT REFERENCES accounts(id),
  occurred_on TEXT NOT NULL,
  note TEXT,
  origin TEXT NOT NULL DEFAULT 'manual' CHECK (origin IN ('manual','sms','import','assistant')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  CHECK ((kind = 'transfer') = (to_account_id IS NOT NULL)),
  CHECK (to_account_id IS NULL OR to_account_id <> account_id)
)''',
  r'''CREATE INDEX ix_tx_date ON transactions(occurred_on) WHERE deleted_at IS NULL''',
  r'''CREATE INDEX ix_tx_account_date ON transactions(account_id, occurred_on) WHERE deleted_at IS NULL''',
];

const List<String> _v2 = [
  r'''ALTER TABLE transactions ADD COLUMN external_ref TEXT''',
  r'''CREATE INDEX ix_tx_external_ref ON transactions(external_ref) WHERE external_ref IS NOT NULL''',
  r'''CREATE TABLE idempotency (
  client_request_id TEXT PRIMARY KEY,
  record_kind TEXT NOT NULL,
  record_id TEXT NOT NULL,
  created_at TEXT NOT NULL
)''',
];
