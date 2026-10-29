// The tool's built-in lists equal the spec tables they come from, so the
// tool cannot drift from the UI constitution (AX-03, AX-08 پ, VT-01 step 1).
//
// Tables read: appendix A table A-2-a (AXT rows), table 7-0 (components),
// table 5-1 (destinations).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ui_check/src/manifest.dart';
import '../../tool/ui_check/src/token_registry.dart';

final RegExp _tick = RegExp('`([^`]+)`');

List<String> _cells(String row) =>
    row.split('|').map((String c) => c.trim()).toList();

Set<String> _ticked(String cell) =>
    _tick.allMatches(cell).map((RegExpMatch m) => m.group(1)!).toSet();

/// Keys of the registry object at [path].
List<String> _keys(String path) =>
    registry().firstWhere((RegistryEntry e) => e.path == path).keys;

void main() {
  test('registry equals appendix table A-2-a (AXT-01…AXT-13)', () {
    final List<String> rows = File('docs/design/ui-spec/A-appendix-tokens.md')
        .readAsLinesSync()
        .where((String l) => l.startsWith('| AXT-'))
        .toList();
    expect(rows, hasLength(13));

    final Map<String, Set<String>> expected = <String, Set<String>>{
      'AXT-01': _keys('meta').toSet(),
      'AXT-02': neutralColorNames.toSet(),
      'AXT-03': <String>{
        ...fillBaseNames,
        '-hover',
        '-pressed',
        '-subtle',
      },
      'AXT-04': _keys('alias').toSet(),
      'AXT-05': <String>{..._keys('scrim-opacity'), ..._keys('state-opacity')},
      'AXT-06': _keys('elevation').toSet(),
      'AXT-07': <String>{..._keys('typography'), ...textRoleNames},
      'AXT-08': _keys('space').toSet(),
      'AXT-09': _keys('radius').toSet(),
      'AXT-10': sizeNames.toSet(),
      'AXT-11': <String>{..._keys('layout'), ..._keys('layout.compact')},
      'AXT-12': <String>{
        ..._keys('motion'),
        ..._keys('motion.duration'),
        ..._keys('motion.timing'),
        ..._keys('motion.curve'),
      },
      'AXT-13': _keys('contrast').toSet(),
    };

    for (final String row in rows) {
      final List<String> cells = _cells(row);
      final String id = cells[1];
      expect(_ticked(cells[3]), expected[id], reason: id);
    }

    // Colour names per theme: 14 neutrals + 8 fills × 4 (AXT-02, AXT-03).
    expect(colorNames(), hasLength(46));
    expect(colorNames().toSet(), hasLength(46));
  });

  test('component catalogue equals table 7-0', () {
    final List<String> names = <String>[];
    for (final String l in File(
      'docs/design/ui-spec/07-components/7-00-intro-and-component-table.md',
    ).readAsLinesSync()) {
      if (l.startsWith('| `')) {
        names.addAll(_tick.allMatches(_cells(l)[1]).map((RegExpMatch m) => m.group(1)!));
      }
    }
    expect(names, componentCatalog);
  });

  test('destination catalogue equals table 5-1', () {
    final List<String> lines =
        File('docs/design/ui-spec/05-navigation-home-modules.md')
            .readAsLinesSync();
    final RegExp id = RegExp(r'^\| `([a-z]+)` \|');
    final int start = lines.indexWhere((String l) => id.hasMatch(l));
    final List<String> names = <String>[];
    for (int i = start; i < lines.length && id.hasMatch(lines[i]); i++) {
      names.add(id.firstMatch(lines[i])!.group(1)!);
    }
    expect(names, destinationCatalog);
    for (final String core in coreDestinations) {
      expect(destinationCatalog, contains(core));
    }
  });
}
