// Unit tests of the contrast guard (ADR-UI-011 §3, VT-02; T-012).
//
// Known values first, then negative controls (pairs that must fail), then
// properties over the curated palette of design/brand/themes-v2.json, and a
// cross-check that the guard and `ui_check` compute the same ratio.

import 'dart:convert';
import 'dart:io';

import 'package:bluehesab_mini/design/tokens/contrast_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/ui_check/src/contrast.dart' as tool;

const String themesPath = 'design/brand/themes-v2.json';

int rgbOf(String hex) => int.parse(hex.substring(1), radix: 16);

String hexOf(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

List<String> curatedPalette() {
  final Map<String, Object?> json = jsonDecode(
    File(themesPath).readAsStringSync(),
  ) as Map<String, Object?>;
  return (json['custom_palette']! as List<Object?>).cast<String>();
}

void main() {
  group('ratio', () {
    test('black on white is 21:1 and the order does not matter', () {
      expect(contrastRatioRgb(0x000000, 0xFFFFFF), closeTo(21, 1e-9));
      expect(contrastRatioRgb(0xFFFFFF, 0x000000), closeTo(21, 1e-9));
    });

    test('a colour on itself is 1:1', () {
      expect(contrastRatioRgb(0x93594F, 0x93594F), closeTo(1, 1e-12));
    });

    test('thresholds: 4.5 for text, 3 for large text (ADR-UI-011 §3)', () {
      expect(requiredContrast(largeText: false), 4.5);
      expect(requiredContrast(largeText: true), 3);
    });

    test('values outside 24-bit RGB are rejected', () {
      expect(() => contrastRatioRgb(-1, 0), throwsArgumentError);
      expect(() => contrastRatioRgb(0x1000000, 0), throwsArgumentError);
      expect(() => nearestPassingShade(0, 0x1000000, 4.5), throwsArgumentError);
    });
  });

  group('verdict', () {
    test('#777777 on white: 4.48 fails text, passes large text', () {
      final ContrastVerdict text = guardContrast(0x777777, 0xFFFFFF);
      expect(text.ratio, closeTo(4.4781, 1e-4));
      expect(text.passes, isFalse);
      expect(text.suggestion, 0x767676);
      expect(contrastRatioRgb(text.suggestion!, 0xFFFFFF),
          greaterThanOrEqualTo(4.5));

      final ContrastVerdict large =
          guardContrast(0x777777, 0xFFFFFF, largeText: true);
      expect(large.passes, isTrue);
      expect(large.suggestion, 0x777777, reason: 'a passing colour is kept');
    });

    test('Clay accent on Clay surface (4.45) fails text; nearest shade', () {
      final ContrastVerdict v = guardContrast(0xB4492F, 0xF6E8DD);
      expect(v.ratio, closeTo(4.4489, 1e-4));
      expect(v.passes, isFalse);
      expect(v.suggestion, 0xB3482F);
    });

    test('Clay text2 on Clay background (1.41) moves toward white', () {
      final ContrastVerdict v = guardContrast(0x74463D, 0x93594F);
      expect(v.passes, isFalse);
      expect(v.suggestion, 0xEDE7E6);
    });

    test('same colour as background: dark side wins when it is nearer', () {
      expect(nearestPassingShade(0x777777, 0x777777, 4.5), 0x060606);
      expect(nearestPassingShade(0x777777, 0x777777, 3), 0x2E2E2E);
    });

    test('exactly at the threshold passes (VT-02, VR-07 b)', () {
      final double r = contrastRatioRgb(0x767676, 0xFFFFFF);
      expect(
        ContrastVerdict(ratio: r, threshold: r, suggestion: null).passes,
        isTrue,
      );
      expect(
        ContrastVerdict(ratio: r - 1e-9, threshold: r, suggestion: null)
            .passes,
        isFalse,
      );
    });

    test('no shade can pass an impossible threshold', () {
      expect(nearestPassingShade(0x777777, 0x777777, 21.5), isNull);
    });
  });

  group('curated palette (themes-v2.json custom_palette)', () {
    final List<String> palette = curatedPalette();

    test('guard ratio equals the ui_check ratio for every pair', () {
      int pairs = 0;
      for (final String fg in palette) {
        for (final String bg in palette) {
          expect(
            contrastRatioRgb(rgbOf(fg), rgbOf(bg)),
            tool.contrastRatio(fg, bg),
            reason: '$fg on $bg',
          );
          pairs++;
        }
      }
      expect(pairs, palette.length * palette.length);
    });

    test('every suggestion passes and keeps passing colours unchanged', () {
      int failing = 0;
      for (final String fg in palette) {
        for (final String bg in palette) {
          for (final bool large in <bool>[false, true]) {
            final ContrastVerdict v =
                guardContrast(rgbOf(fg), rgbOf(bg), largeText: large);
            expect(v.suggestion, isNotNull, reason: '$fg on $bg');
            expect(
              contrastRatioRgb(v.suggestion!, rgbOf(bg)),
              greaterThanOrEqualTo(v.threshold),
              reason: '$fg on $bg -> ${hexOf(v.suggestion!)}',
            );
            if (v.passes) {
              expect(v.suggestion, rgbOf(fg));
            } else {
              failing++;
            }
          }
        }
      }
      expect(failing, greaterThan(0), reason: 'negative cases must exist');
    });
  });
}
