// VM-only checks of the T-007 spike: the import closure has no
// package:http (T-07), the single import of package:timezone (DT-02),
// data sizes and DST gap/overlap behaviour (recorded, not decided), and the
// CI evidence lines.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spike_timezone/spike_timezone.dart';

/// Appends one evidence line for the CI summary (build/ is git-ignored).
void recordEvidence(String line) {
  File('build/spike-evidence.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('$line\n', mode: FileMode.append);
}

/// Package name → its `lib/` directory, from .dart_tool/package_config.json.
final Map<String, Uri> packageLibs = () {
  final File config = File('.dart_tool/package_config.json');
  final Object? decoded = jsonDecode(config.readAsStringSync());
  final Map<String, Uri> out = <String, Uri>{};
  final Uri base = config.absolute.uri;
  for (final Object? p
      in (decoded! as Map<String, Object?>)['packages']! as List<Object?>) {
    final Map<String, Object?> m = p! as Map<String, Object?>;
    String root = m['rootUri']! as String;
    if (!root.endsWith('/')) {
      root = '$root/';
    }
    final Uri rootUri = base.resolve(root);
    out[m['name']! as String] =
        rootUri.resolve((m['packageUri'] as String?) ?? 'lib/');
  }
  return out;
}();

final RegExp _directive = RegExp(
  r'^\s*(?:import|export|part)\s+([^;]*);',
  multiLine: true,
);
final RegExp _quoted = RegExp(r'''['"]([^'"]+)['"]''');

/// Every file reachable from [start] through import/export/part, including
/// every URI of a conditional import. Returns file URI → URIs it names.
Map<Uri, List<String>> importClosure(Uri start) {
  final Map<Uri, List<String>> seen = <Uri, List<String>>{};
  final List<Uri> todo = <Uri>[start];
  while (todo.isNotEmpty) {
    final Uri file = todo.removeLast();
    if (seen.containsKey(file)) {
      continue;
    }
    final String text = File.fromUri(file).readAsStringSync();
    final List<String> named = <String>[
      for (final RegExpMatch d in _directive.allMatches(text))
        for (final RegExpMatch q in _quoted.allMatches(d.group(1)!)) q.group(1)!,
    ];
    seen[file] = named;
    for (final String u in named) {
      if (u.startsWith('dart:')) {
        continue;
      }
      if (u.startsWith('package:')) {
        final String rest = u.substring('package:'.length);
        final int slash = rest.indexOf('/');
        final Uri? lib = packageLibs[rest.substring(0, slash)];
        if (lib != null) {
          todo.add(lib.resolve(rest.substring(slash + 1)));
        } else {
          seen[Uri.parse(u)] = const <String>[]; // not resolved: listed
        }
      } else {
        todo.add(file.resolve(u));
      }
    }
  }
  return seen;
}

String packageOf(Uri file) {
  for (final MapEntry<String, Uri> e in packageLibs.entries) {
    if (file.toString().startsWith(e.value.toString())) {
      return e.key;
    }
  }
  return file.scheme == 'package' ? file.path.split('/').first : '?';
}

int sizeOf(Uri dir, String name) {
  final File f = File.fromUri(dir.resolve(name));
  return f.existsSync() ? f.lengthSync() : -1;
}

void main() {
  test('T-07: no package:http in the import closure of the spike library',
      () {
    final Map<Uri, List<String>> closure =
        importClosure(packageLibs['spike_timezone']!.resolve('spike_timezone.dart'));
    final Set<String> packages = <String>{
      for (final Uri f in closure.keys) packageOf(f),
    };
    final Set<String> dartLibs = <String>{
      for (final List<String> named in closure.values)
        for (final String u in named)
          if (u.startsWith('dart:')) u,
    };
    final Map<Uri, List<String>> whole =
        importClosure(packageLibs['timezone']!.resolve('timezone.dart'));
    final Map<Uri, List<String>> data =
        importClosure(packageLibs['timezone']!.resolve('data/latest.dart'));
    // Which files of the package do name http (not reached by the app).
    final Directory tzLib = Directory.fromUri(packageLibs['timezone']!);
    final List<String> httpUsers = <String>[
      for (final FileSystemEntity f in tzLib.listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.readAsStringSync().contains('package:http/'))
          f.uri.pathSegments.skipWhile((String s) => s != 'lib').join('/'),
    ]..sort();
    recordEvidence('closure_files=${closure.length} '
        'closure_packages=${(packages.toList()..sort()).join('+')} '
        'dart_libs=${(dartLibs.toList()..sort()).join('+')} '
        'timezone_files_naming_http=${httpUsers.join('+')} '
        'timezone.dart_closure=${whole.length} latest.dart_closure=${data.length}');
    expect(packages, isNot(contains('http')));
    expect(packages, containsAll(<String>['spike_timezone', 'timezone']));
    expect(dartLibs, isNot(contains('dart:io')));
    expect(dartLibs, isNot(contains('dart:html')));
  });

  test('DT-02: only zone_layer.dart imports package:timezone', () {
    final List<String> importers = <String>[
      for (final FileSystemEntity f
          in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.readAsStringSync().contains('package:timezone/'))
          f.path.replaceAll(r'\', '/'),
    ];
    expect(importers, <String>['lib/src/zone_layer.dart']);
  });

  test('evidence: package version, data variants and sizes', () {
    final Uri tzLib = packageLibs['timezone']!;
    final String pubspec =
        File.fromUri(tzLib.resolve('../pubspec.yaml')).readAsStringSync();
    final String version =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec)!.group(1)!;
    final Uri dataDir = tzLib.resolve('data/');
    final List<String> files = <String>[
      for (final FileSystemEntity f
          in Directory.fromUri(dataDir).listSync())
        if (f is File) '${f.uri.pathSegments.last}:${f.lengthSync()}',
    ]..sort();
    recordEvidence('timezone_version=$version zones=${ZoneLayer.instance.zoneCount} '
        'data_files=${files.join('+')}');
    expect(version, '0.11.2');
    expect(sizeOf(dataDir, 'latest.dart'), greaterThan(0));
    expect(ZoneLayer.instance.zoneCount, greaterThan(300));
  });

  test('evidence: DST gap and overlap of TZDateTime (recorded, no rule ID)',
      () {
    final ZoneLayer zones = ZoneLayer.instance;
    // Europe/Berlin 2026-03-29 02:30 does not exist; 2026-10-25 02:30 exists
    // twice (00:30Z and 01:30Z).
    final DateTime gap =
        zones.localToInstant('Europe/Berlin', 2026, 3, 29, 2, 30);
    final DateTime overlap =
        zones.localToInstant('Europe/Berlin', 2026, 10, 25, 2, 30);
    final DateTime nyGap =
        zones.localToInstant('America/New_York', 2026, 3, 8, 2, 30);
    recordEvidence('berlin_gap_0230=${formatInstant(gap)} '
        'berlin_overlap_0230=${formatInstant(overlap)} '
        'newyork_gap_0230=${formatInstant(nyGap)}');
    const List<String> twoCandidates = <String>[
      '2026-03-29T00:30:00.000Z',
      '2026-03-29T01:30:00.000Z',
    ];
    expect(twoCandidates, contains(formatInstant(gap)));
    expect(
      <String>['2026-10-25T00:30:00.000Z', '2026-10-25T01:30:00.000Z'],
      contains(formatInstant(overlap)),
    );
    expect(
      <String>['2026-03-08T06:30:00.000Z', '2026-03-08T07:30:00.000Z'],
      contains(formatInstant(nyGap)),
    );
  });

  test('evidence: what the runtime says about the device zone', () {
    final DateTime now = DateTime.now();
    // DateTime gives an abbreviation and an offset, not an IANA name: the
    // default of app.timezone (DT-C) needs a platform source (README T5).
    recordEvidence('os=${Platform.operatingSystem} '
        'device_zone_name=${now.timeZoneName} '
        'device_offset_min=${now.timeZoneOffset.inMinutes} '
        'TZ_env=${Platform.environment['TZ'] ?? '-'}');
    expect(now.timeZoneName, isNotEmpty);
  });
}
