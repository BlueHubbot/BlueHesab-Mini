// Contrast of the four ADR-UI-011 themes, read from design/brand/themes-v2.json
// (T-012; VT-02; ADR-UI-011 §1, §3 and "Consequences").
//
// Only the pairs that the v2 source itself defines are checked here. The
// mapping of the v1 roles (table A-2-a, VTG-01…VTG-10) onto the themes is
// open in ESC-002 / SE-13, so design_tokens.json is not changed yet.
//
// Pairs per theme (11): ink and text2 on surface and surface2; on_bg_text on
// bg; on_bg_text2 on bg; onaccent on accent; each activity `on` on its
// `fill`. All need 4.5:1, except on_bg_text2 on Clay, which ADR-UI-011
// limits to large text (3:1): "on it only on_bg_text may carry small text".

import 'dart:convert';
import 'dart:io';

import 'package:bluehesab_mini/design/tokens/contrast_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const String themesPath = 'design/brand/themes-v2.json';

int rgbOf(String hex) => int.parse(hex.substring(1), radix: 16);

/// One checked pair.
final class Pair {
  const Pair(this.name, this.fg, this.bg, {this.large = false});
  final String name;
  final String fg;
  final String bg;
  final bool large;
}

Map<String, Object?> obj(Object? value) => value! as Map<String, Object?>;

List<Pair> pairsOf(String id, Map<String, Object?> theme) {
  final Map<String, Object?> roles = obj(theme['roles']);
  String role(String key) => roles[key]! as String;
  final List<Pair> pairs = <Pair>[
    for (final String fg in <String>['ink', 'text2'])
      for (final String bg in <String>['surface', 'surface2'])
        Pair('$fg/$bg', role(fg), role(bg)),
    Pair('on_bg_text/bg', theme['on_bg_text']! as String, role('bg')),
    Pair('on_bg_text2/bg', theme['on_bg_text2']! as String, role('bg'),
        large: id == 'clay'),
    Pair('onaccent/accent', role('onaccent'), role('accent')),
  ];
  final List<Object?> activity = theme['activity']! as List<Object?>;
  for (int i = 0; i < activity.length; i++) {
    final Map<String, Object?> a = obj(activity[i]);
    pairs.add(Pair('activity$i', a['on']! as String, a['fill']! as String));
  }
  return pairs;
}

void main() {
  final Map<String, Object?> source =
      jsonDecode(File(themesPath).readAsStringSync()) as Map<String, Object?>;
  final Map<String, Object?> themes = obj(source['themes']);

  test('the four themes of ADR-UI-011 are present, in order', () {
    expect(themes.keys.toList(), <String>['ivory', 'plum', 'clay', 'glow']);
  });

  for (final String id in themes.keys) {
    test('theme $id: every defined text pair meets its threshold', () {
      final List<Pair> pairs = pairsOf(id, obj(themes[id]));
      expect(pairs, hasLength(11));
      double min = double.infinity;
      for (final Pair p in pairs) {
        final ContrastVerdict v =
            guardContrast(rgbOf(p.fg), rgbOf(p.bg), largeText: p.large);
        expect(v.passes, isTrue,
            reason: '$id ${p.name} ${p.fg} on ${p.bg}: '
                '${v.ratio.toStringAsFixed(2)} < ${v.threshold}');
        if (v.ratio < min) {
          min = v.ratio;
        }
      }
      debugPrint('themes-v2 $id: ${pairs.length} pairs, 0 failing, '
          'min ${min.toStringAsFixed(2)}');
    });
  }

  group('negative controls (must stay below 4.5:1)', () {
    // ADR-UI-011 "Consequences": on the mid-tone Clay background only
    // on_bg_text may carry small text; ink and text2 must not.
    test('Clay ink and text2 on the Clay background fail', () {
      final Map<String, Object?> roles = obj(obj(themes['clay'])['roles']);
      for (final String fg in <String>['ink', 'text2']) {
        final ContrastVerdict v = guardContrast(
            rgbOf(roles[fg]! as String), rgbOf(roles['bg']! as String));
        expect(v.passes, isFalse, reason: 'clay $fg/bg');
      }
    });

    // Recorded for ESC-002: Clay accent as text on the Clay surface is
    // 4.45:1, so accent cannot become the v1 `primary` role (VTG-02) as is.
    test('Clay accent on the Clay surface is 4.45:1', () {
      final Map<String, Object?> roles = obj(obj(themes['clay'])['roles']);
      final ContrastVerdict v = guardContrast(
          rgbOf(roles['accent']! as String), rgbOf(roles['surface']! as String));
      expect(v.ratio, closeTo(4.45, 0.005));
      expect(v.passes, isFalse);
    });
  });
}
