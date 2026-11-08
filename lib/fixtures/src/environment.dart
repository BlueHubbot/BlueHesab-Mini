// The fixed test environment of DS-01 (ui-spec §10-2; T-022).

import 'fixture_types.dart';

/// A reference viewport of DS-01 (logical pixels).
final class FixtureViewport {
  /// Creates a viewport.
  const FixtureViewport(this.name, this.width, this.height);

  /// Window class name.
  final String name;

  /// Width in logical pixels.
  final int width;

  /// Height in logical pixels.
  final int height;
}

/// DS-01: every sample and test runs in this environment unless it says
/// otherwise.
abstract final class FixtureEnvironment {
  /// Saturday 2 Aban 1405 (2026-10-24), 10:00 in Asia/Tehran, as a UTC
  /// instant (Tehran is +03:30 with no DST since 2023, T-007 T2).
  static final DateTime instantUtc = DateTime.utc(2026, 10, 24, 6, 30);

  /// IANA zone of the fixed clock.
  static const String timeZone = 'Asia/Tehran';

  /// Offset of [timeZone] at [instantUtc], in minutes.
  static const int utcOffsetMinutes = 210;

  /// The day of [instantUtc] in Tehran, in both calendars.
  static const FixtureDate today = FixtureDate(1405, 8, 2, 2026, 10, 24);

  /// Local wall-clock hour of [instantUtc] in Tehran.
  static const int localHour = 10;

  /// Local wall-clock minute of [instantUtc] in Tehran.
  static const int localMinute = 0;

  /// Calendar of the reference rendering.
  static const String calendar = 'jalali';

  /// Digit set of the reference rendering (DS-05 adds Latin digits).
  static const String digits = 'persian';

  /// Display unit of IRR amounts (MN-02).
  static const String displayUnit = 'toman';

  /// Theme of the reference rendering.
  static const String theme = 'light';

  /// Text direction of the reference rendering.
  static const String direction = 'rtl';

  /// Text scale in percent (1.0 = 100).
  static const int textScalePercent = 100;

  /// Reference viewports: Compact, Medium, Expanded, Large.
  static const List<FixtureViewport> viewports = <FixtureViewport>[
    FixtureViewport('compact', 360, 640),
    FixtureViewport('medium', 768, 1024),
    FixtureViewport('expanded', 1024, 768),
    FixtureViewport('large', 1440, 900),
  ];
}
