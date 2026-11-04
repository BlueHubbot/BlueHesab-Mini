import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// T-015 test support: tokens from design/tokens/design_tokens.json (read
// only), the fetched font from build/fonts (tool/fetch_font.py), and an
// evidence file the workflow prints per OS.

/// Font family name the tests register.
const String family = 'Vazirmatn';

/// UI spec §3-1 vertical-metric sample (synthetic).
const String specimen = 'گچپژ یئؤ ۱۲۳۴۵۶۷۸۹۰';

/// One typography token from design_tokens.json.
class TypeToken {
  /// Creates a token.
  const TypeToken(this.name, this.size, this.weight, this.line);

  /// Token name, e.g. `body`.
  final String name;

  /// Font size.
  final double size;

  /// Weight (400..700, TY-07).
  final int weight;

  /// Line height in logical pixels.
  final double line;

  /// Style for this token with the evaluated font. `withLine` false gives
  /// the font's natural line box (no `height`).
  TextStyle style({bool withLine = true, List<FontFeature>? features}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: withLine ? line / size : null,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
        fontFeatures: features,
        letterSpacing: 0, // TY-01
      );
}

/// Reads `typography.scale` from the repository token file.
List<TypeToken> loadTypeTokens() {
  final file = File('../../design/tokens/design_tokens.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final typography = json['typography']! as Map<String, Object?>;
  final scale = typography['scale']! as Map<String, Object?>;
  return [
    for (final entry in scale.entries)
      () {
        final v = entry.value! as Map<String, Object?>;
        return TypeToken(
          entry.key,
          (v['size']! as num).toDouble(),
          (v['weight']! as num).toInt(),
          (v['line']! as num).toDouble(),
        );
      }(),
  ];
}

/// Folder with the fetched TTF files.
String fontDir() => Platform.environment['T015_FONT_DIR'] ?? 'build/fonts';

/// Registers build/fonts/variable.ttf as [family]. Throws with a clear
/// message when the fetch step did not run.
Future<void> loadFont() async {
  final file = File('${fontDir()}/variable.ttf');
  if (!file.existsSync()) {
    throw StateError(
      'Missing ${file.path}: run python3 -I tool/fetch_font.py '
      '--pin tool/font_pin.json --out build/fonts first',
    );
  }
  final bytes = file.readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// Evidence lines written to build/spike-evidence.txt at the end.
final List<String> evidence = <String>[];

/// Writes [evidence] for the workflow notice.
void writeEvidence() {
  final out = File('build/spike-evidence-${Platform.operatingSystem}.txt')
    ..createSync(recursive: true);
  out.writeAsStringSync('${evidence.join('\n')}\n');
}

/// Lays out [text] once, right to left, without width limit.
TextPainter paint(String text, TextStyle style) => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    )..layout();
