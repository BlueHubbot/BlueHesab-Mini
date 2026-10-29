// ui_check: the machine checks of the UI constitution (VR-01).
//
// Implemented stage (T-003): `tokens` (VT-01…VT-06, MC-02, TK-08, AX-02)
// with the MVP profile and manifest (ADR-UI-009). Other stages (MC rules,
// goldens, module matrix) arrive with later tasks.
//
// Usage (from the repository root):
//   dart run tool/ui_check/ui_check.dart tokens [--profile=mvp|full]
//   dart run tool/ui_check/ui_check.dart gen      # rewrite the .g.dart file
// Options: --root=<dir> (default: current directory).
// Exit codes: 0 pass, 1 findings, 64 usage error.

import 'dart:io';

import 'src/generator.dart';
import 'src/manifest.dart';
import 'src/tokens_stage.dart';

/// Repository path of the token file (TK-01, AX-01).
const String tokensPath = 'design/tokens/design_tokens.json';

const String _usage =
    'usage: dart run tool/ui_check/ui_check.dart [tokens|gen] '
    '[--profile=mvp|full] [--root=<dir>]';

void main(List<String> args) {
  exitCode = runCli(args, stdout, stderr);
}

/// Runs the tool and returns the exit code; output goes to [out] and [err].
int runCli(List<String> args, StringSink out, StringSink err) {
  String command = 'tokens';
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
    } else if (a == 'tokens' || a == 'gen') {
      command = a;
    } else {
      err.writeln(_usage);
      return 64;
    }
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
  return result.passed ? 0 : 1;
}
