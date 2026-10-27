// T-002 platform-neutral tests (SP-02, I-01, DD-01…DD-05, MN-02, NM-01…NM-06,
// RKX-01, I-10). Runs on the VM (`flutter test`) and in Chrome
// (`flutter test --platform chrome test/core_test.dart`): the web build only
// formats money (ADR-0009), and BigInt must stay exact there (DD-05).
// Synthetic data only.
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_money/spike_money_core.dart';

final BigInt max = Money.maxMinor;
const CurrencyCode irr = CurrencyCode.irr;
const String now = '2026-10-27T12:00:00.000Z';
const String wallet = '\u06a9\u06cc\u0641\u200c\u067e\u0648\u0644';

/// Latin digits → U+06F0… (independent of the code under test).
String fa(String latin) => latin
    .split('')
    .map((c) => '0123456789'.contains(c)
        ? String.fromCharCode(0x06F0 + int.parse(c))
        : c == ','
            ? '\u066c'
            : c == '.'
                ? '\u066b'
                : c)
    .join();

const MoneyFormatter rialLatin =
    MoneyFormatter(digits: DigitMode.latin, rialUnit: RialDisplayUnit.rial);
const MoneyFormatter tomanLatin =
    MoneyFormatter(digits: DigitMode.latin, rialUnit: RialDisplayUnit.toman);
const MoneyFormatter rialFa = MoneyFormatter(rialUnit: RialDisplayUnit.rial);
const MoneyFormatter tomanFa = MoneyFormatter();

List<Map<String, Object?>> sampleAccounts() => [
      {
        'id': '018f3a00-0000-7000-8000-00000000000a',
        'name': wallet,
        'name_norm': wallet.replaceAll('\u200c', ''),
        'kind': 'cash',
        'currency': 'IRR',
        'opening_balance_minor': '-999999999999999999',
        'sort_order': 0,
        'created_at': now,
        'updated_at': now,
        'archived_at': null,
      },
    ];

List<Map<String, Object?>> sampleTransactions() => [
      {
        'id': '018f3a00-0000-7000-8000-000000000001',
        'kind': 'expense',
        'amount_minor': '999999999999999999',
        'currency': 'IRR',
        'account_id': '018f3a00-0000-7000-8000-00000000000a',
        'to_account_id': null,
        'occurred_on': '2026-10-27',
        'note': 'a "quoted" note\\ with\ttab\nand newline',
        'origin': 'manual',
        'external_ref': null,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': '018f3a00-0000-7000-8000-000000000002',
        'kind': 'income',
        'amount_minor': '1',
        'currency': 'IRR',
        'account_id': '018f3a00-0000-7000-8000-00000000000a',
        'to_account_id': null,
        'occurred_on': '2026-10-27',
        'note': null,
        'origin': 'manual',
        'external_ref': null,
        'created_at': now,
        'updated_at': now,
      },
    ];

Map<String, Object?> sampleBackup() => buildBackup(
      schemaVersion: 2,
      appVersion: 'spike-T-002',
      exportedAt: now,
      accounts: sampleAccounts(),
      transactions: sampleTransactions(),
    );

/// Re-computes the checksum after a test edits the document on purpose.
String reseal(Map<String, Object?> doc) {
  final body = Map<String, Object?>.of(doc)..remove('checksum');
  return canonicalJson({...body, 'checksum': sha256OfString(canonicalJson(body))});
}

Map<String, Object?> decode(String text) =>
    jsonDecode(text) as Map<String, Object?>;

Matcher rejectedWith(BackupRejection reason) => throwsA(
      isA<BackupRejectedException>().having((e) => e.reason, 'reason', reason),
    );

void main() {
  group('Money (DD-01...DD-04, I-01)', () {
    test('canonical storage form is accepted and kept exactly', () {
      for (final text in ['0', '1', '-1', '999999999999999999',
          '-999999999999999999', '120000']) {
        expect(Money.fromStorage(text, irr).toStorage(), text);
      }
      expect(Money.fromStorage('999999999999999999', irr).minor, max);
    });

    test('non-canonical or too long text is rejected (DD-02, NM-06)', () {
      for (final text in ['', '00', '01', '-0', '+1', ' 1', '1 ', '1e5',
          '1.0', '1,000', '\u06f1', '1000000000000000000', '--1']) {
        expect(() => Money.fromStorage(text, irr), throwsFormatException,
            reason: text);
      }
      expect(() => Money(max + BigInt.one, irr), throwsRangeError);
      expect(() => Money(-max - BigInt.one, irr), throwsRangeError);
    });

    test('domain sums are exact BigInt and same-currency only (DD-03/04)', () {
      final a = Money(max - BigInt.one, irr);
      expect((a + Money(BigInt.one, irr)).minor, max);
      expect(() => a + Money(BigInt.two, irr), throwsRangeError);
      expect(
        () => Money(BigInt.one, irr) + Money(BigInt.one, CurrencyCode.usd),
        throwsArgumentError,
      );
      expect(Money(BigInt.one, irr), Money.fromStorage('1', irr));
      expect(Money(BigInt.one, irr) == Money(BigInt.one, CurrencyCode.usd),
          isFalse);
    });
  });

  group('Formatter (MN-02, NM-01...NM-03, NM-05)', () {
    test('the 18-digit maximum and 1 format exactly', () {
      final m = Money(max, irr);
      final one = Money(BigInt.one, irr);
      expect(rialLatin.formatNumber(m), '999,999,999,999,999,999');
      expect(tomanLatin.formatNumber(m), '99,999,999,999,999,999.9');
      expect(rialFa.formatNumber(m), fa('999,999,999,999,999,999'));
      expect(tomanFa.formatNumber(m), fa('99,999,999,999,999,999.9'));
      expect(rialLatin.formatNumber(one), '1');
      expect(tomanLatin.formatNumber(one), '0.1');
      expect(tomanFa.formatNumber(one), '\u06f0\u066b\u06f1');
    });

    test('toman shows a fraction only when rial is not a multiple of 10', () {
      expect(tomanLatin.formatNumber(Money(BigInt.from(10), irr)), '1');
      expect(tomanLatin.formatNumber(Money(BigInt.from(125), irr)), '12.5');
      expect(tomanLatin.formatNumber(Money(BigInt.zero, irr)), '0');
      expect(rialLatin.formatNumber(Money(BigInt.from(1000), irr)), '1,000');
      expect(rialLatin.formatNumber(Money(BigInt.from(999), irr)), '999');
    });

    test('negative values use LRM + U+2212, never a hyphen (NM-02/03)', () {
      final m = Money(-max, irr);
      expect(rialLatin.formatNumber(m), '\u200e\u2212999,999,999,999,999,999');
      expect(rialFa.formatNumber(m),
          '\u200e\u2212${fa('999,999,999,999,999,999')}');
      expect(rialFa.formatNumber(m), isNot(contains('-')));
    });

    test('two-digit currencies keep their minor digits (spike assumption)', () {
      const usd = CurrencyCode.usd;
      expect(rialLatin.formatNumber(Money(BigInt.from(123456), usd)), '1,234.56');
      expect(rialLatin.formatNumber(Money(BigInt.from(5), usd)), '0.05');
    });

    test('format then parse returns the same amount (SP-02 format step)', () {
      final values = [max, -max, BigInt.one, BigInt.zero, BigInt.from(125),
          BigInt.parse('100000000000000000')];
      for (final f in [rialLatin, tomanLatin, rialFa, tomanFa]) {
        for (final v in values) {
          final m = Money(v, irr);
          expect(f.parseNumber(f.formatNumber(m), irr), m,
              reason: '${f.digits} ${f.rialUnit} $v');
        }
      }
    });

    test('input accepts Persian, Arabic and Latin digits (NM-05)', () {
      // 12,345 with Arabic-Indic digits and a Persian group separator.
      expect(rialFa.parseNumber('\u0661\u0662\u066c\u0663\u0664\u0665', irr),
          Money(BigInt.from(12345), irr));
      expect(rialFa.parseNumber('1\u200c234\u00a0567', irr),
          Money(BigInt.from(1234567), irr));
      expect(tomanFa.parseNumber('12/5', irr), Money(BigInt.from(125), irr));
      expect(() => tomanFa.parseNumber('12.55', irr), throwsFormatException);
      expect(() => rialFa.parseNumber('', irr), throwsFormatException);
      expect(() => rialFa.parseNumber('12a', irr), throwsFormatException);
      expect(() => rialFa.parseNumber('1234567890123456789', irr),
          throwsRangeError);
    });
  });

  group('SHA-256 (FIPS 180-4 vectors)', () {
    const vectors = {
      '': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      'abc': 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq':
          '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
    };
    test('NIST short vectors', () {
      vectors.forEach((input, digest) {
        expect(sha256OfString(input), digest, reason: input);
      });
    });
    test('padding edges 55, 56 and 64 bytes', () {
      expect(sha256OfString('a' * 55),
          '9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318');
      expect(sha256OfString('a' * 56),
          'b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a');
      expect(sha256OfString('a' * 64),
          'ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb');
    });
    test('one million "a" and UTF-8 Persian text', () {
      expect(sha256OfString('a' * 1000000),
          'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
      expect(sha256OfString(wallet),
          '9de518e6c380f0c027ee0024f8113c3718878bd360b46a00acde99aee05de263');
    });
  });

  group('Canonical JSON and backup checksum (BACKUP_RESTORE, I-09)', () {
    test('sorted keys, no whitespace, Persian and ZWNJ kept as is', () {
      expect(canonicalJson({'b': 1, 'a': [true, null, 'x'], 'c': {'z': '', 'y': 'q'}}),
          '{"a":[true,null,"x"],"b":1,"c":{"y":"q","z":""}}');
      expect(canonicalJson(wallet), '"$wallet"');
      expect(() => canonicalJson({'a': 1.5}), throwsArgumentError);
    });

    test('checksum equals an independent Python reference', () {
      // python3: json.dumps(body, sort_keys=True, separators=(",", ":"),
      // ensure_ascii=False) then sha256, on the same sample (spike README).
      final doc = sampleBackup();
      expect(doc['checksum'],
          '2812cb5b6d9f8a6bf3d5df043818a922c5bccbfe937c3ed23fa9a181f153e98f');
      final text = canonicalJson(doc);
      expect(text.length, 1292);
      expect(sha256OfString(text),
          '891cf11da79c1a3d51d8798d44c2e971ed157b30960e44a5dbe999686e5e2226');
      expect(text, contains('"amount_minor":"999999999999999999"'));
      expect(text, isNot(contains(':999999999999999999')));
    });

    test('a valid file validates and keeps every amount exact', () {
      final ok = validateBackup(canonicalJson(sampleBackup()), supportedSchema: 2);
      expect(ok.accounts.single['opening_balance_minor'], '-999999999999999999');
      expect(
        Money.fromStorage(ok.transactions.first['amount_minor']! as String, irr),
        Money(max, irr),
      );
    });
  });

  group('Backup rejections change nothing (I-10, BACKUP_RESTORE \u00a72)', () {
    String valid() => canonicalJson(sampleBackup());
    ValidatedBackup check(String text) =>
        validateBackup(text, supportedSchema: 2);

    test('malformed and truncated files', () {
      expect(() => check('not json'), rejectedWith(BackupRejection.malformed));
      final text = valid();
      expect(() => check(text.substring(0, text.length - 10)),
          rejectedWith(BackupRejection.malformed));
      expect(() => check('[1]'), rejectedWith(BackupRejection.malformed));
    });

    test('unknown format and newer schema (MG-03)', () {
      final doc = decode(valid())..['format'] = 'other';
      expect(() => check(reseal(doc)), rejectedWith(BackupRejection.unknownFormat));
      final newer = decode(valid())..['schema_version'] = 3;
      expect(() => check(reseal(newer)), rejectedWith(BackupRejection.newerSchema));
    });

    test('one changed digit breaks the checksum', () {
      final text = valid().replaceFirst(
          '"amount_minor":"999999999999999999"', '"amount_minor":"999999999999999998"');
      expect(() => check(text), rejectedWith(BackupRejection.checksumMismatch));
    });

    test('money as a JSON number is rejected even when resealed (RKX-01)', () {
      final doc = decode(valid());
      final txs = (doc['transactions']! as List<Object?>).cast<Map<String, Object?>>();
      txs[1]['amount_minor'] = 1;
      expect(() => check(reseal(doc)), rejectedWith(BackupRejection.badAmount));
    });

    test('counts, references and currencies are checked (DD-04)', () {
      final counts = decode(valid());
      (counts['counts']! as Map<String, Object?>)['transactions'] = 3;
      expect(() => check(reseal(counts)), rejectedWith(BackupRejection.countMismatch));

      final ref = decode(valid());
      ((ref['transactions']! as List<Object?>).first! as Map<String, Object?>)
          ['account_id'] = 'missing';
      expect(() => check(reseal(ref)), rejectedWith(BackupRejection.badReference));

      final cur = decode(valid());
      ((cur['transactions']! as List<Object?>).first! as Map<String, Object?>)
          ['currency'] = 'USD';
      expect(() => check(reseal(cur)), rejectedWith(BackupRejection.currencyMismatch));

      final extra = decode(valid());
      ((extra['accounts']! as List<Object?>).first! as Map<String, Object?>)
          ['balance'] = '1';
      expect(() => check(reseal(extra)), rejectedWith(BackupRejection.badField));
    });
  });

  test('RKX-01: a JSON number loses the 18-digit value on the web, a string '
      'never does', () {
    final asNumber = decode('{"a":999999999999999999}')['a'];
    final asString = decode('{"a":"999999999999999999"}')['a']! as String;
    expect(BigInt.parse(asString), max);
    if (kIsWeb) {
      expect('$asNumber', isNot('999999999999999999'));
    } else {
      expect('$asNumber', '999999999999999999');
    }
  });
}
