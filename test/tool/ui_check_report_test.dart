// Tool tests of the VR-05 report (T-038; VR-07 report item and
// determinism; MC-23 "uncovered" visible in the report).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/ui_check/src/generator.dart';
import '../../tool/ui_check/src/manifest.dart';
import '../../tool/ui_check/src/report.dart';
import '../../tool/ui_check/src/rules_stage.dart';
import '../../tool/ui_check/src/token_registry.dart';
import '../../tool/ui_check/src/tokens_stage.dart';
import '../../tool/ui_check/ui_check.dart';

final List<int> _repoJson = File(tokensPath).readAsBytesSync();
final List<int> _repoGenerated = File(generatedPath).readAsBytesSync();
final List<int> _repoManifest = File(manifestPath).readAsBytesSync();

StageResult _tokens(List<int> json, {Profile profile = Profile.mvp}) =>
    runTokensStage(
      jsonBytes: json,
      generatedBytes: identical(json, _repoJson)
          ? _repoGenerated
          : utf8.encode(generateFromBytes(json)!),
      manifestBytes: _repoManifest,
      profile: profile,
    );

RulesResult _rules(Map<String, String> files, {Profile profile = Profile.mvp}) =>
    runRulesStage(files, profile: profile);

const Map<String, String> _cleanLib = <String, String>{
  'lib/ui/a.dart': 'const int c = 1;\n',
};

/// The table row of [rule] in the Rules section.
String _row(String report, String rule) {
  final List<String> rows = report
      .split('\n')
      .where((String l) => l.startsWith('| $rule |'))
      .toList();
  expect(rows, hasLength(1), reason: 'exactly one row for $rule');
  return rows.single;
}

void main() {
  test('report of the repository: all sections in order, PASS', () {
    final String r = buildReport(
      tokens: _tokens(_repoJson),
      rules: _rules(_cleanLib),
      profile: Profile.mvp,
    );
    debugPrint('--- VR-05 report (repository tokens, clean lib sample)');
    debugPrint(r);
    int last = -1;
    for (final String s in reportSections) {
      final int at = r.indexOf('\n$s\n');
      expect(at, greaterThan(last), reason: 'section "$s" present and in order');
      last = at;
    }
    expect(r, contains('- Result: PASS'));
    expect(r, contains('- Profile: mvp'));
    expect(r, isNot(contains(Directory.current.path)));
  });

  test('every rule appears once with its status; UNCOVERED rows visible', () {
    final String r = buildReport(
      tokens: _tokens(_repoJson),
      rules: _rules(_cleanLib),
      profile: Profile.mvp,
    );
    for (final TokenStageRule t in tokenStageRules) {
      expect(_row(r, t.rule), contains('| tokens | GREEN | 0 |'));
    }
    expect(_row(r, 'VT-04'), contains('| EXEMPT |'));
    expect(_row(r, 'VT-05'), contains('| NOT_COVERED |'));
    for (final String rule in coveredRules) {
      expect(_row(r, rule), contains('| rules | GREEN | 0 |'));
    }
    expect(uncoveredRows, isNotEmpty);
    for (final UncoveredRow u in uncoveredRows) {
      expect(_row(r, u.rule), contains('| UNCOVERED |'));
      expect(_row(r, u.rule), contains(u.reason));
    }
  });

  test('a broken input turns its rule RED (TK-08, MC-08) and FAIL', () {
    final String text = utf8.decode(_repoJson);
    expect(text.split('"background": "#0B1220"').length, 2);
    final List<int> black = utf8.encode(
        text.replaceFirst('"background": "#0B1220"', '"background": "#000000"'));
    final String r = buildReport(
      tokens: _tokens(black),
      rules: _rules(<String, String>{
        'lib/ui/a.dart': 'const Duration d = Duration(milliseconds: 5);\n'
            'const Duration e = Duration(milliseconds: 6);\n',
      }),
      profile: Profile.mvp,
    );
    expect(_row(r, 'TK-08'), contains('| RED |'));
    expect(_row(r, 'MC-08'), contains('| rules | RED | 2 |'));
    expect(_row(r, 'MC-01'), contains('| GREEN |'));
    expect(r, contains('- Result: FAIL'));
    expect(r, contains('- `TK-08` '));
    expect(r, contains('- `MC-08` lib/ui/a.dart:1 '));
  });

  test('contrast section equals the token stage summaries', () {
    final StageResult t = _tokens(_repoJson);
    final String r = buildReport(
      tokens: t,
      rules: _rules(_cleanLib),
      profile: Profile.mvp,
    );
    expect(t.groups.map((GroupSummary g) => g.id).toList(),
        contrastGroups.map((GroupSpec g) => g.id).toList());
    for (final GroupSummary g in t.groups) {
      final String id =
          g.id == separateGroupId ? '${g.id} (reported apart)' : g.id;
      expect(r, contains('| $id | ${g.threshold} | ${g.pairsPerTheme} |'));
    }
    expect(r, contains('VTG-01…VTG-09: $expectedPairCount pair checks'));
  });

  test('profile=full: MC-23 finding listed, UNCOVERED still visible', () {
    final String r = buildReport(
      tokens: _tokens(_repoJson, profile: Profile.full),
      rules: _rules(_cleanLib, profile: Profile.full),
      profile: Profile.full,
    );
    expect(r, contains('- Profile: full'));
    expect(r, contains('- `MC-23` profile=full'));
    expect(_row(r, uncoveredRows.first.rule), contains('| UNCOVERED |'));
  });

  test('deterministic: two builds are byte-equal', () {
    String build() => buildReport(
          tokens: _tokens(_repoJson),
          rules: _rules(_cleanLib),
          profile: Profile.mvp,
        );
    expect(build(), build());
  });

  group('CLI', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('ui_check_report_');
      for (final String p in <String>[tokensPath, generatedPath, manifestPath]) {
        File('${tmp.path}/$p')
          ..createSync(recursive: true)
          ..writeAsBytesSync(File(p).readAsBytesSync());
      }
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    test('all writes the default report and keeps exit 0', () {
      final StringBuffer out = StringBuffer();
      expect(runCli(<String>['--root=${tmp.path}'], out, StringBuffer()), 0);
      final File f = File('${tmp.path}/$defaultReportPath');
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), contains('- Result: PASS'));
      expect(out.toString(), contains('report (VR-05): $defaultReportPath'));
    });

    test('--report=<path> writes there; a finding still exits 1', () {
      File('${tmp.path}/lib/ui/a.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('const Duration d = Duration(milliseconds: 5);\n');
      final String path = '${tmp.path}/out/r.md';
      expect(
          runCli(<String>['all', '--root=${tmp.path}', '--report=$path'],
              StringBuffer(), StringBuffer()),
          1);
      expect(File(path).readAsStringSync(), contains('| MC-08 | rules | RED | 1 |'));
      expect(File('${tmp.path}/$defaultReportPath').existsSync(), isFalse);
    });

    test('tokens, rules, gen and a usage error write no report', () {
      for (final List<String> args in <List<String>>[
        <String>['tokens', '--root=${tmp.path}'],
        <String>['rules', '--root=${tmp.path}'],
        <String>['gen', '--root=${tmp.path}'],
      ]) {
        runCli(args, StringBuffer(), StringBuffer());
      }
      expect(
          runCli(<String>['--report=', '--root=${tmp.path}'], StringBuffer(),
              StringBuffer()),
          64);
      expect(Directory('${tmp.path}/build').existsSync(), isFalse);
    });
  });
}
