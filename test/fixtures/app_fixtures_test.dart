// T-022: the claims of ui-spec §10-2 checked by computation over the rows of
// `app_fixtures` (DS-01, DS-03, DS-06, DS-07; DD-06, DD-11; table
// 10-2-be2; ESC-006 item 2). Totals are derived from the rows, never copied.

import 'dart:io';

import 'package:bluehesab_mini/fixtures/app_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';

final BigInt _int64Max = BigInt.parse('9223372036854775807');
final BigInt _int64Min = -_int64Max - BigInt.one;
final RegExp _canonical = RegExp(r'^-?(0|[1-9][0-9]*)$');

BigInt _sum(Iterable<FixtureAmount> amounts) =>
    amounts.fold(BigInt.zero, (BigInt a, FixtureAmount b) => a + b.minor);

BigInt _toman(String text) => BigInt.parse(text) * BigInt.from(10);

/// DD-11 integer percentage: sign × (2·|Δ|·100 + prev) ÷ (2·prev).
BigInt _dd11Percent(BigInt current, BigInt previous) {
  final BigInt delta = current - previous;
  final BigInt magnitude =
      (BigInt.two * delta.abs() * BigInt.from(100) + previous) ~/
          (BigInt.two * previous);
  return delta.isNegative ? -magnitude : magnitude;
}

/// Every amount reachable from a set, for DS-07.
List<FixtureAmount> _amountsOf(FixtureSet s) => <FixtureAmount>[
      for (final FixtureAccount a in s.accounts) ...<FixtureAmount>[
        a.opening,
        a.displayedBalance,
      ],
      for (final FixtureTransaction t in s.transactions) t.amount,
      if (s.draftTransaction != null) s.draftTransaction!.amount,
      if (s.monthlyBudget != null) s.monthlyBudget!,
      for (final FixtureDatedItem i in s.upcoming)
        if (i.amount != null) i.amount!,
      for (final FixturePrice p in s.marketWatch) p.price,
    ];

List<FixtureAmount> _worstAmounts() => <FixtureAmount>[
      WorstSet.w01,
      WorstSet.w02,
      WorstSet.w03,
      WorstSet.w04,
      ...WorstSet.w06FiveCurrencies,
      for (final List<FixtureAmount> series in WorstSet.w09Chart1) ...series,
      ...WorstSet.w11Column,
    ];

/// Groups an unsigned digit string by thousands with ',' (test-only helper;
/// the product formatter is not under test here).
String _group(String digits) {
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(',');
    }
    out.write(digits[i]);
  }
  return out.toString();
}

void main() {
  group('DS-01 environment', () {
    test('2 Aban 1405 10:00 Tehran is 06:30 UTC on Saturday 2026-10-24', () {
      final DateTime local = FixtureEnvironment.instantUtc
          .add(const Duration(minutes: FixtureEnvironment.utcOffsetMinutes));
      expect(local.hour, FixtureEnvironment.localHour);
      expect(local.minute, FixtureEnvironment.localMinute);
      expect(local.weekday, DateTime.saturday);
      expect(
        DateTime.utc(local.year, local.month, local.day),
        FixtureEnvironment.today.gregorian,
      );
      expect(FixtureEnvironment.today.jalaliMonth, 8);
      expect(FixtureEnvironment.today.jalaliDay, 2);
    });

    test('four reference viewports', () {
      expect(
        FixtureEnvironment.viewports
            .map((FixtureViewport v) => '${v.name} ${v.width}x${v.height}')
            .toList(),
        <String>[
          'compact 360x640',
          'medium 768x1024',
          'expanded 1024x768',
          'large 1440x900',
        ],
      );
    });
  });

  group('normal set (DS-03)', () {
    final FixtureSet fx = normalSet;
    final FixtureStatedTotals stated = fx.statedTotals!;
    bool isAban(FixtureTransaction t) =>
        t.date.jalaliYear == 1405 && t.date.jalaliMonth == 8;
    final List<FixtureTransaction> aban = fx.transactions.where(isAban).toList();

    test('table sizes and order (DS-07)', () {
      expect(fx.accounts.map((FixtureAccount a) => a.key),
          <String>['cash', 'bank_melli', 'savings']);
      expect(aban, hasLength(6));
      expect(fx.transactions, hasLength(9));
      expect(
        fx.transactions.take(6).map((FixtureTransaction t) => t.source),
        <String>[for (int i = 1; i <= 6; i++) 'table 10-2-be row $i'],
      );
      expect(fx.expenseCategories, hasLength(12));
      expect(fx.expenseCategories.toSet(), hasLength(12));
      expect(fx.frequentExpenseCategories, hasLength(5));
      expect(
        fx.frequentExpenseCategories.every(fx.expenseCategories.contains),
        isTrue,
      );
      expect(fx.tasks.total, 6);
      expect(fx.tasks.done, hasLength(4));
      expect(fx.habits.total, 5);
      expect(fx.habits.done, hasLength(2));
      expect(fx.upcoming, hasLength(3));
      expect(fx.marketWatch, hasLength(3));
      expect(fx.carReminders, hasLength(2));
    });

    test('every row points at a known account and category', () {
      final Set<String> accounts =
          fx.accounts.map((FixtureAccount a) => a.key).toSet();
      for (final FixtureTransaction t in <FixtureTransaction>[
        ...fx.transactions,
        fx.draftTransaction!,
      ]) {
        expect(accounts, contains(t.accountKey), reason: t.key);
        expect(
          t.kind == FixtureKind.expense
              ? fx.expenseCategories
              : fx.incomeCategories,
          contains(t.categoryKey),
          reason: t.key,
        );
        expect(t.amount.minor > BigInt.zero, isTrue, reason: t.key);
      }
    });

    test('total balance = sum of the three accounts', () {
      expect(
        _sum(fx.accounts.map((FixtureAccount a) => a.displayedBalance)),
        stated.totalBalance.minor,
      );
      expect(stated.totalBalance.minor, _toman('40250000'));
    });

    test('month expense = sum of the five Aban expenses; coffee excluded', () {
      final List<FixtureTransaction> expenses = aban
          .where((FixtureTransaction t) => t.kind == FixtureKind.expense)
          .toList();
      expect(expenses, hasLength(5));
      expect(
        _sum(expenses.map((FixtureTransaction t) => t.amount)),
        stated.monthExpense.minor,
      );
      expect(fx.transactions.map((FixtureTransaction t) => t.key),
          isNot(contains('coffee')));
      expect(fx.draftTransaction!.key, 'coffee');
    });

    test('month income = the Aban salary row', () {
      expect(
        _sum(aban
            .where((FixtureTransaction t) => t.kind == FixtureKind.income)
            .map((FixtureTransaction t) => t.amount)),
        stated.monthIncome.minor,
      );
    });

    test('budget 5,500,000 with 1,760,000 spent leaves 68 % = budget arc', () {
      expect(fx.monthlyBudget, stated.monthBudget);
      final BigInt budget = fx.monthlyBudget!.minor;
      final BigInt left = budget - stated.monthExpense.minor;
      final FixtureArc arc =
          fx.arcs.firstWhere((FixtureArc a) => a.key == 'budget');
      expect(left * BigInt.from(arc.fraction.denominator),
          budget * BigInt.from(arc.fraction.numerator));
    });

    test('task and habit arcs = done / total', () {
      FixtureRatio arc(String key) =>
          fx.arcs.firstWhere((FixtureArc a) => a.key == key).fraction;
      expect(
        arc('tasks')
            .sameValueAs(FixtureRatio(fx.tasks.done.length, fx.tasks.total)),
        isTrue,
      );
      expect(
        arc('habits').sameValueAs(
            FixtureRatio(fx.habits.done.length, fx.habits.total)),
        isTrue,
      );
    });

    test('DD-06: opening + income - expense = displayed balance (10-2-be2)', () {
      for (final FixtureAccount a in fx.accounts) {
        BigInt balance = a.opening.minor;
        for (final FixtureTransaction t in fx.transactions) {
          if (t.accountKey != a.key) {
            continue;
          }
          balance += t.kind == FixtureKind.income ? t.amount.minor : -t.amount.minor;
        }
        expect(balance, a.displayedBalance.minor, reason: a.key);
        expect(a.opening.minor >= BigInt.zero, isTrue, reason: a.key);
      }
    });

    test('DD-11 + 10-2-be2: same-period Mehr = 2,000,000, 15 Mehr excluded, 12 %',
        () {
      final int elapsed = FixtureEnvironment.today.jalaliDay;
      BigInt expenseIn(int month) => _sum(fx.transactions
          .where((FixtureTransaction t) =>
              t.kind == FixtureKind.expense &&
              t.date.jalaliYear == 1405 &&
              t.date.jalaliMonth == month &&
              t.date.jalaliDay <= elapsed)
          .map((FixtureTransaction t) => t.amount));
      final BigInt current = expenseIn(8);
      final BigInt previous = expenseIn(7);
      expect(current, stated.monthExpense.minor);
      expect(previous, stated.previousSamePeriodExpense.minor);
      expect(
        fx.transactions.any((FixtureTransaction t) =>
            t.date.jalaliMonth == 7 && t.date.jalaliDay > elapsed),
        isTrue,
        reason: 'a Mehr row outside the period proves the exclusion',
      );
      expect(_dd11Percent(current, previous),
          BigInt.from(-stated.comparisonPercentLess));
    });

    test('Jalali and Gregorian days agree (1 Aban 1405 = 2026-10-23, Mehr 30 days)',
        () {
      final DateTime aban1 = DateTime.utc(2026, 10, 23);
      final List<FixtureDate> dates = <FixtureDate>[
        for (final FixtureTransaction t in fx.transactions) t.date,
        fx.draftTransaction!.date,
        for (final FixtureDatedItem i in fx.upcoming) i.date,
        for (final FixtureDatedItem i in fx.carReminders) i.date,
        FixtureEnvironment.today,
      ];
      for (final FixtureDate d in dates) {
        expect(d.jalaliYear, 1405);
        final int offset = d.jalaliMonth == 8
            ? d.jalaliDay - 1
            : d.jalaliMonth == 7
                ? d.jalaliDay - 31
                : throw StateError('unexpected month ${d.jalaliMonth}');
        expect(d.gregorian, aban1.add(Duration(days: offset)),
            reason: '${d.jalaliMonth}/${d.jalaliDay}');
      }
    });
  });

  group('worst set (DS-04, table 10-2-te)', () {
    test('W-01 / W-02: 15-digit toman and its negative', () {
      expect(WorstSet.w01.minorText, '9876543210123450');
      expect((WorstSet.w01.minor ~/ BigInt.from(10)).toString(), hasLength(15));
      expect(WorstSet.w02.minor, -WorstSet.w01.minor);
    });

    test('W-03 shows as 24 characters with two decimals', () {
      final String digits = WorstSet.w03.minorText;
      final String shown =
          '${_group(digits.substring(0, digits.length - 2))}.${digits.substring(digits.length - 2)}';
      expect(shown, '1,234,567,890,123,456.78');
      expect(shown, hasLength(24));
      expect(WorstSet.w03.currency, 'USD');
    });

    test('W-04 is an 18-digit rial amount', () {
      expect(WorstSet.w04.currency, 'IRR');
      expect(WorstSet.w04.minorText, hasLength(18));
    });

    test('W-06: three and five currencies, all different', () {
      expect(
        WorstSet.w06ThreeCurrencies.map((FixtureAmount a) => a.currency),
        <String>['IRR', 'USD', 'EUR'],
      );
      expect(
        WorstSet.w06FiveCurrencies.map((FixtureAmount a) => a.currency).toSet(),
        hasLength(5),
      );
    });

    test('DS-06: 60 values, each 15 digits in toman, minor = 10 x toman', () {
      expect(WorstSet.w09Chart1, hasLength(5));
      for (int s = 0; s < 5; s++) {
        expect(WorstSet.w09Chart1[s], hasLength(12));
        for (int m = 0; m < 12; m++) {
          final FixtureAmount v = WorstSet.w09Chart1[s][m];
          final BigInt toman = ds06Toman(s + 1, m + 1);
          expect(toman.toString(), hasLength(15));
          expect(v.minor, toman * BigInt.from(10));
          expect(v.currency, 'IRR');
        }
      }
    });

    test('ESC-006 item 2: the DS-06 series overlap in range but never cross',
        () {
      // Records the fact behind ESC-006; if the formula changes, this test
      // must change with the erratum.
      for (int a = 1; a <= 5; a++) {
        for (int b = a + 1; b <= 5; b++) {
          final bool crosses = <int>[for (int m = 1; m <= 12; m++) m]
              .any((int m) => ds06Toman(a, m) > ds06Toman(b, m));
          expect(crosses, isFalse, reason: 'series $a vs $b');
        }
      }
      final BigInt max1 = <BigInt>[
        for (int m = 1; m <= 12; m++) ds06Toman(1, m)
      ].reduce((BigInt x, BigInt y) => x > y ? x : y);
      final BigInt min2 = <BigInt>[
        for (int m = 1; m <= 12; m++) ds06Toman(2, m)
      ].reduce((BigInt x, BigInt y) => x < y ? x : y);
      expect(max1 > min2, isTrue, reason: 'ranges of series 1 and 2 overlap');
    });

    test('W-11 column and changes', () {
      expect(
        WorstSet.w11Column.map((FixtureAmount a) => a.minor ~/ BigInt.from(10)),
        <BigInt>[
          BigInt.zero,
          BigInt.from(12),
          BigInt.from(1234),
          BigInt.from(123456),
          WorstSet.w01.minor ~/ BigInt.from(10),
          WorstSet.w02.minor ~/ BigInt.from(10),
        ],
      );
      expect(WorstSet.w11Changes, hasLength(4));
      expect(
        WorstSet.w11Changes[0].sameValueAs(const FixtureRatio(1, 8)),
        isTrue,
      );
    });

    test('W-08 Latin parts', () {
      expect(WorstSet.w08AccountName, 'Wise EUR');
      expect(WorstSet.w08Email, endsWith('@example.com'));
    });
  });

  test('empty set: no account, transaction or arc (DS-02)', () {
    expect(emptySet.accounts, isEmpty);
    expect(emptySet.transactions, isEmpty);
    expect(emptySet.arcs, isEmpty);
    expect(emptySet.draftTransaction, isNull);
    expect(emptySet.statedTotals, isNull);
  });

  group('DS-07 consistency', () {
    final List<FixtureAmount> all = <FixtureAmount>[
      ..._amountsOf(normalSet),
      ..._amountsOf(emptySet),
      normalSet.statedTotals!.totalBalance,
      normalSet.statedTotals!.monthIncome,
      normalSet.statedTotals!.monthExpense,
      normalSet.statedTotals!.monthBudget,
      normalSet.statedTotals!.previousSamePeriodExpense,
      ..._worstAmounts(),
    ];

    test('every amount fits int64, is canonical text and has a known currency',
        () {
      expect(all.length, greaterThan(90));
      for (final FixtureAmount a in all) {
        expect(a.minor <= _int64Max && a.minor >= _int64Min, isTrue,
            reason: '$a');
        expect(_canonical.hasMatch(a.minorText), isTrue, reason: '$a');
        expect(fixtureMinorDigits.containsKey(a.currency), isTrue,
            reason: '$a');
      }
    });

    test('no double in lib/fixtures (MN-01)', () {
      final List<File> files = Directory('lib/fixtures')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .toList();
      expect(files, isNotEmpty);
      final RegExp doubleWord = RegExp(r'\b(?:double|num)\b|\.toDouble\(');
      for (final File f in files) {
        final List<String> code = f
            .readAsLinesSync()
            .where((String l) => !l.trimLeft().startsWith('//'))
            .toList();
        expect(code.where(doubleWord.hasMatch), isEmpty, reason: f.path);
      }
    });

    test('no Flutter import in lib/fixtures (pure Dart)', () {
      for (final FileSystemEntity f
          in Directory('lib/fixtures').listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          expect(f.readAsStringSync(), isNot(contains('package:flutter')),
              reason: f.path);
        }
      }
    });
  });
}
