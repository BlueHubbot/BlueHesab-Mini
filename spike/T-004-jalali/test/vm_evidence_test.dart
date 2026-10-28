// VM-only checks of the T-004 spike: the ICU fixture (AC3), the single
// import of package:shamsi_date (AC4, DT-05) and the CI evidence lines.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spike_jalali/spike_jalali.dart';

import 'support.dart';

/// Rows of test/fixtures/icu_nowruz.csv (tool/make_icu_fixture.js).
final List<({int year, GregorianDate nowruz, int days})> icuRows = () {
  final List<({int year, GregorianDate nowruz, int days})> rows =
      <({int year, GregorianDate nowruz, int days})>[];
  for (final String line
      in File('test/fixtures/icu_nowruz.csv').readAsLinesSync()) {
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final List<String> f = line.split(',');
    rows.add((
      year: int.parse(f[0]),
      nowruz: GregorianDate.parseIso(f[1]),
      days: int.parse(f[2]),
    ));
  }
  return rows;
}();

/// Jalali years where ICU and the 33-year arithmetic disagree on the year
/// length inside the fixture range (README finding F3). Both implementations
/// must still agree with each other there.
const Set<int> knownIcuDivergence = <int>{1502};

void main() {
  test('ICU fixture: Nowruz and year length per Jalali year', () {
    expect(icuRows.first.year, 1279);
    expect(icuRows.last.year, 1502);
    for (final JalaliCalendarPort cal in calendars) {
      for (final row in icuRows) {
        expect(
          cal.toGregorian(JalaliDate(row.year, 1, 1)),
          row.nowruz,
          reason: '${cal.name} Nowruz ${row.year}',
        );
        final int days = cal.isLeapYear(row.year) ? 366 : 365;
        if (!knownIcuDivergence.contains(row.year)) {
          expect(days, row.days, reason: '${cal.name} length ${row.year}');
        }
      }
    }
  });

  test('in-house arithmetic differs from ICU on the length of 1502 (F3)', () {
    final row = icuRows.firstWhere((r) => r.year == 1502);
    expect(row.days, 365);
    expect(const ReferenceCalendar().isLeapYear(1502), isTrue);
  });

  test('package:shamsi_date is imported by exactly one file (DT-05)', () {
    final List<String> importers = <String>[
      for (final FileSystemEntity e
          in Directory('lib').listSync(recursive: true))
        if (e is File &&
            e.path.endsWith('.dart') &&
            e.readAsStringSync().contains('package:shamsi_date/'))
          e.path.replaceAll(r'\', '/'),
    ];
    expect(importers, <String>['lib/src/shamsi_date_adapter.dart']);
  });

  test('evidence for the CI summary', () {
    final ({int days, List<String> problems}) r = crossCheck();
    const ShamsiDateCalendar lib = ShamsiDateCalendar();
    final String probe = lib.rawAddMonthsProbe(const JalaliDate(1405, 6, 31), 1);
    const ReferenceCalendar ref = ReferenceCalendar();
    final String beyond = <String>[
      for (final GregorianDate g in const <GregorianDate>[
        GregorianDate(2124, 3, 20),
        GregorianDate(2124, 3, 21),
      ])
        '$g=${lib.toJalali(g)}/${ref.toJalali(g)}',
    ].join(' ');
    recordEvidence(
      'SPIKE_EVIDENCE T-004 os=${Platform.operatingSystem} '
      'dart=${Platform.version.split(' ').first} '
      'days=${r.days} problems=${r.problems.length} '
      'icu_years=${icuRows.length} '
      'shamsi_addMonths(1405/06/31,+1)=$probe '
      'beyond_fixture(lib/in-house)=$beyond',
    );
    expect(r.problems, isEmpty);
  });
}
