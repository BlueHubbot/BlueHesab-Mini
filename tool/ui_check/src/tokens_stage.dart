// The `tokens` stage of ui_check (VT-01…VT-06, MC-02, TK-08, AX-02) plus the
// profile/manifest part of the VR-05 report (ADR-UI-009 §1).
//
// Pure function over bytes so the tool tests (VR-07) can feed it broken
// fixtures without touching the repository files.

import 'dart:convert';

import 'contrast.dart';
import 'generator.dart';
import 'manifest.dart';
import 'sha256.dart';
import 'token_registry.dart';

/// One violation: the rule ID it breaks and a message.
final class Finding {
  const Finding(this.rule, this.message);

  /// Rule ID, e.g. `VT-01`, `MC-02`, `TK-08` or a group ID like `VTG-03`.
  final String rule;
  final String message;

  @override
  String toString() => '$rule $message';
}

/// Contrast summary of one group for the report (VT-02).
final class GroupSummary {
  GroupSummary(this.id, this.threshold);

  final String id;
  final double threshold;
  int pairsPerTheme = 0;
  double? minLight;
  double? minDark;
}

/// Output of [runTokensStage].
final class StageResult {
  StageResult(this.findings, this.report, this.computedChecksum);

  /// Every violation, in the order found.
  final List<Finding> findings;

  /// The report lines (VR-05 subset for this stage).
  final List<String> report;

  /// sha256 of the token file with an empty `checksum` (AX-02).
  final String? computedChecksum;

  bool get passed => findings.isEmpty;

  /// Rule IDs that failed, without duplicates, in order.
  List<String> get failedRules {
    final List<String> out = <String>[];
    for (final Finding f in findings) {
      if (!out.contains(f.rule)) {
        out.add(f.rule);
      }
    }
    return out;
  }
}

final RegExp _checksumField = RegExp(r'"checksum"\s*:\s*"[0-9a-fA-F]*"');

/// sha256 of [jsonBytes] after `meta.checksum` is replaced by `""`
/// (AX-02, VT-01 step 3). Null when the field is absent.
String? tokenChecksum(List<int> jsonBytes) {
  final String text = utf8.decode(jsonBytes);
  final RegExpMatch? m = _checksumField.firstMatch(text);
  if (m == null) {
    return null;
  }
  final String blank =
      text.replaceRange(m.start, m.end, '"checksum": ""');
  return sha256Hex(utf8.encode(blank));
}

Object? _at(Object? root, String path) {
  if (path.isEmpty) {
    return root;
  }
  Object? cur = root;
  for (final String part in path.split('.')) {
    if (cur is! Map<String, Object?>) {
      return null;
    }
    cur = cur[part];
  }
  return cur;
}

String _fmt(double v) => (hundredths(v) / 100).toStringAsFixed(2);

Object? _decode(List<int> bytes) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return null;
  }
}

String? _generate(
  Map<String, Object?> tokens,
  void Function(String rule, String message) fail,
) {
  try {
    return generateDart(tokens);
  } on Object catch (e) {
    fail('MC-02', 'cannot generate $generatedPath: $e');
    return null;
  }
}

/// Runs the stage. [generatedBytes] or [manifestBytes] may be null when the
/// file does not exist; both cases are failures.
StageResult runTokensStage({
  required List<int> jsonBytes,
  required List<int>? generatedBytes,
  required List<int>? manifestBytes,
  required Profile profile,
}) {
  final List<Finding> findings = <Finding>[];
  final List<String> report = <String>[];
  void fail(String rule, String message) =>
      findings.add(Finding(rule, message));

  // AX-02: file format.
  if (jsonBytes.length >= 3 &&
      jsonBytes[0] == 0xEF &&
      jsonBytes[1] == 0xBB &&
      jsonBytes[2] == 0xBF) {
    fail('AX-02', 'design_tokens.json starts with a BOM');
  }
  if (jsonBytes.contains(0x0D)) {
    fail('AX-02', 'design_tokens.json has CR characters (LF only)');
  }
  if (jsonBytes.isEmpty ||
      jsonBytes.last != 0x0A ||
      (jsonBytes.length >= 2 && jsonBytes[jsonBytes.length - 2] == 0x0A)) {
    fail('AX-02', 'design_tokens.json must end with exactly one LF');
  }

  final Object? decoded = _decode(jsonBytes);
  if (decoded is! Map<String, Object?>) {
    fail('VT-01', 'design_tokens.json is not a readable JSON object');
    return StageResult(
      findings,
      <String>[for (final Finding f in findings) '  $f', 'Result: FAIL'],
      null,
    );
  }
  final Map<String, Object?> tokens = decoded;

  // VT-01 step 1: names against table A-2-a (AX-03); AX-02 key order.
  bool namesOk = true;
  for (final RegistryEntry entry in registry()) {
    final Object? node = _at(tokens, entry.path);
    final String where = entry.path.isEmpty ? '(root)' : entry.path;
    if (node is! Map<String, Object?>) {
      fail('VT-01', '${entry.axt} "$where" is missing or not an object');
      namesOk = false;
      continue;
    }
    final List<String> actual = node.keys.toList();
    bool entryOk = true;
    for (final String k in actual) {
      if (!entry.keys.contains(k)) {
        fail('VT-01', '${entry.axt} unregistered name "$where.$k"');
        entryOk = false;
      }
    }
    for (final String k in entry.keys) {
      if (!actual.contains(k)) {
        fail('VT-01', '${entry.axt} registered name "$where.$k" is missing');
        entryOk = false;
      }
    }
    if (!entryOk) {
      namesOk = false;
    } else if (actual.join(',') != entry.keys.join(',')) {
      fail('AX-02', '${entry.axt} keys of "$where" are not in the order of '
          'block A-3');
    }
  }

  // VT-01 step 5: six-digit hex colours; alias targets exist.
  final List<String> names = colorNames();
  final Map<String, Map<String, String>> themes = <String, Map<String, String>>{};
  for (final String theme in <String>['light', 'dark']) {
    final Object? c = _at(tokens, 'color.$theme');
    final Map<String, String> colors = <String, String>{};
    if (c is Map<String, Object?>) {
      for (final MapEntry<String, Object?> e in c.entries) {
        final Object? v = e.value;
        if (v is String && isHex6(v)) {
          colors[e.key] = v;
        } else {
          fail('VT-01', 'color.$theme.${e.key} = $v is not a six-digit hex '
              'colour');
        }
      }
    }
    themes[theme] = colors;
  }
  final Object? elevation = tokens['elevation'];
  if (elevation is Map<String, Object?>) {
    for (final MapEntry<String, Object?> level in elevation.entries) {
      final Object? l = level.value;
      if (l is! Map<String, Object?>) {
        continue;
      }
      for (final MapEntry<String, Object?> t in l.entries) {
        final Object? shadow = t.value;
        final Object? col = shadow is Map<String, Object?> ? shadow['color'] : null;
        if (col is! String || !isHex6(col)) {
          fail('VT-01', 'elevation.${level.key}.${t.key}.color = $col is not '
              'a six-digit hex colour');
        }
      }
    }
  }
  final Object? alias = tokens['alias'];
  if (alias is Map<String, Object?>) {
    for (final MapEntry<String, Object?> a in alias.entries) {
      if (!names.contains(a.value)) {
        fail('VT-01', 'alias.${a.key} points to "${a.value}", which is not a '
            'colour token');
      }
    }
  }

  // VT-01 step 3: checksum (AX-02).
  final String? computed = tokenChecksum(jsonBytes);
  final Object? stored = _at(tokens, 'meta.checksum');
  if (computed == null) {
    fail('VT-01', 'meta.checksum is missing');
  } else if (stored != computed) {
    fail('VT-01', 'checksum mismatch: file has "$stored", computed '
        '"$computed" (a token change needs an ADR that updates meta.checksum '
        'and AX-02 together, AX-07)');
  }

  // TK-08: dark background is never pure black.
  final String? darkBg = themes['dark']!['background'];
  if (darkBg != null && darkBg.toUpperCase() == '#000000') {
    fail('TK-08', 'color.dark.background is #000000');
  }

  // VT-01 step 2 / MC-02: the committed generated file equals a fresh one.
  if (generatedBytes == null) {
    fail('MC-02', '$generatedPath is missing (run: dart run '
        'tool/ui_check/ui_check.dart gen)');
  } else if (namesOk) {
    final String? fresh = _generate(tokens, fail);
    if (fresh != null) {
      final String committed = utf8.decode(generatedBytes, allowMalformed: true);
      if (committed != fresh) {
        final List<String> a = committed.split('\n');
        final List<String> b = fresh.split('\n');
        int line = 0;
        while (line < a.length && line < b.length && a[line] == b[line]) {
          line++;
        }
        final String got = line < a.length ? a[line] : '<end of file>';
        final String want = line < b.length ? b[line] : '<end of file>';
        fail('MC-02', '$generatedPath differs from a fresh generation at '
            'line ${line + 1}: has "$got", expected "$want" (edited by hand?)');
      }
    }
  }

  // VT-02, VT-03, VT-06: contrast groups.
  final List<GroupSummary> summaries = <GroupSummary>[];
  final Object? groupsNode = _at(tokens, 'contrast.groups');
  final List<Object?> groups =
      groupsNode is List<Object?> ? groupsNode : <Object?>[];
  final List<String> ids = <String>[
    for (final Object? g in groups)
      if (g is Map<String, Object?>) '${g['id']}' else '?',
  ];
  final List<String> expectedIds =
      contrastGroups.map((GroupSpec g) => g.id).toList();
  if (ids.join(',') != expectedIds.join(',')) {
    fail('VT-06', 'contrast.groups must be ${expectedIds.join(', ')} in '
        'order; found ${ids.join(', ')} (a new pair needs an ADR, AGX-05)');
  }
  final Object? surfaces = _at(tokens, 'contrast.surfaces');
  if (surfaces is! List<Object?> ||
      surfaces.join(',') != 'background,surface,surface-raised') {
    fail('VT-01', 'contrast.surfaces must be background, surface, '
        'surface-raised');
  }

  int counted = 0;
  for (final GroupSpec spec in contrastGroups) {
    final GroupSummary summary = GroupSummary(spec.id, spec.threshold);
    summaries.add(summary);
    Map<String, Object?>? group;
    for (final Object? g in groups) {
      if (g is Map<String, Object?> && g['id'] == spec.id) {
        group = g;
      }
    }
    if (group == null) {
      continue;
    }
    final Object? threshold = group['threshold'];
    if (threshold is! num || threshold.toDouble() != spec.threshold) {
      fail('VT-02', '${spec.id} threshold is $threshold, table 2-8 says '
          '${spec.threshold}');
    }
    final Object? sets = group['sets'];
    if (sets is! List<Object?> || sets.isEmpty) {
      fail('VT-06', '${spec.id} has no sets');
      continue;
    }
    int setIndex = 0;
    for (final Object? s in sets) {
      setIndex++;
      final String label = '${spec.id} set $setIndex';
      if (s is! Map<String, Object?>) {
        fail('VT-06', '$label is not an object');
        continue;
      }
      final Object? fgNode = s['fg'];
      final Object? bgNode = s['bg'];
      final Object? mode = s['mode'];
      if (fgNode is! List<Object?> || bgNode is! List<Object?>) {
        fail('VT-06', '$label needs "fg" and "bg" lists');
        continue;
      }
      final List<String> fg = fgNode.map((Object? e) => '$e').toList();
      final List<String> bg = bgNode.map((Object? e) => '$e').toList();
      bool known = true;
      for (final String n in <String>[...fg, ...bg]) {
        if (!names.contains(n)) {
          fail('VT-06', '$label uses "$n", which is not a colour token');
          known = false;
        }
      }
      final List<List<String>> pairs = <List<String>>[];
      if (mode == 'product') {
        for (final String f in fg) {
          for (final String g in bg) {
            pairs.add(<String>[f, g]);
          }
        }
      } else if (mode == 'zip') {
        if (fg.length != bg.length) {
          fail('VT-06', '$label is "zip" but fg and bg differ in length');
          continue;
        }
        for (int i = 0; i < fg.length; i++) {
          pairs.add(<String>[fg[i], bg[i]]);
        }
      } else {
        fail('VT-06', '$label mode "$mode" is not product or zip (AX-05)');
        continue;
      }
      if (s['count-per-theme'] != pairs.length) {
        fail('VT-03', '$label count-per-theme is ${s['count-per-theme']}, '
            'the sets give ${pairs.length}');
      }
      summary.pairsPerTheme += pairs.length;
      if (spec.id != separateGroupId) {
        counted += pairs.length * 2;
      }
      if (!known) {
        continue;
      }
      for (final String theme in <String>['light', 'dark']) {
        final Map<String, String> colors = themes[theme]!;
        double? setMin;
        for (final List<String> p in pairs) {
          final String? a = colors[p[0]];
          final String? b = colors[p[1]];
          if (a == null || b == null) {
            continue; // reported by VT-01 above
          }
          final double ratio = contrastRatio(a, b);
          if (!meetsThreshold(ratio, spec.threshold)) {
            fail(spec.id, '(VT-02) $theme ${p[0]} on ${p[1]}: '
                '${ratio.toStringAsFixed(4)} < ${spec.threshold}');
          }
          setMin = setMin == null || ratio < setMin ? ratio : setMin;
        }
        if (setMin == null) {
          continue;
        }
        final Object? recorded = s['min-$theme'];
        if (recorded is! num ||
            hundredths(recorded.toDouble()) != hundredths(setMin)) {
          fail('VT-03', '$label min-$theme is $recorded, computed '
              '${_fmt(setMin)} (${setMin.toStringAsFixed(4)})');
        }
        if (theme == 'light') {
          final double? old = summary.minLight;
          summary.minLight = old == null || setMin < old ? setMin : old;
        } else {
          final double? old = summary.minDark;
          summary.minDark = old == null || setMin < old ? setMin : old;
        }
      }
    }
  }
  if (counted != expectedPairCount) {
    fail('VT-03', 'VTG-01…VTG-09 give $counted pair checks, expected '
        '$expectedPairCount (AX-06, table 2-8)');
  }

  // ADR-UI-009: profile and manifest.
  final ManifestResult? manifest =
      manifestBytes == null ? null : readManifest(manifestBytes);
  if (manifest == null) {
    fail('ADR-UI-009', '$manifestPath is missing');
  } else {
    for (final String e in manifest.errors) {
      final int space = e.indexOf(' ');
      fail(e.substring(0, space), e.substring(space + 1));
    }
    if (profile == Profile.full && manifest.exemptionCount > 0) {
      fail('ADR-UI-009', '--profile=full: the manifest leaves '
          '${manifest.exemptionCount} item(s) NOT_IN_BUILD; the full profile '
          'allows no exemption (ADR-UI-009 §1, acceptance test 4)');
    }
  }

  // Report (VR-05 subset).
  final List<String> failed = <String>[
    for (final Finding f in findings) f.rule.startsWith('VTG-') ? 'VT-02' : f.rule,
  ];
  String status(String rule) => failed.contains(rule) ? 'RED  ' : 'GREEN';
  report
    ..add('ui_check tokens · profile=${profile.name} · manifest '
        '${manifest == null ? 'missing' : 'sha256 ${manifest.hash}'}')
    ..add('token checksum (AX-02): computed ${computed ?? 'n/a'} · file '
        '${stored ?? 'n/a'}')
    ..add('Rules:')
    ..add('  ${status('AX-02')} AX-02 file format (UTF-8, LF, key order)')
    ..add('  ${status('VT-01')} VT-01 names AXT-01…AXT-13, hex colours, '
        'checksum')
    ..add('  ${status('MC-02')} MC-02 $generatedPath equals a fresh '
        'generation')
    ..add('  ${status('TK-08')} TK-08 dark background is not #000000')
    ..add('  ${status('VT-02')} VT-02 contrast thresholds (text 4.5, '
        'border/graphic 3)')
    ..add('  ${status('VT-03')} VT-03 $expectedPairCount pair checks and '
        'table 2-8 minima')
    ..add('  ${status('VT-06')} VT-06 only the registered groups and colours')
    ..add('  ${status('ADR-UI-009')} ADR-UI-009 manifest and profile')
    ..add('  ${status('ND-02')} ND-02 core destinations in the manifest')
    ..add('  EXEMPT VT-04 $exemptPairNote')
    ..add('  NOT_COVERED VT-05 widget-level pixel contrast: component '
        'widget tests (later tasks), not this stage')
    ..add('Contrast (VT-02), pairs per theme and minima:');
  for (final GroupSummary g in summaries) {
    final String light = g.minLight == null ? 'n/a' : _fmt(g.minLight!);
    final String dark = g.minDark == null ? 'n/a' : _fmt(g.minDark!);
    final String note = g.id == separateGroupId ? ' (reported separately)' : '';
    report.add('  ${g.id} threshold ${g.threshold} · ${g.pairsPerTheme} '
        'per theme · min light $light · min dark $dark$note');
  }
  final GroupSummary separate =
      summaries.firstWhere((GroupSummary g) => g.id == separateGroupId);
  report
    ..add('  total VTG-01…VTG-09: $counted checks (${counted ~/ 2} per '
        'theme); $separateGroupId: ${separate.pairsPerTheme * 2} checks')
    ..add('Profile: ${profile.name} (token checks are never reduced, '
        'ADR-UI-009 §2)');
  if (manifest != null) {
    report.add(profile == Profile.mvp
        ? 'NOT_IN_BUILD (${manifest.exemptionCount}):'
        : 'Exemptions found (${manifest.exemptionCount}):');
    for (final MapEntry<String, List<String>> e in manifest.notInBuild.entries) {
      report.add('  ${e.key} (${e.value.length}): '
          '${e.value.isEmpty ? '-' : e.value.join(', ')}');
    }
  }
  report.add('Findings (${findings.length}):');
  for (final Finding f in findings) {
    report.add('  $f');
  }
  report.add(findings.isEmpty
      ? 'Result: PASS'
      : 'Result: FAIL (${failedRulesOf(findings).join(', ')})');
  return StageResult(findings, report, computed);
}

/// Distinct rule IDs of [findings] in order.
List<String> failedRulesOf(List<Finding> findings) =>
    StageResult(findings, const <String>[], null).failedRules;
