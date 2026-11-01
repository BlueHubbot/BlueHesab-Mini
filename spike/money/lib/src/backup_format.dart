// T-002 spike: the backup document, built and validated without touching a
// database (DATA_MODEL §10, BACKUP_RESTORE §1–§2, I-09, I-10, RKX-01).
//
// Spike subset: the entity arrays are `accounts` and `transactions` only.
// Validation runs completely before any write; a rejected file changes
// nothing (I-10). Money must arrive as canonical decimal strings: a JSON
// number in a money field is rejected even when its value would fit (DD-02).
// Pure Dart: runs on the VM and on the web.

import 'dart:convert';

import 'canonical_json.dart';
import 'money.dart';
import 'sha256.dart';

/// Identifies the file type (BACKUP_RESTORE §1).
const String backupFormat = 'bluehesab-backup';

/// Version of the file layout, independent of the schema version.
const int backupFormatVersion = 1;

/// Why a backup was rejected (each maps to a specific message in the app).
enum BackupRejection {
  malformed,
  unknownFormat,
  newerSchema,
  checksumMismatch,
  countMismatch,
  badField,
  badAmount,
  badReference,
  currencyMismatch,
  targetNotEmpty,
}

/// A backup that failed validation or restore; nothing was changed.
final class BackupRejectedException implements Exception {
  const BackupRejectedException(this.reason, this.detail);

  /// Machine-readable reason.
  final BackupRejection reason;

  /// Developer detail (no financial data; ids only).
  final String detail;

  @override
  String toString() => 'BackupRejectedException(${reason.name}): $detail';
}

/// Exported account columns, in file order. `text?` marks nullable text.
const Map<String, String> accountFields = {
  'id': 'text',
  'name': 'text',
  'name_norm': 'text',
  'kind': 'text',
  'currency': 'text',
  'opening_balance_minor': 'money_signed',
  'sort_order': 'int',
  'created_at': 'text',
  'updated_at': 'text',
  'archived_at': 'text?',
};

/// Exported transaction columns (schema v2).
const Map<String, String> transactionFields = {
  'id': 'text',
  'kind': 'text',
  'amount_minor': 'money_positive',
  'currency': 'text',
  'account_id': 'text',
  'to_account_id': 'text?',
  'occurred_on': 'text',
  'note': 'text?',
  'origin': 'text',
  'external_ref': 'text?',
  'created_at': 'text',
  'updated_at': 'text',
};

/// Transaction columns of schema v1: v2 added `external_ref` (schema.dart).
final Map<String, String> transactionFieldsV1 = {
  for (final e in transactionFields.entries)
    if (e.key != 'external_ref') e.key: e.value,
};

/// The account columns a backup of [schemaVersion] carries (T-006).
Map<String, String> accountFieldsFor(int schemaVersion) => switch (
      schemaVersion) {
      1 || 2 => accountFields,
      _ => throw BackupRejectedException(
          BackupRejection.badField,
          'no field set for schema v$schemaVersion',
        ),
    };

/// The transaction columns a backup of [schemaVersion] carries. A file is
/// checked against its own version's set, so a v1 file with a v2 field is
/// rejected (T-006, BACKUP_RESTORE §4 step 2).
Map<String, String> transactionFieldsFor(int schemaVersion) => switch (
      schemaVersion) {
      1 => transactionFieldsV1,
      2 => transactionFields,
      _ => throw BackupRejectedException(
          BackupRejection.badField,
          'no field set for schema v$schemaVersion',
        ),
    };

/// Builds the document and its checksum: sha256 of the canonical body
/// without the `checksum` field (DATA_MODEL §10).
Map<String, Object?> buildBackup({
  required int schemaVersion,
  required String appVersion,
  required String exportedAt,
  required List<Map<String, Object?>> accounts,
  required List<Map<String, Object?>> transactions,
}) {
  final body = <String, Object?>{
    'format': backupFormat,
    'format_version': backupFormatVersion,
    'schema_version': schemaVersion,
    'app_version': appVersion,
    'exported_at': exportedAt,
    'device_label': '',
    'counts': <String, Object?>{
      'accounts': accounts.length,
      'transactions': transactions.length,
    },
    'accounts': accounts,
    'transactions': transactions,
  };
  return {...body, 'checksum': sha256OfString(canonicalJson(body))};
}

/// The validated content of a backup, ready to write.
final class ValidatedBackup {
  const ValidatedBackup(this.schemaVersion, this.accounts, this.transactions);

  final int schemaVersion;
  final List<Map<String, Object?>> accounts;
  final List<Map<String, Object?>> transactions;
}

/// Parses and validates [text] (BACKUP_RESTORE §2, "validate, change
/// nothing"). Throws [BackupRejectedException].
ValidatedBackup validateBackup(String text, {required int supportedSchema}) {
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (e) {
    throw BackupRejectedException(BackupRejection.malformed, e.message);
  }
  if (decoded is! Map<String, Object?>) {
    throw const BackupRejectedException(
      BackupRejection.malformed,
      'top level is not an object',
    );
  }
  if (decoded['format'] != backupFormat ||
      decoded['format_version'] != backupFormatVersion) {
    throw const BackupRejectedException(
      BackupRejection.unknownFormat,
      'format or format_version unknown',
    );
  }
  final schema = decoded['schema_version'];
  if (schema is! int || schema < 1) {
    throw const BackupRejectedException(
      BackupRejection.badField,
      'schema_version',
    );
  }
  if (schema > supportedSchema) {
    throw BackupRejectedException(
      BackupRejection.newerSchema,
      'file v$schema > supported v$supportedSchema (MG-03)',
    );
  }

  final checksum = decoded['checksum'];
  final body = Map<String, Object?>.of(decoded)..remove('checksum');
  String canonical;
  try {
    canonical = canonicalJson(body);
  } on ArgumentError catch (e) {
    throw BackupRejectedException(BackupRejection.badField, '$e');
  }
  if (checksum is! String || checksum != sha256OfString(canonical)) {
    throw const BackupRejectedException(
      BackupRejection.checksumMismatch,
      'checksum does not match the content',
    );
  }

  final accounts = _rows(decoded, 'accounts', accountFieldsFor(schema));
  final transactions =
      _rows(decoded, 'transactions', transactionFieldsFor(schema));
  final counts = decoded['counts'];
  if (counts is! Map<String, Object?> ||
      counts['accounts'] != accounts.length ||
      counts['transactions'] != transactions.length) {
    throw const BackupRejectedException(
      BackupRejection.countMismatch,
      'counts differ from the arrays',
    );
  }

  final accountCurrency = <String, String>{};
  for (final a in accounts) {
    final currency = a['currency']! as String;
    _knownCurrency(currency, a['id']! as String);
    accountCurrency[a['id']! as String] = currency;
  }
  for (final t in transactions) {
    _checkTransaction(t, accountCurrency);
  }
  return ValidatedBackup(schema, accounts, transactions);
}

List<Map<String, Object?>> _rows(
  Map<String, Object?> doc,
  String entity,
  Map<String, String> fields,
) {
  final list = doc[entity];
  if (list is! List<Object?>) {
    throw BackupRejectedException(BackupRejection.badField, entity);
  }
  final rows = <Map<String, Object?>>[];
  for (final item in list) {
    if (item is! Map<String, Object?>) {
      throw BackupRejectedException(BackupRejection.badField, entity);
    }
    for (final key in item.keys) {
      if (!fields.containsKey(key)) {
        throw BackupRejectedException(
          BackupRejection.badField,
          '$entity.$key is unknown',
        );
      }
    }
    for (final MapEntry(key: name, value: kind) in fields.entries) {
      _checkField(entity, name, kind, item[name], item.containsKey(name));
    }
    rows.add(item);
  }
  return rows;
}

void _checkField(
  String entity,
  String name,
  String kind,
  Object? value,
  bool present,
) {
  final where = '$entity.$name';
  if (!present) {
    throw BackupRejectedException(BackupRejection.badField, '$where missing');
  }
  switch (kind) {
    case 'text':
      if (value is! String) {
        throw BackupRejectedException(BackupRejection.badField, where);
      }
    case 'text?':
      if (value != null && value is! String) {
        throw BackupRejectedException(BackupRejection.badField, where);
      }
    case 'int':
      if (value is! int) {
        throw BackupRejectedException(BackupRejection.badField, where);
      }
    case 'money_signed' || 'money_positive':
      // DD-02: a decimal string; a JSON number is a defect (RKX-01).
      if (value is! String || !Money.isCanonical(value)) {
        throw BackupRejectedException(BackupRejection.badAmount, where);
      }
      if (kind == 'money_positive' && (value == '0' || value.startsWith('-'))) {
        throw BackupRejectedException(BackupRejection.badAmount, where);
      }
    default:
      throw StateError('unknown field kind $kind');
  }
}

void _checkTransaction(
  Map<String, Object?> t,
  Map<String, String> accountCurrency,
) {
  final id = t['id']! as String;
  final kind = t['kind']! as String;
  final currency = t['currency']! as String;
  final from = t['account_id']! as String;
  final to = t['to_account_id'] as String?;
  final fromCurrency = accountCurrency[from];
  if (fromCurrency == null) {
    throw BackupRejectedException(BackupRejection.badReference, '$id account');
  }
  if ((kind == 'transfer') != (to != null) || to == from) {
    throw BackupRejectedException(BackupRejection.badReference, '$id transfer');
  }
  if (to != null && accountCurrency[to] == null) {
    throw BackupRejectedException(BackupRejection.badReference, '$id target');
  }
  // DD-04: same currency as the account(s); no conversion in v0.1.
  if (currency != fromCurrency ||
      (to != null && accountCurrency[to] != currency)) {
    throw BackupRejectedException(BackupRejection.currencyMismatch, id);
  }
}

void _knownCurrency(String code, String id) {
  try {
    CurrencyCode.parse(code);
  } on FormatException {
    throw BackupRejectedException(BackupRejection.badField, '$id currency');
  }
}
