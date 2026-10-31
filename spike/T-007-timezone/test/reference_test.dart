// DT-02: package:timezone (embedded `latest` data) against an independent
// reference, Python zoneinfo over the system IANA database
// (tool/make_tz_fixture.py). Platform-neutral (VM and Chrome).
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_timezone/spike_timezone.dart';

import 'fixtures/tz_reference.g.dart';

DateTime utcMs(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

void main() {
  final ZoneLayer zones = ZoneLayer.instance;

  test('every reference offset change is seen at the same second', () {
    final List<String> problems = <String>[];
    for (final (String zone, int ms, int before, int after)
        in referenceTransitions) {
      final int a = zones.offsetAt(zone, utcMs(ms - 1000)).inSeconds;
      final int b = zones.offsetAt(zone, utcMs(ms)).inSeconds;
      if (a != before || b != after) {
        problems.add('$zone ${formatInstant(utcMs(ms))}: reference '
            '$before→$after, package $a→$b');
      }
    }
    expect(problems, isEmpty, reason: problems.take(10).join('\n'));
    expect(referenceTransitions.length, greaterThan(300));
  });

  test('two samples per year agree', () {
    final List<String> problems = <String>[];
    for (final (String zone, int ms, int offset) in referenceSamples) {
      final int got = zones.offsetAt(zone, utcMs(ms)).inSeconds;
      if (got != offset) {
        problems.add('$zone ${formatInstant(utcMs(ms))}: '
            'reference $offset, package $got');
      }
    }
    expect(problems, isEmpty, reason: problems.take(10).join('\n'));
    expect(referenceSamples.length, 7 * 36 * 2);
  });

  test('no offset change in the package that the reference lacks', () {
    // Daily scan at 12:00 UTC: a change between two days must be one of the
    // reference transitions of that zone in that interval.
    final Map<String, List<int>> known = <String, List<int>>{};
    for (final (String zone, int ms, int _, int _) in referenceTransitions) {
      (known[zone] ??= <int>[]).add(ms);
    }
    final List<String> zoneNames = <String>{
      for (final (String z, int _, int _) in referenceSamples) z,
    }.toList();
    final List<String> problems = <String>[];
    const int day = 86400000;
    final int first = DateTime.utc(2000, 1, 1, 12).millisecondsSinceEpoch;
    final int last = DateTime.utc(2035, 12, 31, 12).millisecondsSinceEpoch;
    for (final String zone in zoneNames) {
      int prev = zones.offsetAt(zone, utcMs(first)).inSeconds;
      for (int ms = first + day; ms <= last; ms += day) {
        final int cur = zones.offsetAt(zone, utcMs(ms)).inSeconds;
        if (cur != prev) {
          final bool expected = (known[zone] ?? const <int>[])
              .any((int t) => t > ms - day && t <= ms);
          if (!expected) {
            problems.add('$zone change before ${formatInstant(utcMs(ms))}');
          }
          prev = cur;
        }
      }
    }
    expect(problems, isEmpty, reason: problems.take(10).join('\n'));
  });
}
