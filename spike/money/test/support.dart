// Shared helpers for the native T-002 tests. Synthetic data only.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:spike_money/spike_money_storage.dart';

const String fixedNow = '2026-10-27T12:00:00.000Z';
const CurrencyCode irr = CurrencyCode.irr;
final BigInt max = Money.maxMinor;

// Ids used by test/fixtures/schema_v1_fixture.sql (tool/make_fixture.py).
const String walletId = '018f3a00-0000-7000-8000-00000000000a';
const String bankId = '018f3a00-0000-7000-8000-00000000000b';
const String txMaxId = '018f3a00-0000-7000-8000-000000000001';
const String txOneId = '018f3a00-0000-7000-8000-000000000002';
const String txDeletedId = '018f3a00-0000-7000-8000-000000000003';

/// Persian account name with a ZWNJ, written as escapes (CM-10 keeps
/// Persian text out of source as literals).
const String walletName = '\u06a9\u06cc\u0641\u200c\u067e\u0648\u0644';

String fixedClock() => fixedNow;

Directory newTempDir() => Directory.systemTemp.createTempSync('spike_money_');

/// Opens [file] with the given migrations (default: the build's v1…v2).
SpikeDatabase openDb(
  File file, {
  List<Migration> migrations = schemaMigrations,
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return SpikeDatabase(
    NativeDatabase(file),
    migrations: migrations,
    now: fixedClock,
  );
}

/// The frozen v1 fixture written into [file] as a real v1 database.
Future<void> loadV1Fixture(File file) async {
  final sql = File('test/fixtures/schema_v1_fixture.sql').readAsStringSync();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = SpikeDatabase(
    NativeDatabase(
      file,
      enableMigrations: false,
      setup: (raw) => raw.execute(sql),
    ),
    migrations: schemaMigrations.sublist(0, 1),
    now: fixedClock,
  );
  await db.userVersion(); // opens the file, which runs the setup once
  await db.close();
}

/// `version` rows of schema_migrations.
Future<List<int>> history(SpikeDatabase db) async {
  final rows = await db
      .customSelect('SELECT version FROM schema_migrations ORDER BY version')
      .get();
  return [for (final r in rows) r.read<int>('version')];
}

/// Appends one evidence line for the CI summary (build/ is not committed).
void recordEvidence(String line) {
  File('build/spike-evidence.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('$line\n', mode: FileMode.append);
}
