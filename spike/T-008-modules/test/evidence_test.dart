// Records what the audit rows ask the spike to verify (T-005): resolved
// versions of the state/routing packages and the OS. VM only.

@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `name -> version` from pubspec.lock (simple line scan).
Map<String, String> _lockVersions() {
  final List<String> lines = File('pubspec.lock').readAsLinesSync();
  final Map<String, String> out = <String, String>{};
  String? current;
  for (final String line in lines) {
    final RegExpMatch? pkg = RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
    if (pkg != null) {
      current = pkg.group(1);
      continue;
    }
    final RegExpMatch? ver =
        RegExp(r'^    version: "([^"]+)"$').firstMatch(line);
    if (ver != null && current != null) {
      out[current] = ver.group(1)!;
    }
  }
  return out;
}

void main() {
  test('pinned versions resolved and recorded', () {
    final Map<String, String> v = _lockVersions();
    expect(v['flutter_riverpod'], '3.4.3');
    expect(v['go_router'], '18.1.0');
    final List<String> watch = <String>[
      'flutter_riverpod',
      'riverpod',
      'state_notifier',
      'go_router',
      'material_ui',
      'cupertino_ui',
      'logging',
      'flutter_web_plugins',
      'flutter_localizations',
      'intl',
      'listen',
      'uuid',
    ];
    final String line = <String>[
      'os=${Platform.operatingSystem}',
      'packages=${v.length}',
      for (final String n in watch) '$n=${v[n] ?? 'absent'}',
    ].join(' ');
    Directory('build').createSync(recursive: true);
    File('build/spike-evidence.txt').writeAsStringSync('$line\n');
  });
}
