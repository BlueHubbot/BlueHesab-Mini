// T-006 spike: restore of a backup written by an older schema version
// (SP-05, BACKUP_RESTORE §4 steps 2, 6, 7 and §5, MG-01, I-10). Native
// targets only (dart:io).
//
// The file is validated against its own version's field set, written into a
// staging database built by the first N migration steps of this build,
// upgraded by the same MG-01 code the app runs on open, checked
// (`integrity_check`, `foreign_key_check`), and only then copied into the
// target inside one transaction. The target is not written before that
// transaction, any failure rolls it back, and the staging files are always
// deleted. One migration list stays the only upgrade path: there is no
// second, JSON-level upgrader to keep in step with schema.dart.

import 'dart:io';

import 'backup_format.dart';
import 'backup_io.dart';
import 'open.dart';
import 'spike_database.dart';

/// Restores [text] into the empty [target], upgrading a file of an older
/// schema version through a staging database in [workDir]. Throws
/// [BackupRejectedException] (or the SQL error) with [target] unchanged.
Future<void> restoreBackup(
  SpikeDatabase target,
  String text, {
  required Directory workDir,
}) async {
  // Step 2: validate, change nothing (also rejects newer files, MG-03).
  final backup = validateBackup(text, supportedSchema: target.schemaVersion);
  if (backup.schemaVersion == target.schemaVersion) {
    return target.importBackup(text);
  }
  await _requireEmpty(target);

  final staging = File(
    '${workDir.path}${Platform.pathSeparator}restore-staging.sqlite',
  );
  deleteStagingFiles(staging);
  try {
    // Step 6 at the file's own version: the v<N> code path of this build.
    final old = openSpikeDatabase(
      staging,
      migrations: target.migrations.sublist(0, backup.schemaVersion),
    );
    try {
      await old.importBackup(text);
    } finally {
      await old.close();
    }

    // Step 7: the same forward-only migrations as on app start (MG-01),
    // then the integrity checks.
    final upgraded = openSpikeDatabase(staging, migrations: target.migrations);
    try {
      final version = await upgraded.userVersion();
      if (version != target.schemaVersion) {
        throw StateError('staging is v$version, '
            'expected v${target.schemaVersion}');
      }
      await _checkIntegrity(upgraded);
    } finally {
      await upgraded.close();
    }

    await _copyInto(target, staging);
  } finally {
    deleteStagingFiles(staging);
  }
}

/// Deletes [staging] and its `-wal`, `-shm` and `-journal` companions.
void deleteStagingFiles(File staging) {
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final f = File('${staging.path}$suffix');
    if (f.existsSync()) {
      f.deleteSync();
    }
  }
}

Future<void> _requireEmpty(SpikeDatabase db) async {
  final row = await db.customSelect(
    'SELECT (SELECT count(*) FROM main.accounts) + '
    '(SELECT count(*) FROM main.transactions) AS n',
  ).getSingle();
  if (row.read<int>('n') != 0) {
    throw const BackupRejectedException(
      BackupRejection.targetNotEmpty,
      'restore needs an empty database in the spike',
    );
  }
}

Future<void> _checkIntegrity(SpikeDatabase db) async {
  final integrity = await db.customSelect('PRAGMA integrity_check').get();
  final first = integrity.isEmpty ? null : integrity.first.data.values.first;
  if (integrity.length != 1 || first != 'ok') {
    throw const BackupRejectedException(
      BackupRejection.malformed,
      'staged database failed integrity_check',
    );
  }
  final orphans = await db.customSelect('PRAGMA foreign_key_check').get();
  if (orphans.isNotEmpty) {
    throw BackupRejectedException(
      BackupRejection.badReference,
      'staged database: ${orphans.length} foreign key problem(s)',
    );
  }
}

Future<void> _copyInto(SpikeDatabase target, File staging) async {
  // ATTACH cannot run inside a transaction, so it wraps the transaction.
  await target.customStatement(
    'ATTACH DATABASE ? AS staged',
    <Object?>[staging.path],
  );
  try {
    await target.transaction(() async {
      await _requireEmpty(target);
      final accounts = accountFieldsFor(target.schemaVersion).keys.join(', ');
      final transactions =
          transactionFieldsFor(target.schemaVersion).keys.join(', ');
      await target.customStatement(
        'INSERT INTO main.accounts ($accounts) '
        'SELECT $accounts FROM staged.accounts ORDER BY id',
      );
      await target.customStatement(
        'INSERT INTO main.transactions ($transactions) '
        'SELECT $transactions FROM staged.transactions ORDER BY id',
      );
    });
  } finally {
    await target.customStatement('DETACH DATABASE staged');
  }
}
