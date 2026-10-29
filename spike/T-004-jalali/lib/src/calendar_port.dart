// The one central calendar port (DT-05: Jalali arithmetic happens in one
// place only). Two implementations exist in this spike: the shamsi_date
// adapter and the in-house reference (ADRX-04 fallback). Rules that the spec
// fixes (clamped month addition, weekday from Saturday) are written once
// here, on top of the port, so both implementations share them.
import 'civil_date.dart';

/// Conversion and calendar facts. Implementations hold no state.
abstract interface class JalaliCalendarPort {
  /// Short name for test output and evidence lines.
  String get name;

  JalaliDate toJalali(GregorianDate date);

  GregorianDate toGregorian(JalaliDate date);

  bool isLeapYear(int jalaliYear);

  /// 1…12 → 31 (Farvardin…Shahrivar), 30 (Mehr…Bahman), 29 or 30 (Esfand).
  int monthLength(int jalaliYear, int jalaliMonth);

  /// 1 = Saturday … 7 = Friday (DT-03: the week starts on Saturday).
  int weekdayFromSaturday(GregorianDate date);
}

/// Rules on top of any port.
class CentralCalendar {
  const CentralCalendar(this.port);

  final JalaliCalendarPort port;

  /// Adds [months] (may be negative). The day is clamped to the last day of
  /// the target month (DT-05: 1405/06/31 + 1 month = 1405/07/30).
  JalaliDate addMonths(JalaliDate date, int months) {
    final int index = date.year * 12 + (date.month - 1) + months;
    // Dart's % is never negative for a positive divisor, so this floors.
    final int month = index % 12 + 1;
    final int year = (index - (month - 1)) ~/ 12;
    final int last = port.monthLength(year, month);
    return JalaliDate(year, month, date.day > last ? last : date.day);
  }

  /// Whether [date] names a real day of the Jalali calendar.
  bool isValid(JalaliDate date) =>
      date.month >= 1 &&
      date.month <= 12 &&
      date.day >= 1 &&
      date.day <= port.monthLength(date.year, date.month);
}
