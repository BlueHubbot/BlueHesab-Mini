// T-002 on a device (SP-02, SP-05, I-01, MG-01, MG-04): the same checks as
// the VM tests, on the Android emulator and the iOS simulator, with a real
// file in the app's temporary directory. Synthetic data only.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spike_money/spike_money_storage.dart';

const String now = '2026-10-27T12:00:00.000Z';
const String wallet = '018f3a00-0000-7000-8000-00000000000a';
const String txMax = '018f3a00-0000-7000-8000-000000000001';
const String txOne = '018f3a00-0000-7000-8000-000000000002';
const CurrencyCode irr = CurrencyCode.irr;
final BigInt max = Money.maxMinor;

String clock() => now;

Future<void> seed(SpikeDatabase db) async {
  await db.insertAccount(
    id: wallet,
    name: 'synthetic wallet',
    nameNorm: 'synthetic wallet',
    kind: 'cash',
    openingBalance: Money(-max, irr),
    now: now,
  );
  await db.insertTransaction(
    id: txMax,
    kind: 'expense',
    amount: Money(max, irr),
    accountId: wallet,
    occurredOn: '2026-10-27',
    now: now,
  );
  await db.insertTransaction(
    id: txOne,
    kind: 'income',
    amount: Money(BigInt.one, irr),
    accountId: wallet,
    occurredOn: '2026-10-27',
    now: now,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('spike_money_'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('SP-02 / I-01 on device: write, read, format, export, import',
      (tester) async {
    final db = openSpikeDatabase(File('${dir.path}/a.sqlite'), now: clock);
    await seed(db);
    final sqlite = await db.sqliteVersion();
    // One line the CI step turns into an annotation (evidence per OS).
    // ignore: avoid_print
    print('SPIKE_EVIDENCE os=${Platform.operatingSystem} '
        'osVersion="${Platform.operatingSystemVersion}" sqlite=$sqlite');

    final readMax = await db.readAmount(txMax);
    expect(readMax, Money(max, irr));
    expect(readMax.toStorage(), '999999999999999999');
    expect(await db.readAmount(txOne), Money(BigInt.one, irr));
    expect(await db.readOpeningBalance(wallet), Money(-max, irr));

    const rial = MoneyFormatter(
      digits: DigitMode.latin,
      rialUnit: RialDisplayUnit.rial,
    );
    expect(rial.formatNumber(readMax), '999,999,999,999,999,999');
    const toman = MoneyFormatter();
    expect(toman.parseNumber(toman.formatNumber(readMax), irr), readMax);

    final exported = await db.exportBackup(exportedAt: now);
    expect(exported, contains('"amount_minor":"999999999999999999"'));
    final restored = openSpikeDatabase(File('${dir.path}/b.sqlite'), now: clock);
    await restored.importBackup(exported);
    expect(await restored.readAmount(txMax), readMax);
    expect(await restored.readAmount(txOne), Money(BigInt.one, irr));
    expect(await restored.exportBackup(exportedAt: now), exported);
    await db.close();
    await restored.close();
  });

  testWidgets('SP-05 / MG-01 on device: v1 -> v2, a failing step rolls back',
      (tester) async {
    final path = File('${dir.path}/m.sqlite');
    final v1Only = schemaMigrations.sublist(0, 1);
    final v1 = openSpikeDatabase(path, migrations: v1Only, now: clock);
    await seed(v1);
    final schemaV1 = await v1.schemaSnapshot();
    await v1.close();
    expect(headerUserVersion(path), 1);

    final broken = [
      schemaMigrations[0],
      Migration(2, [
        ...schemaMigrations[1].statements,
        'INSERT INTO no_such_table VALUES (1)',
      ]),
    ];
    final failing = openSpikeDatabase(path, migrations: broken, now: clock);
    await expectLater(failing.userVersion(), throwsA(anything));
    await failing.close();
    final after = openSpikeDatabase(path, migrations: v1Only, now: clock);
    expect(await after.schemaSnapshot(), schemaV1);
    expect(await after.userVersion(), 1);
    await after.close();

    expect(copyForRecovery(path, targetVersion: 2, stamp: '1'), isNotNull);
    final upgraded = openSpikeDatabase(path, now: clock);
    expect(await upgraded.userVersion(), 2);
    expect(await upgraded.readAmount(txMax), Money(max, irr));
    final fresh = openSpikeDatabase(File('${dir.path}/f.sqlite'), now: clock);
    expect(await fresh.schemaSnapshot(), await upgraded.schemaSnapshot());
    await upgraded.close();
    await fresh.close();
  });
}
