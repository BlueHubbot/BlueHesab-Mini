// T-002 spike: writing and reading money through drift (SP-02 write → read,
// DD-02, DD-04). Values are bound as strings, so SQLite keeps TEXT; the
// read path checks `typeof()` to prove it.

import 'package:drift/drift.dart';

import 'money.dart';
import 'spike_database.dart';

/// Minimal row access for the spike tests (not a product repository).
extension MoneyStore on SpikeDatabase {
  /// Inserts an account with its opening balance (DD-02 allows a sign here).
  Future<void> insertAccount({
    required String id,
    required String name,
    required String nameNorm,
    required String kind,
    required Money openingBalance,
    required String now,
  }) {
    return customStatement(
      'INSERT INTO accounts (id, name, name_norm, kind, currency, '
      'opening_balance_minor, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        id,
        name,
        nameNorm,
        kind,
        openingBalance.currency.code,
        openingBalance.toStorage(),
        now,
        now,
      ],
    );
  }

  /// Inserts a transaction; its currency must equal the account's (DD-04).
  Future<void> insertTransaction({
    required String id,
    required String kind,
    required Money amount,
    required String accountId,
    String? toAccountId,
    required String occurredOn,
    String? note,
    required String now,
  }) async {
    final row = await customSelect(
      'SELECT currency FROM accounts WHERE id = ?',
      variables: [Variable.withString(accountId)],
    ).getSingle();
    if (row.read<String>('currency') != amount.currency.code) {
      throw ArgumentError('DD-04: transaction currency differs from account');
    }
    await customStatement(
      'INSERT INTO transactions (id, kind, amount_minor, currency, account_id, '
      'to_account_id, occurred_on, note, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        id,
        kind,
        amount.toStorage(),
        amount.currency.code,
        accountId,
        toAccountId,
        occurredOn,
        note,
        now,
        now,
      ],
    );
  }

  /// Reads a transaction amount; fails unless SQLite stored TEXT (DD-02).
  Future<Money> readAmount(String transactionId) async {
    final row = await customSelect(
      'SELECT amount_minor, typeof(amount_minor) AS storage, currency '
      'FROM transactions WHERE id = ?',
      variables: [Variable.withString(transactionId)],
    ).getSingle();
    return _money(row.data, 'amount_minor');
  }

  /// Reads an account's opening balance; fails unless stored as TEXT.
  Future<Money> readOpeningBalance(String accountId) async {
    final row = await customSelect(
      'SELECT opening_balance_minor, typeof(opening_balance_minor) AS storage, '
      'currency FROM accounts WHERE id = ?',
      variables: [Variable.withString(accountId)],
    ).getSingle();
    return _money(row.data, 'opening_balance_minor');
  }
}

Money _money(Map<String, Object?> data, String column) {
  final storage = data['storage'];
  final value = data[column];
  final currency = data['currency'];
  if (storage != 'text' || value is! String || currency is! String) {
    throw StateError('$column is stored as $storage, expected text (DD-02)');
  }
  return Money.fromStorage(value, CurrencyCode.parse(currency));
}
