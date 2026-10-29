// T-006 native tests: two connections on one database file in one process
// (SP-05 "concurrent read/write", ADR-0003 row "Concurrency", MG-02).
//
// Each connection runs in its own drift background isolate, as a UI isolate
// and an export/backup isolate would. Both use WAL. The tests assert order
// and lower time bounds only, never upper bounds (slow CI runners). Calls
// to the other connection inside a transaction run in the zone outside it,
// so drift cannot route them into this connection's transaction.
// Runs on Linux, macOS and Windows in CI. Synthetic data only.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_money/spike_money_storage.dart';

import 'support.dart';

/// A connection in its own isolate with WAL and the given busy timeout.
SpikeDatabase openShared(File file, {required int busyMs}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return SpikeDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (raw) {
        raw.execute('PRAGMA journal_mode = WAL');
        raw.execute('PRAGMA busy_timeout = $busyMs');
      },
    ),
    now: fixedClock,
  );
}

Future<void> addAccount(SpikeDatabase db, String id) => db.insertAccount(
      id: id,
      name: id,
      nameNorm: id,
      kind: 'bank',
      openingBalance: Money(BigInt.one, irr),
      now: fixedNow,
    );

Future<int> accountCount(SpikeDatabase db) async {
  final row =
      await db.customSelect('SELECT count(*) AS n FROM accounts').getSingle();
  return row.read<int>('n');
}

Future<bool> hasAccount(SpikeDatabase db, String id) async {
  final rows = await db
      .customSelect("SELECT id FROM accounts WHERE id = '$id'")
      .get();
  return rows.isNotEmpty;
}

Future<String> journalMode(SpikeDatabase db) async {
  final row = await db.customSelect('PRAGMA journal_mode').getSingle();
  return row.read<String>('journal_mode');
}

final Matcher isLocked = predicate<Object>(
  (e) => e.toString().contains('database is locked'),
  'an SQLite "database is locked" error',
);

void main() {
  late Directory dir;
  late File file;
  final open = <SpikeDatabase>[];

  setUp(() {
    dir = newTempDir();
    file = File('${dir.path}/shared.sqlite');
  });
  tearDown(() async {
    for (final db in open) {
      try {
        await db.close();
      } on Object {
        // Already closed by the test; nothing to do.
      }
    }
    open.clear();
    dir.deleteSync(recursive: true);
  });

  /// Opens a connection; the first one creates and migrates the file.
  Future<SpikeDatabase> connect({int busyMs = 5000}) async {
    final db = openShared(file, busyMs: busyMs);
    open.add(db);
    expect(await db.userVersion(), 2);
    return db;
  }

  test('both connections use WAL; a read transaction is a stable snapshot '
      'while the other connection commits', () async {
    final a = await connect();
    final b = await connect();
    expect(await journalMode(a), 'wal');
    expect(await journalMode(b), 'wal');
    await addAccount(a, 'acc-1');

    late int before;
    late int after;
    final outside = Zone.current;
    await b.transaction(() async {
      before = await accountCount(b);
      // a commits while b's snapshot is open
      await outside.run(() => addAccount(a, 'acc-2'));
      after = await accountCount(b);
    });
    expect(before, 1);
    expect(after, 1, reason: 'the snapshot must not change inside it');
    expect(await accountCount(b), 2, reason: 'visible once b ends its read');
  });

  test('writer/writer: with busy_timeout the second writer waits for the '
      'first commit; with busy_timeout 0 it fails at once', () async {
    final a = await connect();
    final b = await connect();
    final impatient = await connect(busyMs: 0);

    final holds = Completer<void>();
    final release = Completer<void>();
    final first = a.transaction(() async {
      await addAccount(a, 'w-a');
      holds.complete();
      await release.future;
    });
    await holds.future;

    // busy_timeout = 0: SQLITE_BUSY at once, nothing stored.
    await expectLater(addAccount(impatient, 'w-zero'), throwsA(isLocked));

    // busy_timeout = 5000: waits in its own isolate until a commits.
    final watch = Stopwatch()..start();
    final second = addAccount(b, 'w-b');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    release.complete();
    await first;
    await second;
    watch.stop();

    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(250));
    expect(await hasAccount(b, 'w-a'), isTrue);
    expect(await hasAccount(b, 'w-b'), isTrue);
    expect(await hasAccount(b, 'w-zero'), isFalse);
    recordEvidence('concurrency os=${Platform.operatingSystem} '
        'second_writer_waited_ms=${watch.elapsedMilliseconds} '
        'busy0=locked sqlite=${await b.sqliteVersion()}');
  });

  test('a rolled-back write is never visible to the other connection',
      () async {
    final a = await connect();
    final b = await connect();
    await addAccount(a, 'kept');

    late int seenDuring;
    final outside = Zone.current;
    await expectLater(
      a.transaction(() async {
        await addAccount(a, 'rolled-back');
        // the reader is not blocked by the open write (WAL)
        seenDuring = await outside.run(() => accountCount(b));
        throw StateError('roll back');
      }),
      throwsStateError,
    );
    expect(seenDuring, 1);
    expect(await accountCount(b), 1);
    expect(await hasAccount(a, 'rolled-back'), isFalse);
  });

  test('finding for ADR-0003: a read-then-write transaction fails after the '
      'other connection committed, even with busy_timeout', () async {
    final a = await connect();
    final b = await connect();

    Object? error;
    final outside = Zone.current;
    try {
      await b.transaction(() async {
        await accountCount(b); // starts b's read snapshot (deferred BEGIN)
        // a commits a newer version
        await outside.run(() => addAccount(a, 'snap-a'));
        await addAccount(b, 'snap-b'); // b cannot upgrade its old snapshot
      });
    } on Object catch (e) {
      error = e;
    }
    expect(error, isLocked);
    expect(await hasAccount(a, 'snap-a'), isTrue);
    expect(await hasAccount(a, 'snap-b'), isFalse);
    recordEvidence('concurrency read_then_write_after_commit=locked '
        '(SQLITE_BUSY_SNAPSHOT; product: one writer or BEGIN IMMEDIATE)');
  });

  test('MG-02: with a WAL connection open the recovery copy refuses; after '
      'the last close no -wal is left and the copy works', () async {
    final a = await connect();
    final b = await connect();
    await addAccount(a, 'before-close');

    expect(File('${file.path}-wal').existsSync(), isTrue);
    expect(
      () => copyForRecovery(file, targetVersion: 3, stamp: 'open'),
      throwsStateError,
    );

    await a.close();
    await b.close();
    open.clear();
    expect(File('${file.path}-wal').existsSync(), isFalse);
    expect(File('${file.path}-shm').existsSync(), isFalse);
    expect(headerUserVersion(file), 2);

    final copy = copyForRecovery(file, targetVersion: 3, stamp: 'closed');
    expect(copy, isNotNull);
    final reopened = openShared(copy!, busyMs: 5000);
    open.add(reopened);
    expect(await hasAccount(reopened, 'before-close'), isTrue);
  });
}
