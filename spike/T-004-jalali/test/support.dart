// Shared helpers for the T-004 tests (platform-neutral: VM and Chrome).
// Synthetic reference data only.
import 'package:spike_jalali/spike_jalali.dart';

/// Both implementations of the port, run by every parameterised test.
const List<JalaliCalendarPort> calendars = <JalaliCalendarPort>[
  ShamsiDateCalendar(),
  ReferenceCalendar(),
];

/// First and last Gregorian day of the day-by-day cross-check (T-004 AC2).
const GregorianDate crossCheckFirst = GregorianDate(1900, 1, 1);
const GregorianDate crossCheckLast = GregorianDate(2123, 12, 31);

/// Walks every day from [crossCheckFirst] to [crossCheckLast] and returns the
/// number of days and the first mismatches (at most [limit]) between the two
/// implementations or in a round trip.
({int days, List<String> problems}) crossCheck({int limit = 5}) {
  final JalaliCalendarPort lib = calendars[0];
  final JalaliCalendarPort ref = calendars[1];
  final List<String> problems = <String>[];
  int days = 0;
  GregorianDate g = crossCheckFirst;
  while (g.compareTo(crossCheckLast) <= 0) {
    days++;
    final JalaliDate a = lib.toJalali(g);
    final JalaliDate b = ref.toJalali(g);
    if (problems.length < limit) {
      if (a != b) {
        problems.add('$g: ${lib.name} $a, ${ref.name} $b');
      } else if (lib.toGregorian(a) != g || ref.toGregorian(b) != g) {
        problems.add('$g: round trip via $a fails');
      } else if (lib.weekdayFromSaturday(g) != ref.weekdayFromSaturday(g)) {
        problems.add('$g: weekday differs');
      }
    }
    g = nextGregorianDay(g);
  }
  return (days: days, problems: problems);
}
