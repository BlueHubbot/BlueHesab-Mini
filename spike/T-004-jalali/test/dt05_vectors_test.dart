// DT-05 vectors (docs/design/ui-spec/03-typography-rtl.md §3-5, "verified
// with ICU"), run against both implementations of the port (SP-04).
// Platform-neutral: runs on the VM and in Chrome.
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_jalali/spike_jalali.dart';

import 'support.dart';

// Gregorian ↔ Jalali conversion vectors of DT-05, in spec order.
const List<(GregorianDate, JalaliDate)> conversions = <(GregorianDate, JalaliDate)>[
  (GregorianDate(2026, 3, 21), JalaliDate(1405, 1, 1)),
  (GregorianDate(2025, 3, 21), JalaliDate(1404, 1, 1)),
  (GregorianDate(2024, 3, 20), JalaliDate(1403, 1, 1)),
  (GregorianDate(2026, 10, 24), JalaliDate(1405, 8, 2)),
  (GregorianDate(2027, 3, 21), JalaliDate(1406, 1, 1)),
  (GregorianDate(2026, 3, 20), JalaliDate(1404, 12, 29)),
  (GregorianDate(2025, 3, 20), JalaliDate(1403, 12, 30)),
];

void main() {
  for (final JalaliCalendarPort cal in calendars) {
    final CentralCalendar central = CentralCalendar(cal);
    group('DT-05 · ${cal.name}', () {
      for (final (GregorianDate g, JalaliDate j) in conversions) {
        test('$g ↔ $j', () {
          expect(cal.toJalali(g), j);
          expect(cal.toGregorian(j), g);
        });
      }

      test('1403 is a leap year, 1404 and 1405 are not', () {
        expect(cal.isLeapYear(1403), isTrue);
        expect(cal.isLeapYear(1404), isFalse);
        expect(cal.isLeapYear(1405), isFalse);
      });

      test('month lengths of 1405: 6 × 31, 5 × 30, Esfand 29', () {
        expect(
          <int>[for (int m = 1; m <= 12; m++) cal.monthLength(1405, m)],
          <int>[31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29],
        );
      });

      test('Esfand 1403 has 30 days (leap year)', () {
        expect(cal.monthLength(1403, 12), 30);
      });

      test('2026-10-24 is a Saturday (DT-03: week starts on Saturday)', () {
        expect(cal.weekdayFromSaturday(const GregorianDate(2026, 10, 24)), 1);
        // and the following Friday is day 7
        expect(cal.weekdayFromSaturday(const GregorianDate(2026, 10, 30)), 7);
      });

      test('1405/06/31 + 1 month = 1405/07/30 (clamped)', () {
        expect(
          central.addMonths(const JalaliDate(1405, 6, 31), 1),
          const JalaliDate(1405, 7, 30),
        );
      });

      test('month addition across years and backwards', () {
        expect(
          central.addMonths(const JalaliDate(1403, 11, 30), 1),
          const JalaliDate(1403, 12, 30),
        );
        expect(
          central.addMonths(const JalaliDate(1403, 12, 30), 12),
          const JalaliDate(1404, 12, 29),
        );
        expect(
          central.addMonths(const JalaliDate(1405, 1, 31), -1),
          const JalaliDate(1404, 12, 29),
        );
        expect(
          central.addMonths(const JalaliDate(1405, 3, 15), -27),
          const JalaliDate(1402, 12, 15),
        );
      });

      test('validity follows the month lengths', () {
        expect(central.isValid(const JalaliDate(1403, 12, 30)), isTrue);
        expect(central.isValid(const JalaliDate(1404, 12, 30)), isFalse);
        expect(central.isValid(const JalaliDate(1405, 7, 31)), isFalse);
        expect(central.isValid(const JalaliDate(1405, 13, 1)), isFalse);
      });
    });
  }
}
