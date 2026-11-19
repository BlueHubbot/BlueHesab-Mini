// The VR-05 report of one VR-01 run (T-038): one Markdown file with the
// green and red rules, the contrast pair counts per group (VT-02), the
// golden changes (GM-06) and the device profile (PV-03).
//
// The static stage (VR-02) runs only `tokens` and `rules`; the golden and
// device sections are always present (VR-07, report item) and say which stage fills
// them. Pure function over the two stage results: no clock, no absolute
// path, so two runs over the same tree give the same bytes (VR-07, determinism).

import 'contrast.dart' show hundredths;
import 'manifest.dart' show Profile;
import 'rules_stage.dart';
import 'token_registry.dart' show expectedPairCount, separateGroupId;
import 'tokens_stage.dart';

/// Default location of the report, relative to the repository root. `build/`
/// is git-ignored, so the report is never committed (AGENTS.md: no build
/// output in git).
const String defaultReportPath = 'build/ui_check/report.md';

/// The section headings of the report, in order (VR-05; VR-07, report item).
const List<String> reportSections = <String>[
  '## Rules (VR-05)',
  '## Contrast pairs per group (VT-02, VT-03)',
  '## Goldens changed (GM-06)',
  '## Device profile (PV-03)',
  '## Findings',
];

/// A rule checked by the `tokens` stage, with its report label.
final class TokenStageRule {
  const TokenStageRule(this.rule, this.label);

  final String rule;
  final String label;
}

/// The rules the `tokens` stage decides GREEN or RED, in report order.
const List<TokenStageRule> tokenStageRules = <TokenStageRule>[
  TokenStageRule('AX-02', 'file format (UTF-8, LF, key order)'),
  TokenStageRule('VT-01', 'names AXT-01…AXT-13, hex colours, checksum'),
  TokenStageRule('MC-02', 'generated token file equals a fresh generation'),
  TokenStageRule('TK-08', 'dark background is not #000000'),
  TokenStageRule('VT-02', 'contrast thresholds per group'),
  TokenStageRule('VT-03', 'pair count and table 2-8 minima'),
  TokenStageRule('VT-06', 'only the registered groups and colours'),
  TokenStageRule('ADR-UI-009', 'manifest and profile'),
  TokenStageRule('ND-02', 'core destinations in the manifest'),
];

String _fmt(double v) => (hundredths(v) / 100).toStringAsFixed(2);

/// The rule a finding counts against in the Rules table: a contrast group
/// failure (`VTG-nn`) is a VT-02 failure.
String _ruleOf(Finding f) => f.rule.startsWith('VTG-') ? 'VT-02' : f.rule;

/// Builds the report of one run of both static stages.
String buildReport({
  required StageResult tokens,
  required RulesResult rules,
  required Profile profile,
}) {
  final StringBuffer b = StringBuffer();
  void line([String s = '']) => b.write('$s\n');

  final bool passed = tokens.passed && rules.passed;
  line('# ui_check report (VR-05)');
  line();
  line('- Command: `dart run tool/ui_check/ui_check.dart` (VR-01, stage '
      '"static" of VR-02)');
  line('- Profile: ${profile.name} (token checks are never reduced, '
      'ADR-UI-009 §2)');
  line('- Token checksum (AX-02, computed): '
      '${tokens.computedChecksum ?? 'n/a'}');
  line('- Result: ${passed ? 'PASS' : 'FAIL'}');
  line();

  // Rules.
  line(reportSections[0]);
  line();
  line('| Rule | Stage | Status | Findings | Note |');
  line('|---|---|---|---|---|');
  final Map<String, int> tokenCounts = <String, int>{};
  for (final Finding f in tokens.findings) {
    tokenCounts.update(_ruleOf(f), (int n) => n + 1, ifAbsent: () => 1);
  }
  final Set<String> listed = <String>{};
  for (final TokenStageRule r in tokenStageRules) {
    final int n = tokenCounts[r.rule] ?? 0;
    listed.add(r.rule);
    line('| ${r.rule} | tokens | ${n == 0 ? 'GREEN' : 'RED'} | $n | '
        '${r.label} |');
  }
  for (final MapEntry<String, int> e in tokenCounts.entries) {
    if (!listed.contains(e.key)) {
      listed.add(e.key);
      line('| ${e.key} | tokens | RED | ${e.value} | reported by the '
          'manifest check |');
    }
  }
  line('| VT-04 | tokens | EXEMPT | 0 | the only exempt pair: `border` on '
      'the surfaces (DV-04) |');
  line('| VT-05 | tokens | NOT_COVERED | 0 | pixel contrast belongs to '
      'component widget tests |');
  for (final String rule in coveredRules) {
    final int n = rules.hits.where((RuleHit h) => h.rule == rule).length;
    line('| $rule | rules | ${n == 0 ? 'GREEN' : 'RED'} | $n | pattern row '
        'of table 11-2-a |');
  }
  final int profileFindings =
      rules.findings.where((Finding f) => f.rule == 'MC-23').length;
  for (final UncoveredRow u in uncoveredRows) {
    line('| ${u.rule} | rules | UNCOVERED | - | ${u.reason} |');
  }
  line();
  line('UNCOVERED rows do not pass a gate (MC-23)'
      '${profileFindings > 0 ? '; profile=full counts them as a finding' : ''}'
      '.');
  line();

  // Contrast.
  line(reportSections[1]);
  line();
  if (tokens.groups.isEmpty) {
    line('Not computed: the token file could not be read (see Findings).');
  } else {
    line('| Group | Threshold | Pairs per theme | Min light | Min dark |');
    line('|---|---|---|---|---|');
    int total = 0;
    for (final GroupSummary g in tokens.groups) {
      final String light = g.minLight == null ? 'n/a' : _fmt(g.minLight!);
      final String dark = g.minDark == null ? 'n/a' : _fmt(g.minDark!);
      final String id =
          g.id == separateGroupId ? '${g.id} (reported apart)' : g.id;
      line('| $id | ${g.threshold} | ${g.pairsPerTheme} | $light | $dark |');
      if (g.id != separateGroupId) {
        total += g.pairsPerTheme * 2;
      }
    }
    line();
    line('VTG-01…VTG-09: $total pair checks over both themes (expected '
        '$expectedPairCount).');
  }
  line();

  // Goldens.
  line(reportSections[2]);
  line();
  line('Not run by this command: goldens belong to the "test" stage of VR-02 '
      '(`flutter test`). The list of changed goldens with before and after '
      'images is added here when the golden matrix exists (GMX-01…GMX-04).');
  line();

  // Device profile.
  line(reportSections[3]);
  line();
  line('Not run by this command: the PV-03 profile belongs to the "device" '
      'stage of VR-02 and runs before each gate of section 14.');
  line();

  // Findings.
  line(reportSections[4]);
  line();
  final List<Finding> all = <Finding>[...tokens.findings, ...rules.findings];
  if (all.isEmpty) {
    line('None.');
  } else {
    for (final Finding f in all) {
      line('- `${f.rule}` ${f.message}');
    }
  }
  return b.toString();
}
