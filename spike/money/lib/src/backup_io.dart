// T-002 spike: export and restore through drift (SP-02 export → import,
// I-09, I-10, BACKUP_RESTORE §2). Restore validates the whole file first,
// then writes everything in one transaction into an empty database; any
// failure rolls back and leaves the database unchanged.

import 'backup_format.dart';
import 'canonical_json.dart';
import 'spike_database.dart';

/// Backup export and restore for the spike database. Export writes the
/// field set of the open schema version (v1 code writes v1 files, T-006).
extension BackupIo on SpikeDatabase {
  /// The backup file content: canonical JSON with its checksum.
  Future<String> exportBackup({
    required String exportedAt,
    String appVersion = 'spike-T-002',
  }) async {
    final accounts = await _select(
      'SELECT ${accountFieldsFor(schemaVersion).keys.join(', ')} FROM accounts '
      'WHERE deleted_at IS NULL ORDER BY id',
    );
    final transactions = await _select(
      'SELECT ${transactionFieldsFor(schemaVersion).keys.join(', ')} '
      'FROM transactions '
      'WHERE deleted_at IS NULL ORDER BY id',
    );
    return canonicalJson(
      buildBackup(
        schemaVersion: schemaVersion,
        appVersion: appVersion,
        exportedAt: exportedAt,
        accounts: accounts,
        transactions: transactions,
      ),
    );
  }

  /// Restores [text] into this (empty) database or throws
  /// [BackupRejectedException] with the database unchanged (I-10).
  Future<void> importBackup(String text) async {
    final backup = validateBackup(text, supportedSchema: schemaVersion);
    if (backup.schemaVersion != schemaVersion) {
      // Older files go through restoreBackup (backup_upgrade.dart), which
      // stages them at their own version and runs the migrations (T-006).
      throw BackupRejectedException(
        BackupRejection.badField,
        'importBackup takes schema v$schemaVersion only; use restoreBackup',
      );
    }
    await transaction(() async {
      final row = await customSelect(
        'SELECT (SELECT count(*) FROM accounts) + '
        '(SELECT count(*) FROM transactions) AS n',
      ).getSingle();
      if (row.read<int>('n') != 0) {
        throw const BackupRejectedException(
          BackupRejection.targetNotEmpty,
          'restore needs an empty database in the spike',
        );
      }
      await _insertAll(
        'accounts',
        accountFieldsFor(schemaVersion).keys,
        backup.accounts,
      );
      await _insertAll(
        'transactions',
        transactionFieldsFor(schemaVersion).keys,
        backup.transactions,
      );
    });
  }

  Future<List<Map<String, Object?>>> _select(String sql) async {
    final rows = await customSelect(sql).get();
    return [for (final r in rows) Map<String, Object?>.of(r.data)];
  }

  Future<void> _insertAll(
    String table,
    Iterable<String> columns,
    List<Map<String, Object?>> rows,
  ) async {
    final names = columns.toList();
    final marks = List.filled(names.length, '?').join(', ');
    final sql = 'INSERT INTO $table (${names.join(', ')}) VALUES ($marks)';
    for (final row in rows) {
      await customStatement(sql, <Object?>[for (final n in names) row[n]]);
    }
  }
}
