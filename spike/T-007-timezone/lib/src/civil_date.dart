// A Gregorian calendar day without time or zone (DT-01, DT-B): the stored
// form of a transaction date is `yyyy-MM-dd`.

/// One Gregorian day. Value type; no calendar arithmetic lives here.
class CivilDate implements Comparable<CivilDate> {
  /// Creates the day [year]-[month]-[day]; the caller passes a real date.
  const CivilDate(this.year, this.month, this.day);

  /// Gregorian year.
  final int year;

  /// Month 1…12.
  final int month;

  /// Day of month 1…31.
  final int day;

  /// The stored form `yyyy-MM-dd` (DT-B).
  String toIso() => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CivilDate other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    if (month != other.month) {
      return month.compareTo(other.month);
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
