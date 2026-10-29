// Calendar-neutral value types for the T-004 spike (DT-01, DT-05).
// A civil date has no time and no zone; instants and zones are out of scope
// here (DT-02 needs an audited tz database, see README).

/// A proleptic Gregorian date. This is the only form that is stored
/// (DT-01: `yyyy-MM-dd`, never a Jalali string).
class GregorianDate implements Comparable<GregorianDate> {
  const GregorianDate(this.year, this.month, this.day);

  /// Parses the DT-01 storage form `yyyy-MM-dd` (exactly 10 characters,
  /// four-digit year) and rejects dates that do not exist.
  factory GregorianDate.parseIso(String text) {
    final RegExpMatch? m = _iso.firstMatch(text);
    if (m == null) {
      throw FormatException('not a yyyy-MM-dd date', text);
    }
    final GregorianDate d = GregorianDate(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
    if (d.month < 1 ||
        d.month > 12 ||
        d.day < 1 ||
        d.day > gregorianMonthLength(d.year, d.month)) {
      throw FormatException('no such Gregorian date', text);
    }
    return d;
  }

  static final RegExp _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// DT-01 storage form.
  String toIso() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';

  @override
  int compareTo(GregorianDate other) => year != other.year
      ? year.compareTo(other.year)
      : month != other.month
          ? month.compareTo(other.month)
          : day.compareTo(other.day);

  @override
  bool operator ==(Object other) =>
      other is GregorianDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// A Jalali (Solar Hijri) date. Display only; never stored (DT-01).
class JalaliDate {
  const JalaliDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is JalaliDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Latin digits, for test messages only; display goes through the central
  /// formatter (later task).
  @override
  String toString() => '${_pad(year, 4)}/${_pad(month, 2)}/${_pad(day, 2)}';
}

/// Gregorian leap-year rule.
bool isGregorianLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// Days in a Gregorian month.
int gregorianMonthLength(int year, int month) {
  const List<int> lengths = <int>[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month == 2 && isGregorianLeapYear(year)) {
    return 29;
  }
  return lengths[month - 1];
}

/// The next Gregorian day (pure integer arithmetic; no DateTime, so no zone).
GregorianDate nextGregorianDay(GregorianDate d) {
  if (d.day < gregorianMonthLength(d.year, d.month)) {
    return GregorianDate(d.year, d.month, d.day + 1);
  }
  if (d.month < 12) {
    return GregorianDate(d.year, d.month + 1, 1);
  }
  return GregorianDate(d.year + 1, 1, 1);
}

String _pad(int value, int width) => value.toString().padLeft(width, '0');
