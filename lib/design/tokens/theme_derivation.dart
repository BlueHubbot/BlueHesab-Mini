// Theme role derivation for tokens v2 (ADR-UI-011; ESC-002 and
// ADVISOR_REPLY-002 Action 1; T-012; erratum SE-13).
//
// A theme source has the eight ADR-UI-011 roles plus the seven values the
// owner approves (four status colours, three module accents; option A of
// ADVISOR_REPLY-002). Everything else in the 46-role contract (table A-2-a)
// is derived here by a written rule (option B), and `primary-text` is added
// as the text variant of `primary` (ADVISOR_REPLY-002, Clay). The rule is
// documented in docs/agents/tasks/T-012.md ("Derivation rule"); keep both in
// step. Pure Dart, no Flutter import, so `ui_check`, tool tests and the
// custom-theme editor (T-013) can share it. Colours are `0xRRGGBB` ints.

import 'contrast_guard.dart';

/// State-layer opacities, equal to `state-opacity.hover-layer` and
/// `state-opacity.pressed-layer` in design/tokens/design_tokens.json
/// (a tool test keeps them equal).
const double hoverLayer = 0.08;

/// See [hoverLayer].
const double pressedLayer = 0.12;

/// Share of the fill in a `*-subtle` tint over `surface`, light themes.
const double subtleShareLight = 0.08;

/// Share of the fill in a `*-subtle` tint over `surface`, dark themes.
const double subtleShareDark = 0.16;

/// Share of `surface` in `text-disabled` (mixed from `text-secondary`).
const double disabledShare = 0.4;

/// A theme counts as dark when its `surface` luminance is below this.
const double darkSurfaceLuminance = 0.18;

/// The seven values the owner approves per theme (ADVISOR_REPLY-002, A).
const List<String> ownerFillRoles = <String>[
  'accent-health',
  'accent-tasks',
  'accent-car',
  'success',
  'warning',
  'danger',
  'info',
];

/// Accent fills in VTG order: `primary` then the three module accents.
const List<String> accentRoles = <String>[
  'primary',
  'accent-health',
  'accent-tasks',
  'accent-car',
];

/// Semantic fills in VTG order.
const List<String> semanticRoles = <String>[
  'success',
  'warning',
  'danger',
  'info',
];

/// Input of [deriveThemeRoles].
final class ThemeSource {
  /// Creates a source; [roles] uses the `themes-v2.json` keys (bg, surface,
  /// surface2, ink, text2, line, accent, onaccent) and [ownerFills] the
  /// [ownerFillRoles] keys.
  const ThemeSource({
    required this.roles,
    required this.ownerFills,
    this.backgroundCarriesText = true,
  });

  /// The eight ADR-UI-011 roles.
  final Map<String, int> roles;

  /// The seven owner-approved fills.
  final Map<String, int> ownerFills;

  /// False when only `on_bg_text`/`on_bg_text2` may sit on `background`
  /// (Clay, ADR-UI-011 "Consequences"); `background` then leaves the text
  /// surfaces of every VTG group (erratum SE-13, Clay exception).
  final bool backgroundCarriesText;
}

/// Whether [surface] makes a dark theme.
bool isDarkSurface(int surface) =>
    relativeLuminanceRgb(surface) < darkSurfaceLuminance;

int _channel(int rgb, int shift) => (rgb >> shift) & 0xFF;

/// [from] moved toward [to] by [share] (0…1) per channel, rounded.
int mixRgb(int from, int to, double share) {
  int one(int shift) {
    final int a = _channel(from, shift);
    final int b = _channel(to, shift);
    return (a + (b - a) * share).round();
  }

  return (one(16) << 16) | (one(8) << 8) | one(0);
}

/// Hover and pressed shades of [fill]: the state layers mixed toward
/// [textPrimary]; when the fill already sits at the ink end (no channel of
/// the pressed shade moves by 3 or more), toward [onFill] instead.
(int hover, int pressed) stateShades(int fill, int textPrimary, int onFill) {
  int hover = mixRgb(fill, textPrimary, hoverLayer);
  int pressed = mixRgb(fill, textPrimary, pressedLayer);
  int moved = 0;
  for (final int shift in <int>[16, 8, 0]) {
    final int d = (_channel(fill, shift) - _channel(pressed, shift)).abs();
    if (d > moved) {
      moved = d;
    }
  }
  if (moved < 3) {
    hover = mixRgb(fill, onFill, hoverLayer);
    pressed = mixRgb(fill, onFill, pressedLayer);
  }
  return (hover, pressed);
}

/// The `*-subtle` tint of [fill] on [surface].
int subtleTint(int fill, int surface) => mixRgb(
      surface,
      fill,
      isDarkSurface(surface) ? subtleShareDark : subtleShareLight,
    );

/// Text surfaces of a derived theme, in VTG order.
List<String> textSurfaces({required bool backgroundCarriesText}) => <String>[
      if (backgroundCarriesText) 'background',
      'surface',
      'surface-raised',
    ];

/// Derives the 46 contract roles plus `primary-text` (47 keys).
///
/// Throws [StateError] when a guard-dependent role has no passing shade.
Map<String, int> deriveThemeRoles(ThemeSource source) {
  int role(String key) {
    final int? v = source.roles[key];
    if (v == null) {
      throw ArgumentError('missing role $key');
    }
    return v;
  }

  final Map<String, int> out = <String, int>{
    'background': role('bg'),
    'surface': role('surface'),
    'surface-raised': role('surface2'),
    'border': role('line'),
    'ring-track': role('line'),
    'text-primary': role('ink'),
    'text-secondary': role('text2'),
    'on-fill': role('onaccent'),
    'primary': role('accent'),
  };
  final bool dark = isDarkSurface(out['surface']!);
  final List<int> text = <int>[
    for (final String s
        in textSurfaces(backgroundCarriesText: source.backgroundCarriesText))
      out[s]!,
  ];
  bool onAll(int c, double threshold) =>
      text.every((int b) => contrastRatioRgb(c, b) >= threshold);

  final int? primaryText =
      nearestShadeWhere(out['primary']!, (int c) => onAll(c, textContrastMin));
  if (primaryText == null) {
    throw StateError('no passing primary-text shade');
  }
  out['primary-text'] = primaryText;
  out['text-disabled'] =
      mixRgb(out['text-secondary']!, out['surface']!, disabledShare);
  out['inverse-surface'] = out['text-primary']!;
  out['inverse-text'] = out['surface']!;
  out['scrim'] = dark ? 0x000000 : out['text-primary']!;

  final int? focus = <int>[out['primary']!, out['text-primary']!]
      .where((int c) => onAll(c, largeTextContrastMin))
      .firstOrNull;
  if (focus == null) {
    throw StateError('no focus-ring candidate passes 3:1');
  }
  out['focus-ring'] = focus;

  final int? borderStrong = nearestShadeWhere(
    mixRgb(out['text-secondary']!, out['border']!, 0.5),
    (int c) =>
        onAll(c, largeTextContrastMin) &&
        contrastRatioRgb(c, out['surface']!) >= 3.3,
  );
  if (borderStrong == null) {
    throw StateError('no passing border-strong shade');
  }
  out['border-strong'] = borderStrong;

  for (final String f in <String>[...accentRoles, ...semanticRoles]) {
    final int base;
    if (f == 'primary') {
      base = out['primary']!;
    } else {
      final int? v = source.ownerFills[f];
      if (v == null) {
        throw ArgumentError('missing owner fill $f');
      }
      base = v;
    }
    out[f] = base;
    final (int hover, int pressed) =
        stateShades(base, out['text-primary']!, out['on-fill']!);
    out['$f-hover'] = hover;
    out['$f-pressed'] = pressed;
    out['$f-subtle'] = subtleTint(base, out['surface']!);
  }
  return out;
}
