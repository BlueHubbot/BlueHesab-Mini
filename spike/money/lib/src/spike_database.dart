// T-002 spike: drift without code generation (SP-05, MG-01, MG-03, ADR-0003).
//
// The spike talks to SQLite through drift's custom statements only, so it
// needs no build_runner/drift_dev (fewer dependencies, CB-9). Migrations:
// - forward-only, all pending steps in ONE transaction (MG-01). drift does
//   not wrap migrations in a transaction by itself (drift docs,
//   "migrations/step_by_step", section Transactions), so the spike does.
// - `PRAGMA user_version` is written inside that transaction, so a crash
//   between commit and drift's own version write cannot leave a migrated
//   schema with the old version number.
// - a database newer than the app is refused before any write (MG-03).
// - `schema_migrations` must match the code's steps and checksums on every
//   open, so an edited released step is caught.

import 'package:drift/drift.dart';

import 'schema.dart';

/// MG-03: the file was written by a newer app.
final class SchemaTooNewException implements Exception {
  const SchemaTooNewException(this.fileVersion, this.supportedVersion);

  /// `user_version` found in the file.
  final int fileVersion;

  /// Highest version this build knows.
  final int supportedVersion;

  @override
  String toString() => 'SchemaTooNewException: file is v$fileVersion, '
      'this build supports up to v$supportedVersion (MG-03)';
}

/// `schema_migrations` does not match the migrations of this build.
final class MigrationHistoryException implements Exception {
  const MigrationHistoryException(this.message);

  /// What did not match.
  final String message;

  @override
  String toString() => 'MigrationHistoryException: $message';
}

/// UTC instant with milliseconds, e.g. `2026-10-24T06:55:00.000Z` (DT-A).
String utcInstant(DateTime time) {
  final t = time.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  final ms = t.millisecond.toString().padLeft(3, '0');
  return '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}'
      'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${ms}Z';
}

String _systemNow() => utcInstant(DateTime.now());

/// The spike database. Pass a smaller or altered [migrations] list in tests.
class SpikeDatabase extends GeneratedDatabase {
  SpikeDatabase(
    super.executor, {
    List<Migration> migrations = schemaMigrations,
    String Function() now = _systemNow,
  })  : _migrations = migrations,
        _now = now {
    for (var i = 0; i < migrations.length; i++) {
      if (migrations[i].version != i + 1) {
        throw ArgumentError('migration versions must be 1..n in order');
      }
    }
  }

  final List<Migration> _migrations;
  final String Function() _now;

  @override
  int get schemaVersion => _migrations.length;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => _migrate(0, schemaVersion),
        onUpgrade: (m, from, to) => _migrate(from, to),
        beforeOpen: (details) async {
          // Has no effect inside a transaction, so it is set here (drift docs).
          await customStatement('PRAGMA foreign_keys = ON');
          await _checkHistory();
        },
      );

  Future<void> _migrate(int from, int to) async {
    if (from > to) {
      throw SchemaTooNewException(from, to); // MG-03, before any write
    }
    await transaction(() async {
      for (final step in _migrations) {
        if (step.version <= from || step.version > to) {
          continue;
        }
        for (final sql in step.statements) {
          await customStatement(sql);
        }
        await customStatement(
          'INSERT INTO schema_migrations (version, applied_at, checksum) '
          'VALUES (?, ?, ?)',
          <Object?>[step.version, _now(), step.checksum],
        );
      }
      await customStatement('PRAGMA user_version = $to');
    });
  }

  Future<void> _checkHistory() async {
    final rows = await customSelect(
      'SELECT version, checksum FROM schema_migrations ORDER BY version',
    ).get();
    if (rows.length != _migrations.length) {
      throw MigrationHistoryException(
        '${rows.length} recorded steps, build has ${_migrations.length}',
      );
    }
    for (var i = 0; i < rows.length; i++) {
      final version = rows[i].read<int>('version');
      final checksum = rows[i].read<String>('checksum');
      final step = _migrations[i];
      if (version != step.version || checksum != step.checksum) {
        throw MigrationHistoryException('step $version differs from the build');
      }
    }
  }

  /// `PRAGMA user_version` of the open file (MG-01).
  Future<int> userVersion() async {
    final row = await customSelect('PRAGMA user_version').getSingle();
    return row.read<int>('user_version');
  }

  /// The SQLite library version in use (evidence per OS, DQ-5).
  Future<String> sqliteVersion() async {
    final row = await customSelect('SELECT sqlite_version() AS v').getSingle();
    return row.read<String>('v');
  }

  /// Every schema object with its stored SQL, sorted; equal snapshots mean
  /// an identical schema (MG-04).
  Future<List<String>> schemaSnapshot() async {
    final rows = await customSelect(
      'SELECT type, name, tbl_name, sql FROM sqlite_master '
      "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
    ).get();
    return [
      for (final r in rows)
        '${r.read<String>('type')}|${r.read<String>('name')}|'
            '${r.read<String>('tbl_name')}|${r.readNullable<String>('sql')}',
    ];
  }
}
