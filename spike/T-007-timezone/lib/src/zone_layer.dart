// The only file that imports package:timezone (DT-02: offsets and DST come
// from the IANA tz database, never from hand-written rules). The layer never
// reads the clock: callers pass the current instant (DT-C, SD-06).

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'civil_date.dart';

/// Thrown when an IANA zone name is not in the embedded database.
class UnknownZoneException implements Exception {
  /// Creates the exception for [zone].
  const UnknownZoneException(this.zone);

  /// The name that was asked for.
  final String zone;

  @override
  String toString() => 'UnknownZoneException: $zone';
}

/// Local wall-clock reading of an instant in one zone.
typedef ZoneReading = ({
  CivilDate date,
  int hour,
  int minute,
  int second,
  int millisecond,
  Duration offset,
  bool isDst,
  String abbreviation,
});

/// Central time-zone layer over `package:timezone` (embedded `latest` data).
class ZoneLayer {
  ZoneLayer._();

  /// The single instance; the database is loaded on first use.
  static final ZoneLayer instance = ZoneLayer._();

  bool _loaded = false;

  void _ensureLoaded() {
    if (!_loaded) {
      tzdata.initializeTimeZones();
      _loaded = true;
    }
  }

  /// Number of zone names in the embedded database.
  int get zoneCount {
    _ensureLoaded();
    return tz.timeZoneDatabase.locations.length;
  }

  /// Whether [zone] is a known IANA name.
  bool isKnown(String zone) {
    _ensureLoaded();
    return tz.timeZoneDatabase.locations.containsKey(zone);
  }

  tz.Location _location(String zone) {
    _ensureLoaded();
    final tz.Location? loc = tz.timeZoneDatabase.locations[zone];
    if (loc == null) {
      throw UnknownZoneException(zone);
    }
    return loc;
  }

  /// The wall-clock reading of [instant] in [zone].
  ZoneReading read(String zone, DateTime instant) {
    final tz.TZDateTime t = tz.TZDateTime.fromMillisecondsSinceEpoch(
      _location(zone),
      instant.millisecondsSinceEpoch,
    );
    return (
      date: CivilDate(t.year, t.month, t.day),
      hour: t.hour,
      minute: t.minute,
      second: t.second,
      millisecond: t.millisecond,
      offset: t.timeZoneOffset,
      isDst: t.timeZone.isDst,
      abbreviation: t.timeZone.abbreviation,
    );
  }

  /// UTC offset of [zone] at [instant].
  Duration offsetAt(String zone, DateTime instant) =>
      read(zone, instant).offset;

  /// "Today" in [zone] at the instant [now] (DT-C): the caller freezes it
  /// for the QuickAdd window (SD-06).
  CivilDate todayIn(String zone, DateTime now) => read(zone, now).date;

  /// The instant `TZDateTime` gives for a local wall time in [zone]. Used
  /// only to record DST gap/overlap behaviour; no rule ID decides it yet.
  DateTime localToInstant(
    String zone,
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime t =
        tz.TZDateTime(_location(zone), year, month, day, hour, minute);
    return DateTime.fromMillisecondsSinceEpoch(
      t.millisecondsSinceEpoch,
      isUtc: true,
    );
  }
}
