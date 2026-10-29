// Generates lib/design/tokens/design_tokens.g.dart from design_tokens.json
// (TK-01). The output is deterministic: the same JSON always gives the same
// bytes, so MC-02 can compare the committed file with a fresh generation.
//
// The generated file is the only place where colour literals are allowed
// (MC-01 "allowed in" column); every value in it comes from the JSON.

import 'dart:convert';

import 'token_registry.dart';

/// Repository path of the generated file.
const String generatedPath = 'lib/design/tokens/design_tokens.g.dart';

/// `kebab-case` (or `a.b-c`) to `lowerCamelCase`.
String camel(String name) {
  final List<String> parts = name
      .split(RegExp(r'[-.]'))
      .where((String p) => p.isNotEmpty)
      .toList();
  final StringBuffer out = StringBuffer(parts.first);
  for (final String p in parts.skip(1)) {
    out
      ..write(p[0].toUpperCase())
      ..write(p.substring(1));
  }
  return out.toString();
}

String _num(Object? v) {
  if (v == null) {
    return 'null';
  }
  if (v is int) {
    return '$v';
  }
  if (v is double) {
    return v.toString();
  }
  throw FormatException('Expected a number', v);
}

String _color(Object? hex) {
  final String h = hex! as String;
  return 'Color(0xFF${h.substring(1).toUpperCase()})';
}

Map<String, Object?> _obj(Object? v) => v! as Map<String, Object?>;

/// Decodes [jsonBytes] and generates the Dart source; null when the file
/// does not have the structure of appendix A.
String? generateFromBytes(List<int> jsonBytes) {
  try {
    final Object? decoded = jsonDecode(utf8.decode(jsonBytes));
    return decoded is Map<String, Object?> ? generateDart(decoded) : null;
  } on Object {
    return null;
  }
}

/// Builds the Dart source for [tokens] (the decoded JSON file).
String generateDart(Map<String, Object?> tokens) {
  final Map<String, Object?> meta = _obj(tokens['meta']);
  final Map<String, Object?> color = _obj(tokens['color']);
  final Map<String, Object?> alias = _obj(tokens['alias']);
  final Map<String, Object?> scrim = _obj(tokens['scrim-opacity']);
  final Map<String, Object?> state = _obj(tokens['state-opacity']);
  final Map<String, Object?> elevation = _obj(tokens['elevation']);
  final Map<String, Object?> typography = _obj(tokens['typography']);
  final Map<String, Object?> motion = _obj(tokens['motion']);
  final List<String> names = colorNames();

  final StringBuffer b = StringBuffer()
    ..writeln('// GENERATED FILE: do not edit by hand (TK-01, MC-02).')
    ..writeln('// Source: design/tokens/design_tokens.json, tokens-version '
        '${meta['tokens-version']}.')
    ..writeln('// Regenerate: dart run tool/ui_check/ui_check.dart gen')
    ..writeln()
    ..writeln("import 'dart:ui' show Color, FontWeight;")
    ..writeln()
    ..writeln("import 'package:flutter/animation.dart' show Cubic;")
    ..writeln()
    // TokenColors
    ..writeln('/// Colours of one theme (appendix A, AXT-02 and AXT-03).')
    ..writeln('final class TokenColors {')
    ..writeln('  /// Creates the colours of one theme.')
    ..writeln('  const TokenColors({');
  for (final String n in names) {
    b.writeln('    required this.${camel(n)},');
  }
  b
    ..writeln('  });')
    ..writeln();
  for (final String n in names) {
    b
      ..writeln('  /// Token `$n`.')
      ..writeln('  final Color ${camel(n)};');
  }
  for (final MapEntry<String, Object?> a in alias.entries) {
    final String target = a.value! as String;
    b
      ..writeln()
      ..writeln('  /// Alias `${a.key}` of `$target` (AXT-04).')
      ..writeln('  Color get ${camel(a.key)} => ${camel(target)};');
  }
  b
    ..writeln('}')
    ..writeln()
    // TokenShadow
    ..writeln('/// One shadow of an elevation level (AXT-06).')
    ..writeln('final class TokenShadow {')
    ..writeln('  /// Creates a shadow.')
    ..writeln('  const TokenShadow({')
    ..writeln('    required this.x,')
    ..writeln('    required this.y,')
    ..writeln('    required this.blur,')
    ..writeln('    required this.color,')
    ..writeln('    required this.opacity,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double x;')
    ..writeln('  final double y;')
    ..writeln('  final double blur;')
    ..writeln('  final Color color;')
    ..writeln('  final double opacity;')
    ..writeln('}')
    ..writeln()
    // TokenElevation
    ..writeln('/// An elevation level: its light and dark shadow (AXT-06).')
    ..writeln('final class TokenElevation {')
    ..writeln('  /// Creates an elevation level.')
    ..writeln('  const TokenElevation({required this.light, required this.dark});')
    ..writeln()
    ..writeln('  final TokenShadow light;')
    ..writeln('  final TokenShadow dark;')
    ..writeln('}')
    ..writeln()
    // TokenTextRole
    ..writeln('/// A text role of table 3-1 (AXT-07).')
    ..writeln('final class TokenTextRole {')
    ..writeln('  /// Creates a text role.')
    ..writeln('  const TokenTextRole({')
    ..writeln('    required this.size,')
    ..writeln('    required this.weight,')
    ..writeln('    required this.line,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double size;')
    ..writeln('  final FontWeight weight;')
    ..writeln('  final double line;')
    ..writeln('}')
    ..writeln()
    // TokenLayout
    ..writeln('/// A layout class of table 2-5 (AXT-11).')
    ..writeln('final class TokenLayout {')
    ..writeln('  /// Creates a layout class.')
    ..writeln('  const TokenLayout({')
    ..writeln('    required this.minWidth,')
    ..writeln('    required this.maxWidth,')
    ..writeln('    required this.pagePadding,')
    ..writeln('    required this.cardPadding,')
    ..writeln('    required this.cardGap,')
    ..writeln('    required this.sectionGap,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double minWidth;')
    ..writeln('  final double? maxWidth;')
    ..writeln('  final double pagePadding;')
    ..writeln('  final double cardPadding;')
    ..writeln('  final double cardGap;')
    ..writeln('  final double sectionGap;')
    ..writeln('}')
    ..writeln()
    // DesignTokens
    ..writeln('/// The design tokens (TK-01). Widgets read values only from here.')
    ..writeln('abstract final class DesignTokens {')
    ..writeln("  static const String tokensVersion = '${meta['tokens-version']}';")
    ..writeln("  static const String checksum = '${meta['checksum']}';");

  for (final String theme in <String>['light', 'dark']) {
    final Map<String, Object?> c = _obj(color[theme]);
    b
      ..writeln()
      ..writeln('  static const TokenColors ${camel('colors-$theme')} = TokenColors(');
    for (final String n in names) {
      b.writeln('    ${camel(n)}: ${_color(c[n])},');
    }
    b.writeln('  );');
  }

  b.writeln();
  for (final MapEntry<String, Object?> e in scrim.entries) {
    b.writeln('  static const double ${camel('scrim-opacity-${e.key}')} = '
        '${_num(e.value)};');
  }
  for (final MapEntry<String, Object?> e in state.entries) {
    b.writeln('  static const double ${camel('state-${e.key}')} = '
        '${_num(e.value)};');
  }

  b.writeln();
  for (final MapEntry<String, Object?> e in elevation.entries) {
    if (e.value == null) {
      b.writeln('  static const TokenElevation? ${camel(e.key)} = null;');
      continue;
    }
    final Map<String, Object?> level = _obj(e.value);
    b.writeln('  static const TokenElevation ${camel(e.key)} = TokenElevation(');
    for (final String theme in <String>['light', 'dark']) {
      final Map<String, Object?> s = _obj(level[theme]);
      b
        ..writeln('    $theme: TokenShadow(')
        ..writeln('      x: ${_num(s['x'])},')
        ..writeln('      y: ${_num(s['y'])},')
        ..writeln('      blur: ${_num(s['blur'])},')
        ..writeln('      color: ${_color(s['color'])},')
        ..writeln('      opacity: ${_num(s['opacity'])},')
        ..writeln('    ),');
    }
    b.writeln('  );');
  }

  final List<Object?> weights = typography['weights']! as List<Object?>;
  b
    ..writeln()
    ..writeln("  static const String fontFamilyFa = '${typography['font-family-fa']}';")
    ..writeln('  static const String fontFamilyLatin = '
        "'${typography['font-family-latin']}';")
    ..writeln('  static const List<FontWeight> weights = <FontWeight>[')
    ..writeln(weights.map((Object? w) => '    FontWeight.w$w,').join('\n'))
    ..writeln('  ];')
    ..writeln('  static const double letterSpacing = '
        '${_num(typography['letter-spacing'])};');
  for (final MapEntry<String, Object?> e
      in _obj(typography['scale']).entries) {
    final Map<String, Object?> r = _obj(e.value);
    b
      ..writeln('  static const TokenTextRole ${camel('text-${e.key}')} = TokenTextRole(')
      ..writeln('    size: ${_num(r['size'])},')
      ..writeln('    weight: FontWeight.w${r['weight']},')
      ..writeln('    line: ${_num(r['line'])},')
      ..writeln('  );');
  }

  for (final String section in <String>['space', 'radius', 'size']) {
    b.writeln();
    for (final MapEntry<String, Object?> e in _obj(tokens[section]).entries) {
      b.writeln('  static const double ${camel(e.key)} = ${_num(e.value)};');
    }
  }

  b.writeln();
  for (final MapEntry<String, Object?> e in _obj(tokens['layout']).entries) {
    final Map<String, Object?> l = _obj(e.value);
    b
      ..writeln('  static const TokenLayout ${camel('layout-${e.key}')} = TokenLayout(')
      ..writeln('    minWidth: ${_num(l['min-width'])},')
      ..writeln('    maxWidth: ${_num(l['max-width'])},')
      ..writeln('    pagePadding: ${_num(l['page-padding'])},')
      ..writeln('    cardPadding: ${_num(l['card-padding'])},')
      ..writeln('    cardGap: ${_num(l['card-gap'])},')
      ..writeln('    sectionGap: ${_num(l['section-gap'])},')
      ..writeln('  );');
  }

  for (final String group in <String>['duration', 'timing']) {
    b.writeln();
    for (final MapEntry<String, Object?> e in _obj(motion[group]).entries) {
      b.writeln('  static const Duration ${camel('$group-${e.key}')} = '
          'Duration(milliseconds: ${_num(e.value)});');
    }
  }
  b.writeln();
  for (final MapEntry<String, Object?> e in _obj(motion['curve']).entries) {
    final List<Object?> p = e.value! as List<Object?>;
    b.writeln('  static const Cubic ${camel('curve-${e.key}')} = '
        'Cubic(${p.map(_num).join(', ')});');
  }
  b.writeln('}');
  return b.toString();
}
