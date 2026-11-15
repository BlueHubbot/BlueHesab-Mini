// T-025: the Persian text of `app_fixtures` (DS-02, tables 10-2-alef to
// 10-2-te, W-05, W-07; SE-15). The texts are checked
// against the spec files themselves, so a typed variant fails.

import 'dart:io';

import 'package:bluehesab_mini/fixtures/app_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';

final RegExp _persianScript = RegExp('[؀-ۿ]');

/// Section 10-2 of the spec: from its heading to the next `###` heading.
String _section102() {
  final String spec =
      File('docs/design/ui-spec/10-style-guide-and-fixtures.md')
          .readAsStringSync();
  final int start = spec.indexOf('### ۱۰-۲');
  final int end = spec.indexOf('### ۱۰-۳');
  expect(start, greaterThanOrEqualTo(0), reason: 'heading of §10-2');
  expect(end, greaterThan(start), reason: 'heading of §10-3');
  return spec.substring(start, end);
}

/// Caption of table 10-2-be2 (Mehr 1405 rows, T-027) inside §10-2.
const String _tableBe2Caption = 'جدول ۱۰-۲-ب۲:';

/// The text of [section] from the table 10-2-be2 caption to the end.
String _fromTableBe2(String section) {
  final int start = section.indexOf(_tableBe2Caption);
  expect(start, greaterThanOrEqualTo(0), reason: 'caption of table 10-2-be2');
  return section.substring(start);
}

/// Data rows of table 10-2-be2 as trimmed cells (header and rule dropped).
List<List<String>> _tableBe2Rows(String section) {
  final List<List<String>> rows = <List<String>>[];
  bool inTable = false;
  for (final String line in _fromTableBe2(section).split('\n').skip(1)) {
    if (line.startsWith('|')) {
      inTable = true;
      final List<String> cells = line.split('|');
      rows.add(cells
          .sublist(1, cells.length - 1)
          .map((String c) => c.trim())
          .toList());
    } else if (inTable) {
      break;
    }
  }
  expect(rows.length, greaterThanOrEqualTo(2), reason: 'header and rule');
  return rows.sublist(2);
}

/// A number written with Persian digits and the Arabic thousands separator
/// (U+066C), as in the §10-2 tables; never parsed through `double`.
BigInt _faNumber(String text) {
  final StringBuffer ascii = StringBuffer();
  for (final int unit in text.codeUnits) {
    if (unit >= 0x06F0 && unit <= 0x06F9) {
      ascii.writeCharCode(0x30 + unit - 0x06F0);
    } else if (unit != 0x066C) {
      fail('not a Persian number: $text');
    }
  }
  return BigInt.parse(ascii.toString());
}

/// The fixture transaction whose title text is [title].
FixtureTransaction _byTitle(Iterable<FixtureTransaction> rows, String title) =>
    rows.singleWhere(
        (FixtureTransaction t) => FixtureTextFa.transactions[t.key] == title);

/// Every text of [FixtureTextFa] with a label for failure messages.
Map<String, String> _allTexts() => <String, String>{
      for (final MapEntry<String, Map<String, String>> g
          in <String, Map<String, String>>{
        'accounts': FixtureTextFa.accounts,
        'transactions': FixtureTextFa.transactions,
        'categories': FixtureTextFa.categories,
        'arcLabels': FixtureTextFa.arcLabels,
        'arcValueTexts': FixtureTextFa.arcValueTexts,
        'upcoming': FixtureTextFa.upcoming,
        'habits': FixtureTextFa.habits,
        'market': FixtureTextFa.market,
        'carReminders': FixtureTextFa.carReminders,
        'tasks': FixtureTextFa.tasks,
      }.entries)
        for (final MapEntry<String, String> e in g.value.entries)
          '${g.key}.${e.key}': e.value,
      'ringSemantics': FixtureTextFa.ringSemantics,
      'monthSpendingComparison': FixtureTextFa.monthSpendingComparison,
      'w05Title': FixtureTextFa.w05Title,
      'w07Category': FixtureTextFa.w07Category,
      'w07CategorySubtitle': FixtureTextFa.w07CategorySubtitle,
      'w07Account': FixtureTextFa.w07Account,
      'w07Range': FixtureTextFa.w07Range,
    };

void main() {
  group('every key of normal has exactly one text (DS-02)', () {
    final FixtureSet n = normalSet;

    test('accounts', () {
      expect(FixtureTextFa.accounts.keys.toList(),
          n.accounts.map((FixtureAccount a) => a.key).toList());
    });

    test('transactions and the coffee draft', () {
      expect(FixtureTextFa.transactions.keys.toSet(), <String>{
        for (final FixtureTransaction t in n.transactions) t.key,
        n.draftTransaction!.key,
      });
    });

    test('categories: 12 expense + income, and every row category', () {
      expect(FixtureTextFa.categories.keys.toList(),
          <String>[...n.expenseCategories, ...n.incomeCategories]);
      for (final FixtureTransaction t in <FixtureTransaction>[
        ...n.transactions,
        n.draftTransaction!,
      ]) {
        expect(FixtureTextFa.categories, contains(t.categoryKey),
            reason: t.key);
        expect(FixtureTextFa.accounts, contains(t.accountKey), reason: t.key);
      }
      expect(n.frequentExpenseCategories.every(n.expenseCategories.contains),
          isTrue);
    });

    test('arcs: one label and one value text each', () {
      final List<String> keys = n.arcs.map((FixtureArc a) => a.key).toList();
      expect(FixtureTextFa.arcLabels.keys.toList(), keys);
      expect(FixtureTextFa.arcValueTexts.keys.toList(), keys);
    });

    test('upcoming, market, car reminders, tasks, habits', () {
      expect(FixtureTextFa.upcoming.keys.toList(),
          n.upcoming.map((FixtureDatedItem i) => i.key).toList());
      expect(FixtureTextFa.market.keys.toList(),
          n.marketWatch.map((FixturePrice p) => p.key).toList());
      expect(FixtureTextFa.carReminders.keys.toList(),
          n.carReminders.map((FixtureDatedItem i) => i.key).toList());
      expect(FixtureTextFa.tasks.keys.toList(),
          <String>[...n.tasks.done, ...n.tasks.open]);
      expect(FixtureTextFa.habits.keys.toList(),
          <String>[...n.habits.done, ...n.habits.open]);
    });
  });

  group('text form', () {
    test('Persian script, trimmed, no double space, no Arabic yeh/kaf', () {
      _allTexts().forEach((String label, String text) {
        expect(_persianScript.hasMatch(text), isTrue, reason: label);
        expect(text, text.trim(), reason: label);
        expect(text, isNot(contains('  ')), reason: label);
        expect(text, isNot(contains('ي')), reason: '$label: U+064A');
        expect(text, isNot(contains('ك')), reason: '$label: U+0643');
      });
    });

    test('W-05 is 43 characters (UTF-16 code units, ZWNJ included)', () {
      expect(FixtureTextFa.w05Title.length, 43);
    });

    test('the ring sentence names each arc label (VI-14)', () {
      for (final String label in FixtureTextFa.arcLabels.values) {
        expect(FixtureTextFa.ringSemantics, contains(label));
      }
    });
  });

  group('texts equal the spec cells', () {
    test('every text occurs in §10-2 as a cell or inside «»', () {
      final String section = _section102();
      _allTexts().forEach((String label, String text) {
        // Table cells are quoted «…» or stand alone between `|`, `،`, `؛`
        // or the start of a parenthesis.
        final bool quoted = section.contains('«$text»');
        final bool cell = RegExp('[|،؛] ?${RegExp.escape(text)} ?[|،؛(]')
            .hasMatch(section);
        expect(quoted || cell, isTrue, reason: '$label = $text');
      });
    });
  });

  group('table 10-2-be2 equals the Mehr rows of normal (T-030)', () {
    final Iterable<FixtureTransaction> mehrRows = normalSet.transactions
        .where((FixtureTransaction t) =>
            t.date.jalaliYear == 1405 && t.date.jalaliMonth == 7);

    test('three rows, one per fixture Mehr row, all citing the table', () {
      final List<List<String>> rows = _tableBe2Rows(_section102());
      expect(rows.length, 3);
      expect(mehrRows.length, 3);
      for (final FixtureTransaction t in mehrRows) {
        expect(t.source, startsWith('table 10-2-be2 row '), reason: t.key);
      }
    });

    test('date, title, kind, category, account and amount per row', () {
      final List<List<String>> rows = _tableBe2Rows(_section102());
      for (int i = 0; i < rows.length; i++) {
        final List<String> cells = rows[i];
        expect(cells.length, 6, reason: 'row ${i + 1}');
        final FixtureTransaction t = _byTitle(mehrRows, cells[1]);
        expect(t.source, startsWith('table 10-2-be2 row ${i + 1}'),
            reason: t.key);
        final List<String> date = cells[0].split(' ');
        expect(date.length, 2, reason: cells[0]);
        expect(date[1], 'مهر', reason: cells[0]);
        expect(_faNumber(date[0]), BigInt.from(t.date.jalaliDay),
            reason: t.key);
        expect(t.kind, FixtureKind.expense, reason: t.key);
        expect(cells[2], 'هزینه', reason: t.key);
        expect(cells[3], FixtureTextFa.categories[t.categoryKey],
            reason: t.key);
        expect(cells[4], FixtureTextFa.accounts[t.accountKey], reason: t.key);
        expect(t.amount, FixtureAmount.toman(_faNumber(cells[5]).toString()),
            reason: t.key);
      }
    });

    test('opening balances equal the sentence under the table (DD-06)', () {
      final String after = _fromTableBe2(_section102());
      for (final FixtureAccount a in normalSet.accounts) {
        final String name = FixtureTextFa.accounts[a.key]!;
        final Match? m =
            RegExp('${RegExp.escape(name)} ([۰-۹٬]+)').firstMatch(after);
        expect(m, isNotNull, reason: a.key);
        final BigInt toman = _faNumber(m!.group(1)!);
        expect(a.opening, FixtureAmount.toman(toman.toString()),
            reason: a.key);
      }
    });
  });
}
