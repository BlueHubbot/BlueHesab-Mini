// T-004 AC2: both implementations agree on every day of 1900-01-01 …
// 2123-12-31, round-trip, and give the same weekday. Platform-neutral.
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_jalali/spike_jalali.dart';

import 'support.dart';

void main() {
  test('every day 1900-01-01 … 2123-12-31: same date, round trip, weekday', () {
    final ({int days, List<String> problems}) r = crossCheck();
    expect(r.problems, isEmpty);
    expect(r.days, 81814);
  });

  test('leap years and Esfand length agree for 1279 … 1502', () {
    for (int y = 1279; y <= 1502; y++) {
      expect(calendars[0].isLeapYear(y), calendars[1].isLeapYear(y), reason: '$y');
      expect(
        calendars[0].monthLength(y, 12),
        calendars[1].monthLength(y, 12),
        reason: '$y',
      );
    }
  });

  test('DT-01: storage form is Gregorian yyyy-MM-dd and round-trips', () {
    const GregorianDate d = GregorianDate(2026, 10, 24);
    expect(d.toIso(), '2026-10-24');
    expect(GregorianDate.parseIso('2026-10-24'), d);
    expect(GregorianDate.parseIso('2024-02-29'), const GregorianDate(2024, 2, 29));
    for (final String bad in <String>[
      '2025-02-29',
      '1405/08/02',
      '2026-1-24',
      '2026-10-24T00:00:00Z',
      '',
    ]) {
      expect(() => GregorianDate.parseIso(bad), throwsFormatException, reason: bad);
    }
  });
}
