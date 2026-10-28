// In-house Jalali arithmetic: the ADRX-04 fallback ("if no candidate passes,
// an own adapter is built behind the date layer"). Algorithm: K. Borkowski,
// "The Persian calendar for 3000 years" (1996), via its break-year table. The
// structure follows the jalaali-js implementation of that method (MIT
// licence); before any promotion to lib/ the Security & License hat records
// it in OPEN_SOURCE_AUDIT.md and its MIT notice goes to third_party/licenses
// (README follow-up). Spike code only. Valid for Jalali years
// -61 … 3177. Integer arithmetic only, so it is exact on the Dart VM and on
// the web (all intermediates stay far below 2^53).
import 'calendar_port.dart';
import 'civil_date.dart';

/// Reference implementation of [JalaliCalendarPort].
class ReferenceCalendar implements JalaliCalendarPort {
  const ReferenceCalendar();

  static const List<int> _breaks = <int>[
    -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, //
    1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
  ];

  @override
  String get name => 'in-house';

  @override
  JalaliDate toJalali(GregorianDate date) =>
      _fromDayNumber(_gregorianToDay(date.year, date.month, date.day));

  @override
  GregorianDate toGregorian(JalaliDate date) =>
      _dayToGregorian(_jalaliToDay(date.year, date.month, date.day));

  @override
  bool isLeapYear(int jalaliYear) => _cal(jalaliYear).leap == 0;

  @override
  int monthLength(int jalaliYear, int jalaliMonth) {
    if (jalaliMonth < 1 || jalaliMonth > 12) {
      throw RangeError.range(jalaliMonth, 1, 12, 'jalaliMonth');
    }
    if (jalaliMonth <= 6) {
      return 31;
    }
    if (jalaliMonth <= 11) {
      return 30;
    }
    return isLeapYear(jalaliYear) ? 30 : 29;
  }

  @override
  int weekdayFromSaturday(GregorianDate date) {
    // Julian day number: (jdn + 1) % 7 gives 0 = Sunday … 6 = Saturday.
    final int sundayZero =
        (_gregorianToDay(date.year, date.month, date.day) + 1) % 7;
    return (sundayZero + 1) % 7 + 1;
  }

  // ---- Borkowski's method (truncating division, as in the paper's C code).

  static int _div(int a, int b) => a ~/ b;

  static int _mod(int a, int b) => a.remainder(b);

  static _YearInfo _cal(int jy) {
    if (jy < _breaks.first || jy >= _breaks.last) {
      throw RangeError.range(jy, _breaks.first, _breaks.last - 1, 'jalaliYear');
    }
    final int gy = jy + 621;
    int leapJ = -14;
    int jp = _breaks[0];
    int jump = 0;
    for (int i = 1; i < _breaks.length; i++) {
      final int jm = _breaks[i];
      jump = jm - jp;
      if (jy < jm) {
        break;
      }
      leapJ = leapJ + _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
      jp = jm;
    }
    int n = jy - jp;
    leapJ = leapJ + _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
    if (_mod(jump, 33) == 4 && jump - n == 4) {
      leapJ += 1;
    }
    final int leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
    final int march = 20 + leapJ - leapG;
    if (jump - n < 6) {
      n = n - jump + _div(jump + 4, 33) * 33;
    }
    int leap = _mod(_mod(n + 1, 33) - 1, 4);
    if (leap == -1) {
      leap = 4;
    }
    return _YearInfo(leap, gy, march);
  }

  static int _jalaliToDay(int jy, int jm, int jd) {
    final _YearInfo r = _cal(jy);
    return _gregorianToDay(r.gy, 3, r.march) +
        (jm - 1) * 31 -
        _div(jm, 7) * (jm - 7) +
        jd -
        1;
  }

  static JalaliDate _fromDayNumber(int jdn) {
    final int gy = _dayToGregorian(jdn).year;
    int jy = gy - 621;
    final _YearInfo r = _cal(jy);
    final int first = _gregorianToDay(gy, 3, r.march);
    int k = jdn - first;
    if (k >= 0) {
      if (k <= 185) {
        return JalaliDate(jy, 1 + _div(k, 31), _mod(k, 31) + 1);
      }
      k -= 186;
    } else {
      jy -= 1;
      k += 179;
      if (r.leap == 1) {
        k += 1;
      }
    }
    return JalaliDate(jy, 7 + _div(k, 30), _mod(k, 30) + 1);
  }

  static int _gregorianToDay(int gy, int gm, int gd) {
    final int d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
        _div(153 * _mod(gm + 9, 12) + 2, 5) +
        gd -
        34840408;
    return d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
  }

  static GregorianDate _dayToGregorian(int jdn) {
    int j = 4 * jdn + 139361631;
    j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
    final int i = _div(_mod(j, 1461), 4) * 5 + 308;
    final int gd = _div(_mod(i, 153), 5) + 1;
    final int gm = _mod(_div(i, 153), 12) + 1;
    final int gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
    return GregorianDate(gy, gm, gd);
  }
}

class _YearInfo {
  const _YearInfo(this.leap, this.gy, this.march);

  /// 0 for a Jalali leap year, otherwise 1…4 (years since the last leap).
  final int leap;
  final int gy;

  /// Day of March (Gregorian year [gy]) on which Farvardin 1 falls.
  final int march;
}
