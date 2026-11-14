// T-028: W-09 charts 2 to 4 and W-12 of the `worst` set, checked against
// the SE-16 interim rule (ADVISOR_REPLY-007 Decision 1-4 and Action 3).
// Dates are checked against an independent derivation from
// 1 Farvardin 1405 = 2026-03-21 (T-004 vectors).

import 'package:bluehesab_mini/fixtures/app_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';

final BigInt _int64Max = BigInt.parse('9223372036854775807');
final BigInt _int64Min = -_int64Max - BigInt.one;
final BigInt _ten = BigInt.from(10);

BigInt _toman(FixtureAmount a) => a.minor ~/ _ten;

void _expectInt64(FixtureAmount a) {
  expect(a.minor <= _int64Max && a.minor >= _int64Min, isTrue,
      reason: '${a.minorText} outside int64 (DS-07)');
}

void main() {
  group('W-09 chart 2 (SE-16 item 1)', () {
    // The twelve values of SE-16, pinned literally so that a drift between
    // the register (or the later spec table) and the code fails here.
    const List<String> se16Values = <String>[
      '-987654321012345',
      '-808080808101010',
      '-628507295189675',
      '-448933782278339',
      '-269360269367004',
      '-89786756455668',
      '89786756455667',
      '269360269367003',
      '448933782278338',
      '628507295189674',
      '808080808101009',
      '987654321012345',
    ];

    test('one series of 12 values equal to the SE-16 list', () {
      expect(WorstSet.w09Chart2, hasLength(1));
      final List<FixtureAmount> series = WorstSet.w09Chart2.single;
      expect(series, hasLength(12));
      for (int m = 0; m < 12; m++) {
        expect(series[m].currency, 'IRR');
        expect(_toman(series[m]).toString(), se16Values[m],
            reason: 'month ${m + 1}');
        expect(se16Chart2Toman(m + 1).toString(), se16Values[m]);
      }
    });

    test('m = 1 is W-02 and m = 12 is W-01', () {
      final List<FixtureAmount> series = WorstSet.w09Chart2.single;
      expect(series.first, WorstSet.w02);
      expect(series.last, WorstSet.w01);
    });

    test('no value is 0; the sign changes only between m = 6 and 7', () {
      final List<FixtureAmount> series = WorstSet.w09Chart2.single;
      expect(series.any((FixtureAmount a) => a.minor == BigInt.zero), isFalse);
      final List<int> changes = <int>[
        for (int m = 1; m < 12; m++)
          if (series[m - 1].minor.isNegative != series[m].minor.isNegative) m,
      ];
      expect(changes, <int>[6]);
    });

    test('strictly increasing, at most 15 digits in toman', () {
      final List<FixtureAmount> series = WorstSet.w09Chart2.single;
      for (int m = 1; m < 12; m++) {
        expect(series[m].minor > series[m - 1].minor, isTrue);
      }
      for (final FixtureAmount a in series) {
        expect(_toman(a).abs().toString().length <= 15, isTrue);
      }
    });

    test('the formula is defined only for months 1..12', () {
      expect(() => se16Chart2Toman(0), throwsRangeError);
      expect(() => se16Chart2Toman(13), throwsRangeError);
    });
  });

  group('W-09 charts 3 and 4 (SE-16 items 2, 3)', () {
    test('chart 3 has the shape of chart 1 and 60 zeros', () {
      expect(WorstSet.w09Chart3, hasLength(WorstSet.w09Chart1.length));
      expect(WorstSet.w09Chart3, hasLength(5));
      int zeros = 0;
      for (final List<FixtureAmount> series in WorstSet.w09Chart3) {
        expect(series, hasLength(12));
        for (final FixtureAmount a in series) {
          expect(a.currency, 'IRR');
          if (a.minor == BigInt.zero) {
            zeros++;
          }
        }
      }
      expect(zeros, 60);
    });

    test('chart 4 is one series with one point equal to W-01', () {
      expect(WorstSet.w09Chart4, hasLength(1));
      expect(WorstSet.w09Chart4.single, hasLength(1));
      expect(WorstSet.w09Chart4.single.single, WorstSet.w01);
    });
  });

  group('W-12 (SE-16 item 4)', () {
    final List<FixtureListRow> rows = WorstSet.w12Rows;
    final DateTime farvardin1 = DateTime.utc(2026, 3, 21);

    test('200 rows with keys w12_000..w12_199 in order', () {
      expect(rows, hasLength(200));
      expect(rows.first.rowKey, 'w12_000');
      expect(rows.last.rowKey, 'w12_199');
      expect(rows.map((FixtureListRow r) => r.rowKey).toSet(), hasLength(200));
      for (int i = 0; i < 200; i++) {
        expect(rows[i].rowKey, 'w12_${i.toString().padLeft(3, '0')}');
      }
    });

    test('even rows: W-05 title and 320 000 toman; odd rows: lunch and W-01',
        () {
      for (int i = 0; i < 200; i++) {
        final FixtureTransaction t = rows[i].transaction;
        if (i.isEven) {
          expect(t.key, WorstSet.w05TitleKey, reason: 'row $i');
          expect(t.amount, FixtureAmount.toman('320000'), reason: 'row $i');
        } else {
          expect(t.key, 'lunch_with_colleagues', reason: 'row $i');
          expect(t.amount, WorstSet.w01, reason: 'row $i');
        }
      }
      expect(
        FixtureTextFa.transactions.containsKey('lunch_with_colleagues'),
        isTrue,
      );
      expect(FixtureTextFa.w05Title, isNotEmpty);
    });

    test('row 1 of table 10-2-be is the same title and amount as even rows',
        () {
      final FixtureTransaction lunch = normalSet.transactions.first;
      expect(lunch.key, 'lunch_with_colleagues');
      expect(lunch.amount, FixtureAmount.toman('320000'));
    });

    test('all rows: expense, food, cash, inside int64', () {
      for (final FixtureListRow r in rows) {
        expect(r.transaction.kind, FixtureKind.expense);
        expect(r.transaction.categoryKey, 'food');
        expect(r.transaction.accountKey, 'cash');
        expect(r.transaction.amount.minor > BigInt.zero, isTrue);
        _expectInt64(r.transaction.amount);
      }
    });

    test('dates: strictly descending, 2 Aban 1405 to 19 Farvardin 1405', () {
      final FixtureDate first = rows.first.transaction.date;
      final FixtureDate last = rows.last.transaction.date;
      expect(
        <int>[first.jalaliYear, first.jalaliMonth, first.jalaliDay],
        <int>[1405, 8, 2],
      );
      expect(first.gregorian, DateTime.utc(2026, 10, 24));
      expect(first.gregorian, FixtureEnvironment.today.gregorian);
      expect(
        <int>[last.jalaliYear, last.jalaliMonth, last.jalaliDay],
        <int>[1405, 1, 19],
      );
      expect(last.gregorian, DateTime.utc(2026, 4, 8));
      for (int i = 1; i < 200; i++) {
        final DateTime prev = rows[i - 1].transaction.date.gregorian;
        final DateTime cur = rows[i].transaction.date.gregorian;
        expect(prev.difference(cur), const Duration(days: 1), reason: 'row $i');
      }
    });

    test('each Jalali day matches its Gregorian day (from 1 Farvardin)', () {
      const List<int> monthLengths1405 = <int>[31, 31, 31, 31, 31, 31, 30, 30];
      for (final FixtureListRow r in rows) {
        final FixtureDate d = r.transaction.date;
        expect(d.jalaliYear, 1405);
        int dayOfYear = d.jalaliDay;
        for (int m = 1; m < d.jalaliMonth; m++) {
          dayOfYear += monthLengths1405[m - 1];
        }
        expect(
          d.gregorian,
          farvardin1.add(Duration(days: dayOfYear - 1)),
          reason: r.rowKey,
        );
        expect(d.jalaliDay <= monthLengths1405[d.jalaliMonth - 1], isTrue);
      }
    });

    test('list-only: not in the normal set totals (DS-03)', () {
      final Set<String> normalKeys = <String>{
        for (final FixtureTransaction t in normalSet.transactions) t.source,
      };
      for (final FixtureListRow r in rows) {
        expect(normalKeys.contains(r.transaction.source), isFalse);
        expect(r.transaction.source, startsWith('SE-16'));
      }
    });

    test('the day helper is defined only for i = 0..199', () {
      expect(() => se16DaysBeforeAban2(-1), throwsRangeError);
      expect(() => se16DaysBeforeAban2(200), throwsRangeError);
    });
  });
}
