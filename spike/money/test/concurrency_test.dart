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

  test('diagnostics (records only): busy_timeout, compile options, lock '
      'wait inside a drift transaction', () async {
    final a = openShared(file, busyMs: 5000);
    open.add(a);
    expect(await a.userVersion(), 2);
    final b = openShared(file, busyMs: 5000);
    open.add(b);
    expect(await b.userVersion(), 2);

    Future<String> one(SpikeDatabase db, String sql) async {
      final row = await db.customSelect(sql).getSingle();
      return '${row.data.values.first}';
    }

    final facts = <String>[
      'busy_a=${await one(a, 'PRAGMA busy_timeout')}',
      'busy_b=${await one(b, 'PRAGMA busy_timeout')}',
      'locking=${await one(a, 'PRAGMA locking_mode')}',
      for (final o in ['HAVE_USLEEP', 'ENABLE_SETLK_TIMEOUT', 'THREADSAFE=1',
          'THREADSAFE=2', 'DEFAULT_WAL_SYNCHRONOUS=1'])
        '$o=${await one(a, "SELECT sqlite_compileoption_used('$o')")}',
    ];

    Future<String> tryWrite(SpikeDatabase db, String id) async {
      final watch = Stopwatch()..start();
      try {
        await addAccount(db, id);
        return 'ok@${watch.elapsedMilliseconds}ms';
      } on Object catch (e) {
        final text = '$e'.split('\n').first;
        return 'error@${watch.elapsedMilliseconds}ms:'
            '${text.length > 60 ? text.substring(0, 60) : text}';
      }
    }

    // 1. b in a drift transaction that only read; a writes.
    final outside = Zone.current;
    await b.transaction(() async {
      await accountCount(b);
      facts.add('write_during_drift_read_tx='
          '${await outside.run(() => tryWrite(a, 'd-1'))}');
    });
    // 2. b in a manual BEGIN DEFERRED read; a writes.
    await b.customStatement('BEGIN DEFERRED');
    await accountCount(b);
    facts.add('write_during_manual_deferred_read='
        '${await tryWrite(a, 'd-2')}');
    facts.add('count_in_manual_read_after=${await accountCount(b)}');
    await b.customStatement('COMMIT');
    // 3. b holds a manual write lock (BEGIN IMMEDIATE); a writes.
    await b.customStatement('BEGIN IMMEDIATE');
    facts.add('write_during_manual_immediate=${await tryWrite(a, 'd-3')}');
    await b.customStatement('COMMIT');

    recordEvidence('concurrency_diag os=${Platform.operatingSystem} '
        '${facts.join(' ')}');
  });

  test('WAL: a read transaction opened with BEGIN DEFERRED is a stable '
      'snapshot while the other connection commits', () async {
    final a = await connect();
    final b = await connect();
    expect(await journalMode(a), 'wal');
    expect(await journalMode(b), 'wal');
    await addAccount(a, 'acc-1');

    await b.customStatement('BEGIN DEFERRED');
    final before = await accountCount(b); // the snapshot starts here
    await addAccount(a, 'acc-2'); // a commits while b's snapshot is open
    final after = await accountCount(b);
    await b.customStatement('COMMIT');

    expect(before, 1);
    expect(after, 1, reason: 'the snapshot must not change inside it');
    expect(await accountCount(b), 2, reason: 'visible once b ends its read');
  });

  test('finding: drift transaction() takes the write lock at once, so even '
      'a read-only drift transaction blocks writers on other connections',
      () async {
    final b = await connect();
    final impatient = await connect(busyMs: 0);
    final outside = Zone.current;

    Object? error;
    await b.transaction(() async {
      await accountCount(b);
      try {
        await outside.run(() => addAccount(impatient, 'blocked'));
      } on Object catch (e) {
        error = e;
      }
    });
    expect(error, isLocked);
    expect(await hasAccount(b, 'blocked'), isFalse);
    // Once the drift transaction has ended the same write succeeds.
    await addAccount(impatient, 'after');
    expect(await hasAccount(b, 'after'), isTrue);
  });

  test('writer/writer: busy_timeout 0 fails at once; an app-level retry '
      'gets the second write in after the first commit on every OS',
      () async {
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

    // busy_timeout = 5000 plus a Dart-side retry (25 ms steps, 30 s cap):
    // SQLite's own wait is not relied on (it gives up early on Linux).
    final watch = Stopwatch()..start();
    var retries = 0;
    Future<void> retrying() async {
      while (true) {
        try {
          await addAccount(b, 'w-b');
          return;
        } on Object catch (e) {
          if (!isLocked.matches(e, <Object?, Object?>{}) ||
              watch.elapsed > const Duration(seconds: 30)) {
            rethrow;
          }
          retries++;
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      }
    }

    final second = retrying();
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
        'second_writer_ms=${watch.elapsedMilliseconds} '
        'app_retries=$retries busy0=locked');
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

    await b.customStatement('BEGIN DEFERRED');
    await accountCount(b); // starts b's read snapshot
    await addAccount(a, 'snap-a'); // a commits a newer version
    Object? error;
    try {
      await addAccount(b, 'snap-b'); // b cannot upgrade its old snapshot
    } on Object catch (e) {
      error = e;
    }
    await b.customStatement('ROLLBACK');

    expect(error, isLocked);
    expect(await hasAccount(b, 'snap-a'), isTrue);
    expect(await hasAccount(b, 'snap-b'), isFalse);
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
