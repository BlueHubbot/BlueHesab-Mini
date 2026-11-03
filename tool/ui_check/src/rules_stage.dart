// The `rules` stage of ui_check (T-016): the pattern rows of table 11-2-a
// (MC-01…MC-17) and the hidden-exemption scan (VR-03), over `lib/` only
// (MC-24). One line per violation with rule ID, file and line (VR-01).
//
// Pure function over file contents so the tool tests (VR-07, MC-23) can feed
// fixtures. Code patterns run on the lexer's `code` view (comments and string
// bodies blanked), MC-01/08/14/17 also look inside string literals, VR-03
// looks only inside comments.
//
// "Allowed in" (VR-03: the column is the only exemption; MC-01 and MC-08
// cells as amended by SE-14). Where the column
// names a file that does not exist yet, the narrowest file name it implies is
// used, one constant per rule; changing one needs Agent 1 approval (AGR-01).

import 'dart_lexer.dart';
import 'generator.dart' show generatedPath;
import 'manifest.dart' show Profile;
import 'tokens_stage.dart' show Finding;

/// One violation of a rule at one line.
final class RuleHit {
  const RuleHit(this.rule, this.path, this.line, this.message);

  final String rule;
  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$rule $path:$line $message';
}

/// A row of table 11-2-a with no check in this stage, and why.
final class UncoveredRow {
  const UncoveredRow(this.rule, this.reason);

  final String rule;
  final String reason;
}

/// Output of [runRulesStage].
final class RulesResult {
  RulesResult(this.hits, this.findings, this.report);

  /// Every violation in lib/, sorted by path, line, rule.
  final List<RuleHit> hits;

  /// [hits] plus the profile finding (MC-23 under `--profile=full`).
  final List<Finding> findings;

  /// The report lines.
  final List<String> report;

  bool get passed => findings.isEmpty;
}

/// Rows checked here, in table order (VR-03 last).
const List<String> coveredRules = <String>[
  'MC-01',
  'MC-03',
  'MC-05',
  'MC-07',
  'MC-08',
  'MC-09',
  'MC-10',
  'MC-11',
  'MC-13',
  'MC-14',
  'MC-15',
  'MC-16',
  'MC-17',
  'VR-03',
];

/// Rows of table 11-2-a not checked by this stage (MC-02 is in `tokens`).
const List<UncoveredRow> uncoveredRows = <UncoveredRow>[
  UncoveredRow('MC-04',
      'needs the component catalogue (table 7-0) and golden review by Agent 1'),
  UncoveredRow('MC-06',
      'lint row: needs static types (package:analyzer has no audit row yet)'),
  UncoveredRow('MC-12',
      'needs the AppDivider and CM-12 frame files (component tasks)'),
  UncoveredRow('MC-18',
      'lint row: needs the static type MoneyVM (package:analyzer)'),
  UncoveredRow('MC-19',
      'lint row: needs the static money type (package:analyzer)'),
  UncoveredRow('MC-20', 'ADR-UI-006 has not chosen a chart library'),
  UncoveredRow('MC-21', 'the copy catalog (CM-10) does not exist yet'),
  UncoveredRow('MC-22', 'the Style Guide (T-010) does not exist yet'),
];

// ---------------------------------------------------------------- paths

String _base(String path) => path.substring(path.lastIndexOf('/') + 1);

bool _isGenerated(String path) => path == generatedPath;

/// MC-01 "allowed in" (SE-14, ADVISOR_REPLY-003): the two pure-Dart colour
/// maths files of the custom theme (ADR-UI-011 §3). Exactly these two paths,
/// not their directory (VR-03), and only while they stay pure Dart.
const Set<String> mc01PureDartFiles = <String>{
  'lib/design/tokens/theme_derivation.dart',
  'lib/design/tokens/contrast_guard.dart',
};

/// What still fails MC-01 inside [mc01PureDartFiles]: Flutter colour types.
final List<RegExp> _mc01PureCode = <RegExp>[
  _re(r'Color\s*\('),
  _re(r'(?:Cupertino)?Colors\.'),
  _re(r'Color\.from(?:RGBO|ARGB)\b'),
];

/// ... and any Flutter import (the exception holds only for pure Dart).
final RegExp _flutterImport = RegExp(r'^package:flutter/');

/// MC-08 "package app_motion": any directory segment `app_motion/`.
final RegExp _appMotion = RegExp(r'(^|/)app_motion/');

/// MC-09 "platform adapter".
final RegExp _platformAdapter = RegExp(r'(^|/)platform_adapter(/|[^/]*\.dart$)');

/// MC-10: PulseDot and BrandMark files, the QuickAdd button, AssistantPage,
/// AIActionCard.
const Set<String> _pulseDotFiles = <String>{
  'pulse_dot.dart',
  'brand_mark.dart',
  'quick_add_button.dart',
  'assistant_page.dart',
  'ai_action_card.dart',
};

/// MC-11: the five files where `AppBadge(` is forbidden.
final RegExp _noBadgeFiles =
    RegExp(r'^(app_)?(chip|list_row|page_header|bottom_nav|summary_card)\.dart$');

/// MC-13: `numeric_cell.dart`.
bool _isNumericCell(String path) => _base(path) == 'numeric_cell.dart';

/// MC-14, MC-15: BidiText, the central formatter, `numeric_cell.dart`.
final RegExp _bidiFiles =
    RegExp(r'^(bidi_text|numeric_cell|[a-z0-9_]*formatter)\.dart$');

/// MC-17: the generated copy catalog (section 9) and the Style Guide folder.
final RegExp _persianAllowed =
    RegExp(r'(^|/)style_guide/|(^|/)copy_catalog\.g\.dart$');

// ---------------------------------------------------------------- patterns

const String _nb = r'(?<![A-Za-z0-9_$])'; // not preceded by an identifier char

RegExp _re(String body) => RegExp(_nb + body);

final List<RegExp> _mc01Code = <RegExp>[
  _re(r'Color\(\s*0[xX]'),
  _re(r'(?:Cupertino)?Colors\.'),
  _re(r'Color\.from(?:RGBO|ARGB)\b'),
  _re(r'0[xX](?:[0-9A-Fa-f]{8}|[0-9A-Fa-f]{6})(?![0-9A-Za-z_])'),
];
final RegExp _mc01String = RegExp(r'#(?:[0-9A-Fa-f]{8}|[0-9A-Fa-f]{6})(?![0-9A-Fa-f])');

final List<RegExp> _mc03 = <RegExp>[
  RegExp(r'\.\s*colorScheme\b'),
  RegExp(r'Theme\s*\.\s*of\s*\([^)]*\)\s*\.\s*[a-z]\w*Color\b'),
];

final List<RegExp> _mc05 = <RegExp>[
  _re(r'(?:Box)?Shadow\('),
  _re(r'elevation\s*:'),
  _re(r'BackdropFilter\('),
  _re(r'ImageFilter\s*\.\s*blur\b'),
  _re(r'(?:Linear|Radial|Sweep)Gradient\('),
];

final List<RegExp> _mc08Code = <RegExp>[
  _re(r'Duration\(\s*milliseconds\s*:'),
  _re(r'Curves\s*\.'),
  _re(r'AnimationController(?:\.\w+)?\s*\('),
  _re(r'AnimatedContainer\('),
  _re(r'AnimatedSize\('),
  _re(r'AnimatedPositioned\('),
  _re(r'TweenAnimationBuilder(?:<[^>]*>)?\('),
  _re(r'Hero\('),
  _re(r'Lottie(?:[A-Z]\w*)?\b'),
  _re(r'Rive(?:[A-Z]\w*)?\b'),
];
final RegExp _mc08Import = RegExp(r'^package:(?:lottie|rive)/');

final List<RegExp> _mc09 = <RegExp>[
  _re(r'Platform\s*\.\s*(?:is[A-Z]\w*|operatingSystem)\b'),
  _re(r'defaultTargetPlatform\b'),
];

final RegExp _mc10 = _re(r'PulseDot(?:\.\w+)?\s*\(');
final RegExp _mc11 = _re(r'AppBadge(?:\.\w+)?\s*\(');

/// MC-13: (call opener, forbidden top-level argument or null = always).
final List<(RegExp, RegExp?)> _mc13 = <(RegExp, RegExp?)>[
  (_re(r'EdgeInsets\s*\.\s*only\s*\('), _re(r'(?:left|right)\s*:')),
  (_re(r'EdgeInsets\s*\.\s*fromLTRB\s*\('), null),
  (_re(r'Positioned\s*\('), _re(r'(?:left|right)\s*:')),
  (
    _re(r'BorderRadius\s*\.\s*only\s*\('),
    _re(r'(?:top|bottom)(?:Left|Right)\s*:')
  ),
  (_re(r'BorderRadius\s*\.\s*horizontal\s*\('), _re(r'(?:left|right)\s*:')),
];

final RegExp _mc14Chars = RegExp('[\u2066\u2068\u2069\u200E\u200F]');
final RegExp _mc14Escape =
    RegExp(r'\\u(?:\{0*)?(?:2066|2068|2069|200[eEfF])\}?');

final List<RegExp> _mc15 = <RegExp>[
  _re(r'TextAlign\s*\.\s*(?:left|right)\b'),
  _re(r'Alignment\s*\.\s*center(?:Left|Right)\b'),
];

final List<RegExp> _mc16 = <RegExp>[
  _re(r'(?:Bidi\s*\.\s*)?(?:detectRtlDirectionality|estimateDirectionOfText|isRtlLanguage)\b'),
  _re(r'TextDirection\s*\.\s*values\s*\.\s*byName\s*\('),
];

final RegExp _mc17Chars =
    RegExp('[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]');
final RegExp _mc17Escape = RegExp(
    r'\\u(?:\{0*)?(?:06[0-9A-Fa-f]{2}|F[B-D][0-9A-Fa-f]{2}|FE[7-9A-Fa-f][0-9A-Fa-f])\}?',
    caseSensitive: false);

final List<RegExp> _vr03 = <RegExp>[
  RegExp(r'ui_check\s*[:=-]?\s*(?:ignore|disable|off|skip|allow|exempt)',
      caseSensitive: false),
  RegExp(r'\b(?:ignore|disable|nolint|noqa|exempt)\b[^\n]*\b(?:MC|VT)-\d{2}',
      caseSensitive: false),
];

// ---------------------------------------------------------------- checks

/// Index after the `)` that closes the `(` at [open] in [code], or -1.
int _closeParen(String code, int open) {
  int depth = 0;
  for (int i = open; i < code.length; i++) {
    final String c = code[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) {
        return i + 1;
      }
    }
  }
  return -1;
}

/// The argument text of a call with nested brackets blanked, so only
/// top-level named arguments remain visible.
String _topLevel(String inner) {
  final StringBuffer b = StringBuffer();
  int depth = 0;
  for (int i = 0; i < inner.length; i++) {
    final String c = inner[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
      b.write(' ');
    } else if (c == ')' || c == ']' || c == '}') {
      depth--;
      b.write(' ');
    } else {
      b.write(depth == 0 ? c : ' ');
    }
  }
  return b.toString();
}

/// Checks one file; [path] is repository-relative with `/`.
List<RuleHit> checkFile(String path, String source) {
  final Lexed lx = Lexed(source);
  final String code = lx.code;
  final String base = _base(path);
  final List<RuleHit> hits = <RuleHit>[];
  final Set<String> seen = <String>{};

  void hit(String rule, int line, String message) {
    if (seen.add('$rule:$line')) {
      hits.add(RuleHit(rule, path, line, message));
    }
  }

  void codeRule(String rule, List<RegExp> patterns, String where) {
    for (final RegExp re in patterns) {
      for (final RegExpMatch m in re.allMatches(code)) {
        hit(rule, lx.lineOf(m.start), '`${m[0]!.trim()}` $where');
      }
    }
  }

  void callRule(String rule, RegExp opener, RegExp? arg, String where) {
    for (final RegExpMatch m in opener.allMatches(code)) {
      final int open = code.lastIndexOf('(', m.end - 1);
      final int close = _closeParen(code, open);
      final String inner =
          close < 0 ? code.substring(open + 1) : code.substring(open + 1, close - 1);
      final RegExpMatch? a = arg?.firstMatch(_topLevel(inner));
      if (arg == null || a != null) {
        final String what = a == null
            ? m[0]!.replaceAll(RegExp(r'\s+'), '')
            : '${m[0]!.replaceAll(RegExp(r'\s+'), '')} ${a[0]!.replaceAll(RegExp(r'\s+'), '')}';
        hit(rule, lx.lineOf(m.start), '`$what` $where');
      }
    }
  }

  // MC-01 (TK-02): colours only in the generated token file, plus hex
  // numbers in the two named pure-Dart files (SE-14).
  if (mc01PureDartFiles.contains(path)) {
    codeRule('MC-01', _mc01PureCode,
        'in a pure-Dart colour file: Flutter colour types are not allowed (SE-14)');
    for (final StringPart s in lx.strings) {
      if (_flutterImport.hasMatch(s.text)) {
        hit('MC-01', s.line,
            'import `${s.text}` in a pure-Dart colour file (SE-14)');
      }
    }
  } else if (!_isGenerated(path)) {
    codeRule('MC-01', _mc01Code, 'outside $generatedPath (TK-02)');
    for (final StringPart s in lx.strings) {
      final RegExpMatch? m = _mc01String.firstMatch(s.text);
      if (m != null) {
        hit('MC-01', s.line, 'hex colour `${m[0]}` in a string (TK-02)');
      }
    }
  }

  // MC-03 (TK-03): colours only from context.colors / context.accent. The
  // ThemeData file is named by ADR-UI-007 (not yet written): no exemption.
  codeRule('MC-03', _mc03,
      'outside context.colors/context.accent (TK-03; ThemeData file not named yet)');

  // MC-05 (TK-10, TK-12): shadows, blur, gradients.
  if (!_isGenerated(path)) {
    codeRule('MC-05', _mc05, 'outside $generatedPath (TK-10, TK-12)');
  }

  // MC-07 (TY-02): TextStyle( with fontSize:.
  if (!_isGenerated(path)) {
    callRule('MC-07', _re(r'TextStyle\s*\('), _re(r'fontSize\s*:'),
        'outside the generated type roles (TY-02)');
  }

  // MC-08 (MX-03, CM-08): motion only in package app_motion and the
  // generated token file (SE-14: the §4-2 durations come from appendix A).
  if (!_appMotion.hasMatch(path) && !_isGenerated(path)) {
    codeRule('MC-08', _mc08Code, 'outside package app_motion (MX-03)');
    for (final StringPart s in lx.strings) {
      if (_mc08Import.hasMatch(s.text)) {
        hit('MC-08', s.line, 'import `${s.text}` outside package app_motion (MX-03)');
      }
    }
  }

  // MC-09 (TK-14): platform checks only in the platform adapter.
  if (!_platformAdapter.hasMatch(path)) {
    codeRule('MC-09', _mc09, 'outside the platform adapter (TK-14)');
  }

  // MC-10 (PD-01): PulseDot only in its three places.
  if (!_pulseDotFiles.contains(base)) {
    codeRule('MC-10', <RegExp>[_mc10],
        'outside PulseDot/BrandMark/QuickAdd button/AssistantPage/AIActionCard (PD-01)');
  }

  // MC-11 (BG-07): no AppBadge in chip, list_row, page_header, bottom_nav,
  // summary_card.
  if (_noBadgeFiles.hasMatch(base)) {
    codeRule('MC-11', <RegExp>[_mc11], 'in $base (BG-07)');
  }

  // MC-13 (RT-02, RT-05): physical left/right only in numeric_cell.dart.
  if (!_isNumericCell(path)) {
    for (final (RegExp opener, RegExp? arg) in _mc13) {
      callRule('MC-13', opener, arg, 'outside numeric_cell.dart (RT-02, RT-05)');
    }
  }

  // MC-14 (NC-11, RT-04): raw bidi controls in strings.
  if (!_bidiFiles.hasMatch(base)) {
    for (final StringPart s in lx.strings) {
      final bool raw = _mc14Chars.hasMatch(s.text);
      final bool escaped = !s.raw && _mc14Escape.hasMatch(s.text);
      if (raw || escaped) {
        hit('MC-14', s.line,
            'bidi control (FSI/LRI/PDI/LRM/RLM) in a string outside BidiText, the formatter, numeric_cell.dart (NC-11)');
      }
    }
  }

  // MC-15 (NC-11): physical text alignment.
  if (!_bidiFiles.hasMatch(base)) {
    codeRule('MC-15', _mc15,
        'outside BidiText, the formatter, numeric_cell.dart (NC-11)');
  }

  // MC-16 (RT-01): direction from text, nowhere.
  codeRule('MC-16', _mc16, 'direction guessed from text (RT-01)');

  // MC-17 (CM-10, TQ-16, SG-04): Persian strings in code.
  if (!_persianAllowed.hasMatch(path)) {
    for (final StringPart s in lx.strings) {
      final bool raw = _mc17Chars.hasMatch(s.text);
      final bool escaped = !s.raw && _mc17Escape.hasMatch(s.text);
      if (raw || escaped) {
        hit('MC-17', s.line,
            'Persian/Arabic text in a string literal outside the copy catalog (CM-10)');
      }
    }
  }

  // VR-03: no comment may switch a rule off.
  for (final CommentPart c in lx.comments) {
    for (final RegExp re in _vr03) {
      final RegExpMatch? m = re.firstMatch(c.text);
      if (m != null) {
        final int line = c.line + '\n'.allMatches(c.text.substring(0, m.start)).length;
        hit('VR-03', line, 'comment disables a rule: `${m[0]}`');
        break;
      }
    }
  }

  hits.sort((RuleHit a, RuleHit b) {
    final int byLine = a.line.compareTo(b.line);
    return byLine != 0 ? byLine : a.rule.compareTo(b.rule);
  });
  return hits;
}

/// Runs the stage over [files] (repository-relative path → content). Only
/// paths under `lib/` ending in `.dart` are scanned (MC-24).
RulesResult runRulesStage(Map<String, String> files, {required Profile profile}) {
  final List<String> paths = files.keys
      .where((String p) => p.startsWith('lib/') && p.endsWith('.dart'))
      .toList()
    ..sort();
  final List<RuleHit> hits = <RuleHit>[];
  for (final String p in paths) {
    hits.addAll(checkFile(p, files[p]!));
  }

  final List<String> report = <String>[
    'rules: ${paths.length} file(s) under lib/ (MC-24)',
    for (final RuleHit h in hits) h.toString(),
  ];
  for (final String rule in coveredRules) {
    final int n = hits.where((RuleHit h) => h.rule == rule).length;
    report.add(n == 0 ? 'PASS $rule' : 'FAIL $rule ($n)');
  }
  for (final UncoveredRow u in uncoveredRows) {
    report.add('UNCOVERED ${u.rule} ${u.reason}');
  }

  final List<Finding> findings = <Finding>[
    for (final RuleHit h in hits) Finding(h.rule, '${h.path}:${h.line} ${h.message}'),
  ];
  final String uncovered = uncoveredRows.map((UncoveredRow u) => u.rule).join(', ');
  if (profile == Profile.full) {
    findings.add(Finding('MC-23',
        'profile=full: rows without a check do not pass the gate: $uncovered'));
    report.add('MC-23 profile=full: rows without a check: $uncovered');
  } else {
    report.add('profile=mvp: ${uncoveredRows.length} row(s) UNCOVERED, listed '
        'above (MC-23: they must be covered before the gate passes)');
  }
  report.add('rules: ${hits.length} violation(s)');
  return RulesResult(hits, findings, report);
}
