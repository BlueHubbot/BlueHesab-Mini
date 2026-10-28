// T-002 native tests: money through SQLite TEXT, export and restore
// (SP-02, SP-05, I-01, I-09, I-10, DD-02). Runs on Linux, macOS and Windows
// in CI (.github/workflows/spike-money.yml). Synthetic data only.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spike_money/spike_money_storage.dart';

import 'support.dart';

void main() {
  late Directory dir;
  setUp(() => dir = newTempDir());
  tearDown(() => dir.deleteSync(recursive: true));

  Future<SpikeDatabase> seeded(String name) async {
    final db = openDb(File('${dir.path}/$name'));
    await db.insertAccount(
      id: walletId,
      name: walletName,
      nameNorm: walletName.replaceAll('\u200c', ''),
      kind: 'cash',
      openingBalance: Money(-max, irr),
      now: fixedNow,
    );
    await db.insertTransaction(
      id: txMaxId,
      kind: 'expense',
      amount: Money(max, irr),
      accountId: walletId,
      occurredOn: '2026-10-27',
      now: fixedNow,
    );
    await db.insertTransaction(
      id: txOneId,
      kind: 'income',
      amount: Money(BigInt.one, irr),
      accountId: walletId,
      occurredOn: '2026-10-27',
      note: 'synthetic',
      now: fixedNow,
    );
    return db;
  }

  test('SP-02 / I-01: 999999999999999999 and 1 survive write, read, format, '
      'export and import', () async {
    final db = await seeded('a.sqlite');
    final sqlite = await db.sqliteVersion();
    recordEvidence('os=${Platform.operatingSystem} '
        'osVersion="${Platform.operatingSystemVersion}" sqlite=$sqlite '
        'dart="${Platform.version.split(' ').first}"');

    // write → read (DD-02: SQLite keeps TEXT; readAmount checks typeof()).
    final readMax = await db.readAmount(txMaxId);
    final readOne = await db.readAmount(txOneId);
    expect(readMax, Money(max, irr));
    expect(readMax.toStorage(), '999999999999999999');
    expect(readOne, Money(BigInt.one, irr));
    expect(await db.readOpeningBalance(walletId), Money(-max, irr));

    // read → format (MN-02, NM-02) and back (NM-05).
    const rial = MoneyFormatter(
      digits: DigitMode.latin,
      rialUnit: RialDisplayUnit.rial,
    );
    const toman = MoneyFormatter();
    expect(rial.formatNumber(readMax), '999,999,999,999,999,999');
    expect(rial.formatNumber(readOne), '1');
    for (final f in [rial, toman]) {
      expect(f.parseNumber(f.formatNumber(readMax), irr), readMax);
      expect(f.parseNumber(f.formatNumber(readOne), irr), readOne);
    }

    // format → export (DD-02: strings in JSON, never numbers).
    final exported = await db.exportBackup(exportedAt: fixedNow);
    expect(exported, contains('"amount_minor":"999999999999999999"'));
    expect(exported, contains('"amount_minor":"1"'));
    expect(exported, isNot(contains(':999999999999999999')));

    // export → import into a clean database → equal (I-09).
    final restored = openDb(File('${dir.path}/b.sqlite'));
    await restored.importBackup(exported);
    expect(await restored.readAmount(txMaxId), readMax);
    expect(await restored.readAmount(txOneId), readOne);
    expect(await restored.readOpeningBalance(walletId), Money(-max, irr));
    expect(await restored.exportBackup(exportedAt: fixedNow), exported);

    await db.close();
    await restored.close();
  });

  test('DD-02: the CHECK constraints refuse non-canonical amounts', () async {
    final db = await seeded('c.sqlite');
    Future<void> insert(String amount) => db.customStatement(
          'INSERT INTO transactions (id, kind, amount_minor, currency, '
          'account_id, occurred_on, created_at, updated_at) VALUES '
          "(?, 'expense', ?, 'IRR', ?, '2026-10-27', ?, ?)",
          <Object?>['bad-$amount', amount, walletId, fixedNow, fixedNow],
        );
    for (final bad in ['0', '0999', '-5', '1e3', '1.0', '', ' 1',
        '1000000000000000000']) {
      await expectLater(insert(bad), throwsA(anything), reason: bad);
    }
    // An integer bound by mistake: TEXT affinity stores it as text, so the
    // CHECK and the typeof() read check still hold (finding for SP-02).
    await db.customStatement(
      'INSERT INTO transactions (id, kind, amount_minor, currency, '
      'account_id, occurred_on, created_at, updated_at) VALUES '
      "('as-int', 'expense', ?, 'IRR', ?, '2026-10-27', ?, ?)",
      <Object?>[7, walletId, fixedNow, fixedNow],
    );
    expect(await db.readAmount('as-int'), Money(BigInt.from(7), irr));
    await db.close();
  });

  test('I-10: a restore that fails half way leaves the database empty',
      () async {
    final source = await seeded('d.sqlite');
    final exported = await source.exportBackup(exportedAt: fixedNow);
    await source.close();

    // Valid file, but the target is not empty: rejected, nothing written.
    final busy = await seeded('e.sqlite');
    await expectLater(
      busy.importBackup(exported),
      throwsA(isA<BackupRejectedException>()),
    );
    final busyRows = await busy
        .customSelect('SELECT count(*) AS n FROM transactions')
        .getSingle();
    expect(busyRows.read<int>('n'), 2);
    await busy.close();

    // Duplicate ids pass validation but fail in SQL: the transaction rolls
    // back the rows already written.
    final doc = exported.replaceFirst(txOneId, txMaxId);
    final resealed = _reseal(doc);
    final target = openDb(File('${dir.path}/f.sqlite'));
    await expectLater(target.importBackup(resealed), throwsA(anything));
    for (final table in ['accounts', 'transactions']) {
      final row = await target
          .customSelect('SELECT count(*) AS n FROM $table')
          .getSingle();
      expect(row.read<int>('n'), 0, reason: table);
    }
    await target.close();
  });
}

String _reseal(String text) {
  final doc = jsonDecode(text) as Map<String, Object?>;
  final body = Map<String, Object?>.of(doc)..remove('checksum');
  return canonicalJson({...body, 'checksum': sha256OfString(canonicalJson(body))});
}
