// T-006 native tests: restore of a backup written by the older schema
// (SP-05, BACKUP_RESTORE §4 steps 2, 6, 7 and §5, MG-01, MG-03, I-09,
// I-10). Runs on Linux, macOS and Windows in CI
// (.github/workflows/spike-money.yml). Synthetic data only.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_money/spike_money_storage.dart';

import 'support.dart';

void main() {
  late Directory dir;
  setUp(() => dir = newTempDir());
  tearDown(() => dir.deleteSync(recursive: true));

  File file(String name) => File('${dir.path}/$name');
  final v1Only = schemaMigrations.sublist(0, 1);

  /// A backup made by the v1 code of this build from the frozen v1 fixture,
  /// i.e. the file an older app version would have written.
  Future<String> v1Backup() async {
    await loadV1Fixture(file('old-app.sqlite'));
    final oldApp = openDb(file('old-app.sqlite'), migrations: v1Only);
    final text = await oldApp.exportBackup(exportedAt: fixedNow);
    await oldApp.close();
    return text;
  }

  Map<String, Object?> decode(String text) =>
      jsonDecode(text) as Map<String, Object?>;

  List<Map<String, Object?>> rows(String text, String entity) => [
        for (final r in decode(text)[entity]! as List<Object?>)
          Map<String, Object?>.of(r! as Map<String, Object?>),
      ];

  Future<int> count(SpikeDatabase db, String table) async {
    final row =
        await db.customSelect('SELECT count(*) AS n FROM $table').getSingle();
    return row.read<int>('n');
  }

  void expectNoStagingFiles() {
    final left = dir
        .listSync()
        .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .where((name) => name.startsWith('restore-staging'))
        .toList();
    expect(left, isEmpty, reason: 'staging files left: $left');
  }

  test('the v1 code writes a v1 file: schema_version 1, no external_ref',
      () async {
    final text = await v1Backup();
    expect(decode(text)['schema_version'], 1);
    final transactions = rows(text, 'transactions');
    expect(transactions, hasLength(2)); // the deleted one is not exported
    for (final t in transactions) {
      expect(t.containsKey('external_ref'), isFalse);
    }
    final validated = validateBackup(text, supportedSchema: 2);
    expect(validated.schemaVersion, 1);
    // The v2-only importer still refuses it and points to restoreBackup.
    final direct = openDb(file('direct.sqlite'));
    await expectLater(
      direct.importBackup(text),
      throwsA(isA<BackupRejectedException>()),
    );
    expect(await count(direct, 'transactions'), 0);
    await direct.close();
  });

  test('BACKUP_RESTORE §4 step 7: a v1 file restores into a v2 database '
      'through a migrated staging database; values stay exact', () async {
    final text = await v1Backup();
    final target = openDb(file('target.sqlite'));
    await restoreBackup(target, text, workDir: dir);
    expectNoStagingFiles();

    expect(await target.userVersion(), 2);
    expect(await history(target), [1, 2]);
    expect(await target.readAmount(txMaxId), Money(max, irr));
    expect(await target.readAmount(txOneId), Money(BigInt.one, irr));
    expect(await target.readOpeningBalance(walletId), Money(-max, irr));
    final name = await target.customSelect(
      'SELECT name, external_ref FROM accounts a '
      'JOIN transactions t ON t.account_id = a.id WHERE t.id = ?',
      variables: [Variable.withString(txMaxId)],
    ).getSingle();
    expect(name.read<String>('name'), walletName);
    expect(name.readNullable<String>('external_ref'), isNull);
    expect(await count(target, 'transactions'), 2);

    // Re-export: a valid v2 file with the same logical data (I-09).
    final again = await target.exportBackup(exportedAt: fixedNow);
    expect(decode(again)['schema_version'], 2);
    expect(validateBackup(again, supportedSchema: 2).schemaVersion, 2);
    expect(rows(again, 'accounts'), rows(text, 'accounts'));
    final upgraded = rows(again, 'transactions');
    for (final t in upgraded) {
      expect(t.remove('external_ref'), isNull);
    }
    expect(upgraded, rows(text, 'transactions'));
    recordEvidence('older_backup v1->v2 restored '
        'transactions=${upgraded.length} sqlite=${await target.sqliteVersion()}');
    await target.close();
  });

  test('I-10: rejected older restores change nothing and leave no staging '
      'file', () async {
    final text = await v1Backup();

    // 1. Target not empty.
    final busy = openDb(file('busy.sqlite'));
    await busy.insertAccount(
      id: 'existing',
      name: 'existing',
      nameNorm: 'existing',
      kind: 'bank',
      openingBalance: Money(BigInt.zero, irr),
      now: fixedNow,
    );
    await expectLater(
      restoreBackup(busy, text, workDir: dir),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.reason,
          'reason',
          BackupRejection.targetNotEmpty,
        ),
      ),
    );
    expect(await count(busy, 'accounts'), 1);
    expect(await count(busy, 'transactions'), 0);
    expectNoStagingFiles();
    await busy.close();

    // 2. A v1 file that carries a v2 field: checked against its own set.
    final doc = decode(text);
    final withV2Field = [
      for (final t in doc['transactions']! as List<Object?>)
        {...t! as Map<String, Object?>, 'external_ref': null},
    ];
    final mixed = _reseal({...doc, 'transactions': withV2Field});
    final target = openDb(file('target.sqlite'));
    await expectLater(
      restoreBackup(target, mixed, workDir: dir),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.reason,
          'reason',
          BackupRejection.badField,
        ),
      ),
    );

    // 3. A file newer than the build (MG-03).
    final newer = _reseal({...decode(await _v2Text(dir)), 'schema_version': 3});
    await expectLater(
      restoreBackup(target, newer, workDir: dir),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.reason,
          'reason',
          BackupRejection.newerSchema,
        ),
      ),
    );

    // 4. Duplicate ids pass validation but fail in the staging insert: the
    // target is never written.
    final duplicated = _reseal({
      ...doc,
      'transactions': [
        for (final t in doc['transactions']! as List<Object?>)
          {...t! as Map<String, Object?>, 'id': txMaxId},
      ],
    });
    await expectLater(
      restoreBackup(target, duplicated, workDir: dir),
      throwsA(anything),
    );

    expect(await count(target, 'accounts'), 0);
    expect(await count(target, 'transactions'), 0);
    expectNoStagingFiles();
    await target.close();
  });
}

/// A v2 backup text with one account (for the newer-schema case).
Future<String> _v2Text(Directory dir) async {
  final db = openDb(File('${dir.path}/v2-source.sqlite'));
  await db.insertAccount(
    id: walletId,
    name: walletName,
    nameNorm: walletName.replaceAll('‌', ''),
    kind: 'cash',
    openingBalance: Money(BigInt.one, irr),
    now: fixedNow,
  );
  final text = await db.exportBackup(exportedAt: fixedNow);
  await db.close();
  return text;
}

String _reseal(Map<String, Object?> doc) {
  final body = Map<String, Object?>.of(doc)..remove('checksum');
  return canonicalJson(
    {...body, 'checksum': sha256OfString(canonicalJson(body))},
  );
}
