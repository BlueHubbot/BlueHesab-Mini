// DT-A (DATA_MODEL §4, DT-01): stored instant text. Platform-neutral (VM and
// Chrome). Synthetic values only.
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_timezone/spike_timezone.dart';

void main() {
  group('DT-A formatInstant', () {
    test('the DATA_MODEL example', () {
      expect(
        formatInstant(DateTime.utc(2026, 10, 24, 6, 55)),
        '2026-10-24T06:55:00.000Z',
      );
    });

    test('exactly three fraction digits; microseconds are truncated', () {
      expect(
        formatInstant(DateTime.utc(2026, 1, 2, 3, 4, 5, 7)),
        '2026-01-02T03:04:05.007Z',
      );
      expect(
        formatInstant(DateTime.utc(2026, 1, 2, 3, 4, 5, 999, 999)),
        '2026-01-02T03:04:05.999Z',
      );
    });

    test('a local DateTime is converted to UTC first', () {
      final DateTime utc = DateTime.utc(2026, 10, 29, 20, 30);
      expect(formatInstant(utc.toLocal()), '2026-10-29T20:30:00.000Z');
    });

    test('years outside 0…9999 are refused', () {
      expect(
        () => formatInstant(DateTime.utc(10000)),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('DT-A parseInstant', () {
    test('round trip', () {
      const List<String> samples = <String>[
        '2026-10-24T06:55:00.000Z',
        '2000-02-29T23:59:59.999Z',
        '1970-01-01T00:00:00.000Z',
      ];
      for (final String s in samples) {
        final DateTime t = parseInstant(s);
        expect(t.isUtc, isTrue, reason: s);
        expect(formatInstant(t), s);
      }
    });

    test('only the exact shape is accepted', () {
      const List<String> bad = <String>[
        '2026-10-24T06:55:00Z',
        '2026-10-24T06:55:00.0Z',
        '2026-10-24T06:55:00.000000Z',
        '2026-10-24T10:25:00.000+03:30',
        '2026-10-24 06:55:00.000Z',
        '2026-10-24T06:55:00.000',
        '2026-13-24T06:55:00.000Z',
        '2026-02-30T06:55:00.000Z',
        '',
      ];
      for (final String s in bad) {
        expect(
          () => parseInstant(s),
          throwsA(isA<FormatException>()),
          reason: s,
        );
      }
    });
  });

  test('DT-B CivilDate stored form', () {
    expect(const CivilDate(2026, 3, 9).toIso(), '2026-03-09');
    expect(const CivilDate(987, 12, 1).toIso(), '0987-12-01');
  });
}
