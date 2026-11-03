// ui_check: the machine checks of the UI constitution (VR-01).
//
// Implemented stages: `tokens` (T-003: VT-01…VT-06, MC-02, TK-08, AX-02)
// with the MVP profile and manifest (ADR-UI-009), and `rules` (T-016: the
// pattern rows of table 11-2-a and VR-03 over lib/). Goldens and the module
// matrix arrive with later tasks.
//
// Usage (from the repository root):
//   dart run tool/ui_check/ui_check.dart [--profile=mvp|full]  # all stages
//   dart run tool/ui_check/ui_check.dart tokens [--profile=mvp|full]
//   dart run tool/ui_check/ui_check.dart rules [--profile=mvp|full]
//   dart run tool/ui_check/ui_check.dart gen      # rewrite the .g.dart file
// Options: --root=<dir> (default: current directory).
// Exit codes: 0 pass, 1 findings, 64 usage error.

import 'dart:io';

import 'src/generator.dart';
import 'src/manifest.dart';
import 'src/rules_stage.dart';
import 'src/tokens_stage.dart';

/// Repository path of the token file (TK-01, AX-01).
const String tokensPath = 'design/tokens/design_tokens.json';

const String _usage =
    'usage: dart run tool/ui_check/ui_check.dart [all|tokens|rules|gen] '
    '[--profile=mvp|full] [--root=<dir>]';

void main(List<String> args) {
  exitCode = runCli(args, stdout, stderr);
}

/// Runs the tool and returns the exit code; output goes to [out] and [err].
int runCli(List<String> args, StringSink out, StringSink err) {
  String command = 'all';
  Profile profile = Profile.mvp;
  String root = '.';
  for (final String a in args) {
    if (a.startsWith('--profile=')) {
      final Profile? p = parseProfile(a.substring('--profile='.length));
      if (p == null) {
        err.writeln(_usage);
        return 64;
      }
      profile = p;
    } else if (a.startsWith('--root=')) {
      root = a.substring('--root='.length);
    } else if (a == 'all' || a == 'tokens' || a == 'rules' || a == 'gen') {
      command = a;
    } else {
      err.writeln(_usage);
      return 64;
    }
  }

  if (command == 'rules') {
    return _runRules(root, profile, out);
  }

  final File json = File('$root/$tokensPath');
  if (!json.existsSync()) {
    err.writeln('VT-01 $tokensPath not found under $root');
    return 1;
  }
  final List<int> jsonBytes = json.readAsBytesSync();

  if (command == 'gen') {
    final String? source = generateFromBytes(jsonBytes);
    if (source == null) {
      err.writeln('gen refused: $tokensPath does not have the structure of '
          'appendix A (run the tokens stage for the findings)');
      return 1;
    }
    File('$root/$generatedPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(source);
    out.writeln('wrote $generatedPath');
    return 0;
  }

  final File generated = File('$root/$generatedPath');
  final File manifest = File('$root/$manifestPath');
  final StageResult result = runTokensStage(
    jsonBytes: jsonBytes,
    generatedBytes: generated.existsSync() ? generated.readAsBytesSync() : null,
    manifestBytes: manifest.existsSync() ? manifest.readAsBytesSync() : null,
    profile: profile,
  );
  for (final String line in result.report) {
    out.writeln(line);
  }
  if (command == 'all') {
    final int rules = _runRules(root, profile, out);
    return result.passed && rules == 0 ? 0 : 1;
  }
  return result.passed ? 0 : 1;
}

/// Reads every `.dart` file under `<root>/lib` (MC-24) and runs the rules
/// stage; returns the exit code.
int _runRules(String root, Profile profile, StringSink out) {
  final Map<String, String> files = <String, String>{};
  final Directory lib = Directory('$root/lib');
  if (lib.existsSync()) {
    for (final FileSystemEntity e in lib.listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.dart')) {
        final String rel = 'lib/'
            '${e.path.substring(lib.path.length + 1).replaceAll('\\', '/')}';
        files[rel] = e.readAsStringSync();
      }
    }
  }
  final RulesResult result = runRulesStage(files, profile: profile);
  for (final String line in result.report) {
    out.writeln(line);
  }
  return result.passed ? 0 : 1;
}
