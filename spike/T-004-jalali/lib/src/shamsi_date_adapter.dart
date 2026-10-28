// The only file that imports package:shamsi_date (DT-05: one central layer;
// ADR-UI-004 candidate, OPEN_SOURCE_AUDIT row: BSD-3-Clause, PROTOTYPE).
import 'package:shamsi_date/shamsi_date.dart' as sd;

import 'calendar_port.dart';
import 'civil_date.dart';

/// [JalaliCalendarPort] backed by shamsi_date.
class ShamsiDateCalendar implements JalaliCalendarPort {
  const ShamsiDateCalendar();

  @override
  String get name => 'shamsi_date';

  @override
  JalaliDate toJalali(GregorianDate date) {
    final sd.Jalali j = sd.Gregorian(date.year, date.month, date.day).toJalali();
    return JalaliDate(j.year, j.month, j.day);
  }

  @override
  GregorianDate toGregorian(JalaliDate date) {
    final sd.Gregorian g =
        sd.Jalali(date.year, date.month, date.day).toGregorian();
    return GregorianDate(g.year, g.month, g.day);
  }

  @override
  bool isLeapYear(int jalaliYear) => sd.Jalali(jalaliYear).isLeapYear();

  @override
  int monthLength(int jalaliYear, int jalaliMonth) =>
      sd.Jalali(jalaliYear, jalaliMonth).monthLength;

  @override
  int weekdayFromSaturday(GregorianDate date) =>
      // shamsi_date numbers Jalali weekdays 1 = Saturday … 7 = Friday.
      sd.Gregorian(date.year, date.month, date.day).toJalali().weekDay;

  /// The library's own month addition on [date], for the README finding only
  /// (the app uses [CentralCalendar.addMonths]). Returns the result or the
  /// exception's type name.
  String rawAddMonthsProbe(JalaliDate date, int months) {
    try {
      final sd.Jalali r =
          sd.Jalali(date.year, date.month, date.day).addMonths(months);
      return JalaliDate(r.year, r.month, r.day).toString();
    } on Object catch (e) {
      return 'throws ${e.runtimeType}';
    }
  }
}
