// T-002 native tests: migrations v1 → v2 (SP-05, MG-01…MG-04, ADR-0003).
// Synthetic data only.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spike_money/spike_money_storage.dart';

import 'support.dart';

void main() {
  late Directory dir;
  setUp(() => dir = newTempDir());
  tearDown(() => dir.deleteSync(recursive: true));

  File file(String name) => File('${dir.path}/$name');
  final v1Only = schemaMigrations.sublist(0, 1);

  test('MG-04: the v1 steps still build exactly the frozen v1 fixture schema',
      () async {
    await loadV1Fixture(file('fixture.sqlite'));
    final fromFixture = openDb(file('fixture.sqlite'), migrations: v1Only);
    final fresh = openDb(file('fresh.sqlite'), migrations: v1Only);
    expect(await fresh.schemaSnapshot(), await fromFixture.schemaSnapshot());
    expect(await fromFixture.userVersion(), 1);
    await fromFixture.close();
    await fresh.close();
  });

  test('MG-04: v1 fixture -> v2 and empty -> v2 give the identical schema; '
      'data survives', () async {
    await loadV1Fixture(file('fixture.sqlite'));
    expect(headerUserVersion(file('fixture.sqlite')), 1);

    final upgraded = openDb(file('fixture.sqlite'));
    final fromFixture = await upgraded.schemaSnapshot();
    expect(await upgraded.userVersion(), 2);
    expect(await history(upgraded), [1, 2]);
    expect(await upgraded.readAmount(txMaxId), Money(max, irr));
    expect(await upgraded.readAmount(txOneId), Money(BigInt.one, irr));
    expect(await upgraded.readOpeningBalance(walletId), Money(-max, irr));
    await upgraded.close();

    final fresh = openDb(file('fresh.sqlite'));
    expect(await fresh.schemaSnapshot(), fromFixture);
    expect(await history(fresh), [1, 2]);
    await fresh.close();
    expect(fromFixture.join('\n'), contains('external_ref TEXT'));
    expect(fromFixture.join('\n'), contains('table|idempotency|'));
  });

  test('MG-01 / MG-02: a failing step rolls back the whole upgrade, and the '
      'next open can still upgrade', () async {
    final path = file('fixture.sqlite');
    await loadV1Fixture(path);
    final before = openDb(path, migrations: v1Only);
    final schemaBefore = await before.schemaSnapshot();
    await before.close();

    final broken = [
      schemaMigrations[0],
      Migration(2, [
        ...schemaMigrations[1].statements,
        'INSERT INTO no_such_table VALUES (1)',
      ]),
    ];
    final failing = openDb(path, migrations: broken);
    await expectLater(failing.userVersion(), throwsA(anything));
    await failing.close();

    expect(headerUserVersion(path), 1);
    final after = openDb(path, migrations: v1Only);
    expect(await after.schemaSnapshot(), schemaBefore);
    expect(await history(after), [1]);
    expect(await after.readAmount(txMaxId), Money(max, irr));
    await after.close();

    final retried = openDb(path);
    expect(await retried.userVersion(), 2);
    await retried.close();
  });

  test('MG-03: a file newer than the build is refused and not modified',
      () async {
    final path = file('newer.sqlite');
    final db = openDb(path);
    await db.userVersion();
    await db.customStatement('PRAGMA user_version = 3');
    await db.close();
    final bytes = path.readAsBytesSync();

    final refused = openDb(path);
    await expectLater(
      refused.userVersion(),
      throwsA(isA<SchemaTooNewException>()),
    );
    await refused.close();
    expect(path.readAsBytesSync(), bytes);
    expect(headerUserVersion(path), 3);
  });

  test('a changed released step is detected on open', () async {
    final path = file('v2.sqlite');
    final db = openDb(path);
    await db.userVersion();
    await db.close();
    final edited = [
      schemaMigrations[0],
      Migration(2, [...schemaMigrations[1].statements, 'SELECT 1']),
    ];
    final reopened = openDb(path, migrations: edited);
    await expectLater(
      reopened.userVersion(),
      throwsA(isA<MigrationHistoryException>()),
    );
    await reopened.close();
  });

  test('MG-02: recovery copy before migrating; only the last 3 are kept',
      () async {
    final path = file('fixture.sqlite');
    await loadV1Fixture(path);
    final original = path.readAsBytesSync();
    for (final stamp in ['20261027T120000001', '20261027T120000002',
        '20261027T120000003', '20261027T120000004']) {
      final copy = copyForRecovery(path, targetVersion: 2, stamp: stamp);
      expect(copy, isNotNull);
      expect(copy!.readAsBytesSync(), original);
      expect(headerUserVersion(copy), 1);
    }
    final copies = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.contains('.recovery-'))
        .toList()
      ..sort();
    expect(copies, [
      'fixture.sqlite.recovery-v1-20261027T120000002',
      'fixture.sqlite.recovery-v1-20261027T120000003',
      'fixture.sqlite.recovery-v1-20261027T120000004',
    ]);

    final db = openDb(path);
    await db.userVersion();
    await db.close();
    expect(copyForRecovery(path, targetVersion: 2, stamp: 'x'), isNull);
  });
}
