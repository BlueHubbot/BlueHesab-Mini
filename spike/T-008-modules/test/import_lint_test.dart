// MDC-A2 / MDC-T1 for the spike layout: core imports neither modules nor
// app; a module imports only core and itself. VM only (reads lib/).

@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _directive =
    RegExp(r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
        multiLine: true);

/// [uri] as a path relative to lib/ when it points into this package;
/// `dart:` and other packages are returned as written.
String _normalise(Uri base, String libRoot, String uri) {
  if (uri.startsWith('package:spike_modules/')) {
    return uri.substring('package:spike_modules/'.length);
  }
  if (uri.contains(':')) {
    return uri;
  }
  final String resolved = base.resolve(uri).toString();
  return resolved.startsWith(libRoot)
      ? resolved.substring(libRoot.length)
      : resolved;
}

/// Imports, exports and parts of [file], normalised.
List<String> _imports(File file) {
  final String text = file.readAsStringSync();
  final Uri base = Uri.file(file.absolute.path);
  final String libRoot = Directory('lib').absolute.uri.toString();
  return <String>[
    for (final RegExpMatch m in _directive.allMatches(text))
      _normalise(base, libRoot, m.group(1)!),
  ];
}

List<File> _dart(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  test('core imports no module and no app file (MDC-A2, MDC-T1)', () {
    final List<File> files = _dart('lib/core');
    expect(files, isNotEmpty);
    for (final File f in files) {
      for (final String i in _imports(f)) {
        expect(i.startsWith('modules/') || i.startsWith('app/'), isFalse,
            reason: '${f.path} imports $i');
      }
    }
  });

  test('budget imports only core and itself (MDC-A2)', () {
    final List<File> files = _dart('lib/modules/budget');
    expect(files, isNotEmpty);
    for (final File f in files) {
      for (final String i in _imports(f)) {
        if (i.contains(':')) {
          continue; // dart: or a third-party package
        }
        expect(i.startsWith('core/') || i.startsWith('modules/budget/'),
            isTrue,
            reason: '${f.path} imports $i');
      }
    }
  });

  test('module_list.dart is the only file that names a module (MDC-A3)',
      () {
    final List<String> naming = <String>[
      for (final File f in _dart('lib'))
        if (!f.path.replaceAll(r'\', '/').contains('lib/modules/') &&
            _imports(f).any((String i) => i.startsWith('modules/')))
          f.path.replaceAll(r'\', '/'),
    ];
    expect(naming, <String>['lib/app/module_list.dart']);
  });
}
