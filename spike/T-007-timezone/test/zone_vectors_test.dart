// DT-C and DT-02 fixed vectors (DATA_MODEL §4, SD-06). Platform-neutral (VM
// and Chrome). Expected values were checked with Python zoneinfo (tzdata
// 2026e) before the spike; the full comparison is reference_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_timezone/spike_timezone.dart';

DateTime at(String text) => parseInstant(text);

void main() {
  final ZoneLayer zones = ZoneLayer.instance;

  group('DT-C today in Asia/Tehran', () {
    test('local midnight is 20:30 UTC (+03:30)', () {
      expect(
        zones.todayIn('Asia/Tehran', at('2026-10-29T20:29:59.999Z')),
        const CivilDate(2026, 10, 29),
      );
      expect(
        zones.todayIn('Asia/Tehran', at('2026-10-29T20:30:00.000Z')),
        const CivilDate(2026, 10, 30),
      );
    });

    test('the same instant is a different day in UTC', () {
      final DateTime t = at('2026-10-29T21:00:00.000Z');
      expect(zones.todayIn('Asia/Tehran', t), const CivilDate(2026, 10, 30));
      expect(zones.todayIn('Europe/London', t), const CivilDate(2026, 10, 29));
    });
  });

  group('DT-C today across a DST change (America/New_York, 2026-03-08)', () {
    test('midnight before the change is 05:00 UTC (EST)', () {
      expect(
        zones.todayIn('America/New_York', at('2026-03-08T04:59:59.999Z')),
        const CivilDate(2026, 3, 7),
      );
      expect(
        zones.todayIn('America/New_York', at('2026-03-08T05:00:00.000Z')),
        const CivilDate(2026, 3, 8),
      );
    });

    test('midnight after the change is 04:00 UTC (EDT)', () {
      expect(
        zones.todayIn('America/New_York', at('2026-03-09T03:59:59.999Z')),
        const CivilDate(2026, 3, 8),
      );
      expect(
        zones.todayIn('America/New_York', at('2026-03-09T04:00:00.000Z')),
        const CivilDate(2026, 3, 9),
      );
    });

    test('the change itself: 01:59:59 EST, then 03:00:00 EDT', () {
      final ZoneReading before =
          zones.read('America/New_York', at('2026-03-08T06:59:59.000Z'));
      final ZoneReading after =
          zones.read('America/New_York', at('2026-03-08T07:00:00.000Z'));
      expect((before.hour, before.minute, before.second), (1, 59, 59));
      expect(before.offset, const Duration(hours: -5));
      expect(before.isDst, isFalse);
      expect((after.hour, after.minute, after.second), (3, 0, 0));
      expect(after.offset, const Duration(hours: -4));
      expect(after.isDst, isTrue);
    });
  });

  group('DT-02 Asia/Tehran rules come from the database', () {
    test('+04:30 in July 2022 (last DST), +03:30 from 2023', () {
      expect(
        zones.offsetAt('Asia/Tehran', at('2022-07-01T00:00:00.000Z')),
        const Duration(hours: 4, minutes: 30),
      );
      expect(
        zones.offsetAt('Asia/Tehran', at('2023-07-01T00:00:00.000Z')),
        const Duration(hours: 3, minutes: 30),
      );
      expect(
        zones.offsetAt('Asia/Tehran', at('2026-07-01T00:00:00.000Z')),
        const Duration(hours: 3, minutes: 30),
      );
      expect(
        zones.read('Asia/Tehran', at('2026-07-01T00:00:00.000Z')).isDst,
        isFalse,
      );
    });

    test('fixed-offset neighbours: Dubai +04:00, Kabul +04:30', () {
      final DateTime t = at('2026-07-01T00:00:00.000Z');
      expect(zones.offsetAt('Asia/Dubai', t), const Duration(hours: 4));
      expect(
        zones.offsetAt('Asia/Kabul', t),
        const Duration(hours: 4, minutes: 30),
      );
    });
  });

  test('an unknown zone name is an error, never a silent UTC', () {
    expect(zones.isKnown('Asia/Tehran'), isTrue);
    expect(zones.isKnown('Asia/Teheran-typo'), isFalse);
    expect(
      () => zones.todayIn('Asia/Teheran-typo', at('2026-01-01T00:00:00.000Z')),
      throwsA(isA<UnknownZoneException>()),
    );
  });
}
