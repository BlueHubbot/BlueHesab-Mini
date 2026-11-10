// T-025: the Persian text of `app_fixtures` (DS-02, tables 10-2-alef to
// 10-2-te, W-05, W-07; SE-09 Mehr rows; SE-15). The texts are checked
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

/// The SE-09 entry of the errata register (proposed Mehr rows).
String _se09() {
  final String errata =
      File('docs/design/SPEC_ERRATA.md').readAsStringSync();
  final int start = errata.indexOf('### SE-09');
  expect(start, greaterThanOrEqualTo(0), reason: 'SE-09 entry');
  return errata.substring(start, errata.indexOf('\n### ', start + 1));
}

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
    test('every text except the Mehr titles occurs in §10-2 inside «»', () {
      final String section = _section102();
      const Set<String> mehr = <String>{
        'transactions.weekly_supermarket_mehr',
        'transactions.gas_bill_mehr',
        'transactions.gasoline_mehr',
      };
      _allTexts().forEach((String label, String text) {
        if (mehr.contains(label)) {
          return;
        }
        // Table cells are quoted «…» or stand alone between `|`, `،`, `؛`
        // or the start of a parenthesis.
        final bool quoted = section.contains('«$text»');
        final bool cell = RegExp('[|،؛] ?${RegExp.escape(text)} ?[|،؛(]')
            .hasMatch(section);
        expect(quoted || cell, isTrue, reason: '$label = $text');
      });
    });

    test('the Mehr titles occur in the SE-09 proposed rows', () {
      final String se09 = _se09();
      for (final String key in <String>[
        'weekly_supermarket_mehr',
        'gas_bill_mehr',
        'gasoline_mehr',
      ]) {
        final String text = FixtureTextFa.transactions[key]!;
        expect(se09, contains('· $text ·'), reason: key);
      }
    });
  });
}
