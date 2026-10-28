// Tool tests of the `tokens` stage (VR-07 b, ث; MC-23; AX-08 a, b).
//
// Each broken case starts from the real design_tokens.json, changes one
// thing and expects the rule ID of that thing. Where the change would also
// move the checksum or the generated file, the test refreshes them so the
// case isolates one rule.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/ui_check/src/contrast.dart';
import '../../tool/ui_check/src/generator.dart';
import '../../tool/ui_check/src/manifest.dart';
import '../../tool/ui_check/src/tokens_stage.dart';
import '../../tool/ui_check/ui_check.dart';

final List<int> _repoJson = File(tokensPath).readAsBytesSync();
final List<int> _repoGenerated = File(generatedPath).readAsBytesSync();
final List<int> _repoManifest = File(manifestPath).readAsBytesSync();

/// Replaces [from] with [to] exactly once in the token text.
List<int> _mutate(String from, String to, {List<int>? base}) {
  final String text = utf8.decode(base ?? _repoJson);
  expect(text.split(from).length, 2, reason: 'fixture text "$from" must be unique');
  return utf8.encode(text.replaceFirst(from, to));
}

/// Writes the correct checksum into [bytes] (as an ADR would).
List<int> _withChecksum(List<int> bytes) {
  final String text = utf8.decode(bytes);
  final String sum = tokenChecksum(bytes)!;
  return utf8.encode(text.replaceFirst(
    RegExp(r'"checksum": "[0-9a-f]*"'),
    '"checksum": "$sum"',
  ));
}

StageResult _run(
  List<int> json, {
  List<int>? generated,
  bool freshGenerated = false,
  List<int>? manifest,
  Profile profile = Profile.mvp,
}) {
  return runTokensStage(
    jsonBytes: json,
    generatedBytes: freshGenerated
        ? utf8.encode(generateFromBytes(json)!)
        : (generated ?? _repoGenerated),
    manifestBytes: manifest ?? _repoManifest,
    profile: profile,
  );
}

void main() {
  group('repository files', () {
    test('the tokens stage passes on the repository (AX-08 a)', () {
      final StageResult r = _run(_repoJson);
      expect(r.findings, isEmpty, reason: r.report.join('\n'));
      expect(r.report.last, 'Result: PASS');
    });

    test('checksum reproduces the AX-02 reference by computation', () {
      final String appendix =
          File('docs/design/ui-spec/A-appendix-tokens.md').readAsStringSync();
      final String ax02 = appendix
          .split('\n')
          .firstWhere((String l) => l.contains('**AX-02'));
      final String reference =
          RegExp(r'[0-9a-f]{64}').firstMatch(ax02)!.group(0)!;
      expect(tokenChecksum(_repoJson), reference);
      expect(reference, startsWith('e6064535'));
      expect(reference, endsWith('3e'));
    });

    test('210 contrast checks, groups and minima are reported (VT-02, VT-03)',
        () {
      final List<String> report = _run(_repoJson).report;
      expect(
        report,
        contains('  total VTG-01…VTG-09: 210 checks (105 per theme); '
            'VTG-10: 6 checks'),
      );
      for (int i = 1; i <= 10; i++) {
        final String id = 'VTG-${i.toString().padLeft(2, '0')}';
        expect(report.where((String l) => l.startsWith('  $id ')), hasLength(1));
      }
      expect(
        report,
        contains('  VTG-06 threshold 3.0 · 3 per theme · min light 3.31 · '
            'min dark 3.30'),
      );
    });

    test('two runs on unchanged files give identical output (VR-07 ث)', () {
      final StringBuffer a = StringBuffer();
      final StringBuffer b = StringBuffer();
      final int codeA = runCli(<String>['tokens'], a, StringBuffer());
      final int codeB = runCli(<String>['tokens'], b, StringBuffer());
      expect(codeA, 0, reason: a.toString());
      expect(codeB, 0);
      expect(a.toString(), b.toString());
    });

    test('the committed generated file holds no value outside the tokens',
        () {
      final String source = utf8.decode(_repoGenerated);
      final Set<String> hex = RegExp(r'0xFF([0-9A-F]{6})')
          .allMatches(source)
          .map((RegExpMatch m) => '#${m.group(1)}')
          .toSet();
      final String json = utf8.decode(_repoJson).toUpperCase();
      for (final String h in hex) {
        expect(json, contains('"$h"'), reason: '$h is not a token value');
      }
      expect(source, isNot(contains('Colors.')));
      expect(source, isNot(contains('fromRGBO')));
      expect(source, isNot(contains('fromARGB')));
    });

    test('the real command prints the report (dart run … tokens)', () {
      final ProcessResult r = Process.runSync(
        'dart',
        <String>['run', 'tool/ui_check/ui_check.dart', 'tokens'],
        runInShell: Platform.isWindows,
      );
      debugPrint('--- dart run tool/ui_check/ui_check.dart tokens '
          '(exit ${r.exitCode}) ---\n${r.stdout}${r.stderr}');
      expect(r.exitCode, 0);
      expect('${r.stdout}', contains('Result: PASS'));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('broken fixtures fail with their rule ID (VR-07 b, MC-23)', () {
    test('a colour change without a new checksum fails VT-01', () {
      final List<int> json = _mutate(
        '"text-disabled": "#94A3B8"',
        '"text-disabled": "#94A3B9"',
      );
      expect(_run(json, freshGenerated: true).failedRules, <String>['VT-01']);
    });

    test('hand-edited design_tokens.g.dart fails MC-02', () {
      final String edited = utf8
          .decode(_repoGenerated)
          .replaceFirst('Color(0xFFF8FAFC)', 'Color(0xFFF8FAFD)');
      final StageResult r = _run(_repoJson, generated: utf8.encode(edited));
      expect(r.failedRules, <String>['MC-02']);
    });

    test('a missing design_tokens.g.dart fails MC-02', () {
      final StageResult r = runTokensStage(
        jsonBytes: _repoJson,
        generatedBytes: null,
        manifestBytes: _repoManifest,
        profile: Profile.mvp,
      );
      expect(r.failedRules, <String>['MC-02']);
    });

    test('a pure black dark background fails TK-08', () {
      final List<int> json = _withChecksum(_mutate(
        '"background": "#0B1220"',
        '"background": "#000000"',
      ));
      expect(_run(json, freshGenerated: true).failedRules, contains('TK-08'));
    });

    test('a pair just under its threshold fails with the group ID', () {
      // #757575 on #F8FAFC is 4.40, under the 4.5 of VTG-01.
      final List<int> json = _withChecksum(_mutate(
        '"text-secondary": "#64748B"',
        '"text-secondary": "#757575"',
      ));
      final StageResult r = _run(json, freshGenerated: true);
      expect(r.failedRules, contains('VTG-01'));
      expect(
        r.findings.where((Finding f) => f.rule == 'VTG-01').first.message,
        contains('light text-secondary on background'),
      );
    });

    test('exactly at the threshold passes, just under fails (VT-02)', () {
      expect(meetsThreshold(4.5, 4.5), isTrue);
      expect(meetsThreshold(4.4, 4.5), isFalse);
      expect(meetsThreshold(3, 3), isTrue);
      expect(meetsThreshold(2.99, 3), isFalse);
      expect(contrastRatio('#000000', '#FFFFFF'), closeTo(21, 1e-9));
      expect(contrastRatio('#FFFFFF', '#FFFFFF'), closeTo(1, 1e-9));
    });

    test('an unregistered token name fails VT-01', () {
      final List<int> json = _withChecksum(_mutate(
        '"space-4": 16,',
        '"space-4": 16,\n    "space-5": 20,',
      ));
      expect(_run(json).failedRules, <String>['VT-01']);
    });

    test('a registered token name that is missing fails VT-01', () {
      final List<int> json = _withChecksum(_mutate('    "space-6": 24,\n', ''));
      expect(_run(json).failedRules, <String>['VT-01']);
    });

    test('a colour that is not six-digit hex fails VT-01', () {
      final List<int> json = _withChecksum(_mutate(
        '"text-disabled": "#94A3B8"',
        '"text-disabled": "#94A"',
      ));
      expect(_run(json, freshGenerated: true).failedRules, <String>['VT-01']);
    });

    test('a wrong count-per-theme fails VT-03', () {
      final List<int> json = _withChecksum(_mutate(
        '"fg": ["focus-ring"],\n'
            '            "bg": ["background", "surface", "surface-raised"],\n'
            '            "count-per-theme": 3,',
        '"fg": ["focus-ring"],\n'
            '            "bg": ["background", "surface", "surface-raised"],\n'
            '            "count-per-theme": 4,',
      ));
      expect(_run(json).failedRules, <String>['VT-03']);
    });

    test('a minimum that differs from table 2-8 fails VT-03', () {
      final List<int> json =
          _withChecksum(_mutate('"min-light": 4.94,', '"min-light": 4.95,'));
      expect(_run(json).failedRules, <String>['VT-03']);
    });

    test('a pair count other than 210 fails VT-03', () {
      final List<int> json = _withChecksum(_mutate(
        '"fg": ["focus-ring"],\n'
            '            "bg": ["background", "surface", "surface-raised"],\n'
            '            "count-per-theme": 3,',
        '"fg": ["focus-ring"],\n'
            '            "bg": ["background", "surface"],\n'
            '            "count-per-theme": 2,',
      ));
      final StageResult r = _run(json);
      expect(r.failedRules, <String>['VT-03']);
      expect(
        r.findings.map((Finding f) => f.message),
        contains(startsWith('VTG-01…VTG-09 give 208 pair checks')),
      );
    });

    test('an unregistered contrast group fails VT-06', () {
      final List<int> json =
          _withChecksum(_mutate('"id": "VTG-10"', '"id": "VTG-11"'));
      expect(_run(json).failedRules, <String>['VT-06']);
    });

    test('a pair with an unknown colour fails VT-06', () {
      final List<int> json = _withChecksum(
        _mutate('"fg": ["focus-ring"]', '"fg": ["focus-glow"]'),
      );
      expect(_run(json).failedRules, <String>['VT-06']);
    });

    test('CRLF line endings fail AX-02', () {
      final List<int> json = _withChecksum(
        utf8.encode(utf8.decode(_repoJson).replaceAll('\n', '\r\n')),
      );
      expect(_run(json).failedRules, <String>['AX-02']);
    });
  });
}
