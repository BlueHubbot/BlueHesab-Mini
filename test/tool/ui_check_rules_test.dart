// Tool tests of the `rules` stage (T-016; VR-01, VR-03, VR-07, MC-23, MC-24).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/ui_check/src/dart_lexer.dart';
import '../../tool/ui_check/src/manifest.dart';
import '../../tool/ui_check/src/rules_stage.dart';
import '../../tool/ui_check/ui_check.dart';

const String _fixtureDir = 'tool/ui_check/fixtures';
final RegExp _header = RegExp(r'^// fixture-path: (\S+)\n');

/// (virtual path, content) of one fixture file.
(String, String) _fixture(String name) {
  final String text = File('$_fixtureDir/$name').readAsStringSync();
  final RegExpMatch? m = _header.firstMatch(text);
  expect(m, isNotNull, reason: '$name has no "// fixture-path:" first line');
  return (m![1]!, text);
}

String _idOf(String rule) => rule.toLowerCase();

void main() {
  group('lexer', () {
    test('comments and string bodies are blanked, lines kept', () {
      const String src = 'a(); // Color(0xFF000000)\n'
          '/* outer /* nested */ Curves.x */ b();\n'
          "final s = 'Colors.red';\n";
      final Lexed lx = Lexed(src);
      expect(lx.code.length, src.length);
      expect(lx.code, isNot(contains('Color(')));
      expect(lx.code, isNot(contains('Curves')));
      expect(lx.code, isNot(contains('Colors.red')));
      expect(lx.code, contains('b();'));
      expect(lx.code.split('\n').length, src.split('\n').length);
      expect(lx.comments.map((CommentPart c) => c.line), <int>[1, 2]);
      expect(lx.strings.single.text, 'Colors.red');
      expect(lx.strings.single.line, 3);
    });

    test('interpolated code stays visible, literal parts are separate', () {
      final Lexed lx = Lexed(r"final s = 'a ${Colors.red} b';");
      expect(lx.code, contains('Colors.red'));
      expect(lx.strings.map((StringPart p) => p.text), <String>['a ', ' b']);
    });

    test('nested string inside interpolation', () {
      final Lexed lx = Lexed(r"""final s = "x ${f('y')} z"; g();""");
      expect(lx.strings.map((StringPart p) => p.text), <String>['x ', 'y', ' z']);
      expect(lx.code, contains('g();'));
    });

    test('raw and triple-quoted strings, exact lines', () {
      const String src = "final a = r'\\u2066';\n"
          "final b = '''\n"
          'one\n'
          "two''';\n"
          'final c = 1;\n';
      final Lexed lx = Lexed(src);
      expect(lx.strings[0].raw, isTrue);
      expect(lx.strings[0].text, r'\u2066');
      expect(lx.strings[1].line, 2);
      expect(lx.strings[1].text, '\none\ntwo');
      expect(lx.lineOf(src.indexOf('final c')), 5);
      expect(lx.code, contains('final c = 1;'));
    });

    test('escaped quote does not end the string', () {
      final Lexed lx = Lexed(r"final s = 'it\'s Curves.x'; h();");
      expect(lx.code, isNot(contains('Curves')));
      expect(lx.code, contains('h();'));
    });
  });

  group('fixtures (MC-23)', () {
    test('every covered row has exactly one bad and one good fixture', () {
      final List<String> names = Directory(_fixtureDir)
          .listSync()
          .whereType<File>()
          .map((File f) => f.uri.pathSegments.last)
          .toList()
        ..sort();
      final List<String> expected = <String>[
        for (final String r in coveredRules) ...<String>[
          '${_idOf(r)}.bad.dart.txt',
          '${_idOf(r)}.good.dart.txt',
        ],
      ]..sort();
      expect(names, expected);
    });

    for (final String rule in coveredRules) {
      test('$rule: bad fixture fails with exactly $rule', () {
        final (String path, String text) = _fixture('${_idOf(rule)}.bad.dart.txt');
        final List<RuleHit> hits = checkFile(path, text);
        expect(hits, isNotEmpty, reason: 'bad fixture of $rule passed');
        expect(hits.map((RuleHit h) => h.rule).toSet(), <String>{rule},
            reason: hits.join('\n'));
      });

      test('$rule: good fixture has no finding', () {
        final (String path, String text) = _fixture('${_idOf(rule)}.good.dart.txt');
        expect(checkFile(path, text), isEmpty);
      });
    }
  });

  group('allowed-in column', () {
    test('MC-01: colour literal only in the generated token file', () {
      const String src = 'const Color c = Color(0xFF112233);\n';
      expect(checkFile('lib/design/tokens/design_tokens.g.dart', src), isEmpty);
      expect(checkFile('lib/design/tokens/other.dart', src).single.rule, 'MC-01');
    });

    test('MC-08: any app_motion/ segment is the package', () {
      const String src = 'const Duration d = Duration(milliseconds: 1);\n';
      expect(checkFile('lib/app_motion/src/a.dart', src), isEmpty);
      expect(checkFile('lib/design/app_motion_x.dart', src).single.rule, 'MC-08');
    });

    test('MC-08: the generated token file is allowed too (SE-14)', () {
      const String src = 'const Duration d = Duration(milliseconds: 1);\n';
      expect(checkFile('lib/design/tokens/design_tokens.g.dart', src), isEmpty);
      expect(checkFile('lib/design/tokens/motion.dart', src).single.rule, 'MC-08');
      expect(
          checkFile('lib/design/tokens/design_tokens.g.dart',
              'const Curve c = Curves.linear;\n'),
          isEmpty);
    });

    test('MC-01: hex numbers allowed only in the two named pure-Dart files (SE-14)',
        () {
      // VR-07(a) sound sample: int RGB maths, a colour-shaped hex constant.
      const String good = 'const int scrim = 0x000000;\n'
          'int red(int rgb) => (rgb >> 16) & 0xFF;\n'
          "const String hex = '#1A2B3C';\n";
      for (final String p in mc01PureDartFiles) {
        expect(checkFile(p, good), isEmpty, reason: p);
      }
      // Same content one directory over or in a sibling file still fails.
      expect(checkFile('lib/design/tokens/other_maths.dart', good)
          .map((RuleHit h) => h.rule)
          .toSet(), <String>{'MC-01'});
      expect(checkFile('lib/design/theme_derivation.dart', good), isNotEmpty);
    });

    test('MC-01: the named files fail once they use Flutter (SE-14)', () {
      // VR-07(a) broken samples: a Flutter import, Color(, Colors., fromARGB.
      const String path = 'lib/design/tokens/contrast_guard.dart';
      final Map<String, int> bad = <String, int>{
        "import 'package:flutter/painting.dart';\n": 1,
        'final Object c = Color(0xFF000000);\n': 1,
        'final Object c = Colors.black;\n': 1,
        'final Object c = Color.fromARGB(255, 0, 0, 0);\n': 1,
      };
      bad.forEach((String src, int line) {
        final List<RuleHit> hits = checkFile(path, src);
        expect(hits.map((RuleHit h) => h.rule).toSet(), <String>{'MC-01'},
            reason: src);
        expect(hits.first.line, line, reason: src);
      });
      // A comment that names Color( is not code (lexer).
      expect(checkFile(path, '// returns a Color( later\nconst int x = 1;\n'),
          isEmpty);
    });

    test('MC-01 and MC-08 cells of table 11-2-a name the same files (SE-14)', () {
      final List<String> rows = File(
              'docs/design/ui-spec/11-testing-and-machine-checks.md')
          .readAsLinesSync();
      final String mc01 = rows.singleWhere((String l) => l.startsWith('| MC-01 '));
      final String mc08 = rows.singleWhere((String l) => l.startsWith('| MC-08 '));
      final String allowed01 = mc01.split('|')[4];
      final String allowed08 = mc08.split('|')[4];
      for (final String p in mc01PureDartFiles) {
        expect(allowed01, contains('`$p`'));
      }
      expect(allowed01, contains('`design_tokens.g.dart`'));
      expect(allowed08, contains('`app_motion`'));
      expect(allowed08, contains('`design_tokens.g.dart`'));
    });

    test('MC-11: AppBadge( fails only in the five named files', () {
      const String src = 'Widget b() => const AppBadge();\n';
      for (final String f in <String>[
        'chip',
        'list_row',
        'page_header',
        'bottom_nav',
        'summary_card',
        'app_chip',
      ]) {
        expect(checkFile('lib/c/$f.dart', src).single.rule, 'MC-11', reason: f);
      }
      expect(checkFile('lib/c/chips.dart', src), isEmpty);
    });

    test('MC-13: only top-level named arguments count', () {
      const String src =
          'Widget w() => Positioned(top: 0, child: Foo(left: 1));\n';
      expect(checkFile('lib/a.dart', src), isEmpty);
      expect(checkFile('lib/a.dart', 'Widget w() => Positioned(left: 0);\n')
          .single.rule, 'MC-13');
    });

    test('MC-17: Persian in comments is fine, in strings it is not', () {
      expect(checkFile('lib/a.dart', '// سلام\nconst int x = 1;\n'), isEmpty);
      expect(checkFile('lib/a.dart', r"const String s = '\u06F1';").single.rule,
          'MC-17');
    });
  });

  group('stage', () {
    test('only lib/**.dart is scanned (MC-24)', () {
      final RulesResult r = runRulesStage(<String, String>{
        'test/a_test.dart': 'const Color c = Color(0xFF000000);\n',
        'tool/x.dart': 'const Color c = Color(0xFF000000);\n',
        'lib/notes.txt': 'Color(0xFF000000)\n',
      }, profile: Profile.mvp);
      expect(r.hits, isEmpty);
      expect(r.passed, isTrue);
    });

    test('one line per violation, sorted by path and line (VR-01)', () {
      final RulesResult r = runRulesStage(<String, String>{
        'lib/b.dart': 'int x = 1;\nconst Duration d = Duration(milliseconds: 5);\n',
        'lib/a.dart': 'const TextAlign t = TextAlign.right;\n',
      }, profile: Profile.mvp);
      expect(r.hits.map((RuleHit h) => '${h.rule} ${h.path}:${h.line}'),
          <String>['MC-15 lib/a.dart:1', 'MC-08 lib/b.dart:2']);
      expect(r.report, contains(startsWith('MC-15 lib/a.dart:1 ')));
      expect(r.report, contains('FAIL MC-08 (1)'));
      expect(r.report, contains('PASS MC-01'));
      expect(r.passed, isFalse);
    });

    test('uncovered rows: listed under mvp, failing under full (MC-23)', () {
      final RulesResult mvp = runRulesStage(<String, String>{}, profile: Profile.mvp);
      expect(mvp.passed, isTrue);
      for (final UncoveredRow u in uncoveredRows) {
        expect(mvp.report, contains('UNCOVERED ${u.rule} ${u.reason}'));
      }
      final RulesResult full =
          runRulesStage(<String, String>{}, profile: Profile.full);
      expect(full.passed, isFalse);
      expect(full.findings.single.rule, 'MC-23');
    });

    test('covered and uncovered rows together are table 11-2-a minus MC-02', () {
      final Set<String> all = <String>{
        ...coveredRules.where((String r) => r.startsWith('MC-')),
        ...uncoveredRows.map((UncoveredRow u) => u.rule),
      };
      expect(all, <String>{
        for (int i = 1; i <= 22; i++)
          if (i != 2) 'MC-${i.toString().padLeft(2, '0')}',
      });
    });
  });

  group('cli', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('ui_check_rules'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('rules: exit 1 with the violation line, 0 when clean', () {
      File('${tmp.path}/lib/ui/a.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('const Curve c = Curves.linear;\n');
      final StringBuffer out = StringBuffer();
      expect(runCli(<String>['rules', '--root=${tmp.path}'], out, StringBuffer()), 1);
      expect(out.toString(), contains('MC-08 lib/ui/a.dart:1 '));

      File('${tmp.path}/lib/ui/a.dart').writeAsStringSync('const int c = 1;\n');
      final StringBuffer out2 = StringBuffer();
      expect(runCli(<String>['rules', '--root=${tmp.path}'], out2, StringBuffer()), 0);
      expect(out2.toString(), contains('rules: 0 violation(s)'));
    });

    test('rules --profile=full fails on uncovered rows; bad option is 64', () {
      Directory('${tmp.path}/lib').createSync();
      expect(
          runCli(<String>['rules', '--profile=full', '--root=${tmp.path}'],
              StringBuffer(), StringBuffer()),
          1);
      expect(runCli(<String>['rules', '--bogus'], StringBuffer(), StringBuffer()),
          64);
    });
  });

  test('scan of the real lib/ is clean (printed for the PR; SE-14)', () {
    final StringBuffer out = StringBuffer();
    final int code = runCli(<String>['rules'], out, StringBuffer());
    debugPrint('--- dart run tool/ui_check/ui_check.dart rules (exit $code)');
    debugPrint(out.toString());
    final RulesResult r = runRulesStage(<String, String>{
      for (final FileSystemEntity e in Directory('lib').listSync(recursive: true))
        if (e is File && e.path.endsWith('.dart'))
          e.path.replaceAll(r'\', '/'): e.readAsStringSync(),
    }, profile: Profile.mvp);
    for (final RuleHit h in r.hits) {
      expect(coveredRules, contains(h.rule));
    }
    // After SE-14 the generated token file no longer trips MC-08, so the
    // rules stage is green on lib/ and can become a blocking CI step (VR-02).
    expect(r.hits, isEmpty, reason: r.report.join('\n'));
    expect(code, 0);
  });
}
