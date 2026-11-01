// Contrast guard for themes (ADR-UI-011 §3, VT-02; T-012).
//
// Pure Dart, no dependency (CB-9) and no Flutter import, so the custom-theme
// editor (T-013), `ui_check` and tool tests can share it. Colours are 24-bit
// RGB integers (`0xRRGGBB`); callers convert from their own colour type.
//
// The ratio is the WCAG 2.x contrast ratio with no intermediate rounding, the
// same computation as `tool/ui_check/src/contrast.dart` (a tool test keeps
// both equal). A pair passes at or above its threshold (VT-02): text needs
// 4.5:1, large text (ADR-UI-011 §3: 24 px and up) needs 3:1.

import 'dart:math' as math;

/// Minimum ratio for normal text (VT-02, ADR-UI-011 §3).
const double textContrastMin = 4.5;

/// Minimum ratio for large text, 24 px and up (ADR-UI-011 §3).
const double largeTextContrastMin = 3;

/// Threshold for a text pair of the given size class.
double requiredContrast({required bool largeText}) =>
    largeText ? largeTextContrastMin : textContrastMin;

int _red(int rgb) => (rgb >> 16) & 0xFF;
int _green(int rgb) => (rgb >> 8) & 0xFF;
int _blue(int rgb) => rgb & 0xFF;

double _linear(int channel) {
  final double s = channel / 255;
  return s <= 0.04045
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

/// Relative luminance (WCAG 2.x) of a 24-bit RGB colour.
double relativeLuminanceRgb(int rgb) {
  _checkRgb(rgb);
  return 0.2126 * _linear(_red(rgb)) +
      0.7152 * _linear(_green(rgb)) +
      0.0722 * _linear(_blue(rgb));
}

/// WCAG contrast ratio of two 24-bit RGB colours (order does not matter).
double contrastRatioRgb(int a, int b) {
  final double la = relativeLuminanceRgb(a);
  final double lb = relativeLuminanceRgb(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void _checkRgb(int rgb) {
  if (rgb < 0 || rgb > 0xFFFFFF) {
    throw ArgumentError.value(rgb, 'rgb', 'must be a 24-bit 0xRRGGBB value');
  }
}

/// Outcome of one guard check.
final class ContrastVerdict {
  /// Creates a verdict.
  const ContrastVerdict({
    required this.ratio,
    required this.threshold,
    required this.suggestion,
  });

  /// The WCAG ratio of the pair as given.
  final double ratio;

  /// The threshold the pair was checked against.
  final double threshold;

  /// Whether the pair may be saved (ratio at or above the threshold).
  bool get passes => ratio >= threshold;

  /// The nearest foreground that passes: the given foreground itself when it
  /// passes, otherwise the closest shade toward black or white; null only
  /// when no shade of the foreground can pass on this background (possible
  /// only for thresholds above about 4.58).
  final int? suggestion;
}

/// Checks [foreground] text on [background] (ADR-UI-011 §3): returns the
/// ratio, whether it passes and the nearest passing shade.
ContrastVerdict guardContrast(
  int foreground,
  int background, {
  bool largeText = false,
}) {
  final double threshold = requiredContrast(largeText: largeText);
  return ContrastVerdict(
    ratio: contrastRatioRgb(foreground, background),
    threshold: threshold,
    suggestion: nearestPassingShade(foreground, background, threshold),
  );
}

int _mix(int rgb, int target, int step) {
  int channel(int c) => (c + ((target - c) * step / 255)).round();
  return (channel(_red(rgb)) << 16) |
      (channel(_green(rgb)) << 8) |
      channel(_blue(rgb));
}

/// The passing shade of [foreground] closest to it on [background].
///
/// The foreground is mixed in 255 equal steps toward black and toward white
/// (each channel moves by the same fraction, so the hue is kept); the first
/// step that reaches [threshold] on each side is a candidate and the one
/// with fewer steps wins. On a tie the candidate with the higher ratio wins,
/// then the darker one, so the result is deterministic.
int? nearestPassingShade(int foreground, int background, double threshold) {
  _checkRgb(foreground);
  _checkRgb(background);
  if (contrastRatioRgb(foreground, background) >= threshold) {
    return foreground;
  }
  int? firstPassing(int target) {
    for (int step = 1; step <= 255; step++) {
      final int shade = _mix(foreground, target, step);
      if (contrastRatioRgb(shade, background) >= threshold) {
        return step;
      }
    }
    return null;
  }

  final int? darkSteps = firstPassing(0);
  final int? lightSteps = firstPassing(255);
  if (darkSteps == null && lightSteps == null) {
    return null;
  }
  final int? dark = darkSteps == null ? null : _mix(foreground, 0, darkSteps);
  final int? light =
      lightSteps == null ? null : _mix(foreground, 255, lightSteps);
  if (dark == null) {
    return light;
  }
  if (light == null) {
    return dark;
  }
  if (darkSteps! != lightSteps!) {
    return darkSteps < lightSteps ? dark : light;
  }
  final double darkRatio = contrastRatioRgb(dark, background);
  final double lightRatio = contrastRatioRgb(light, background);
  return lightRatio > darkRatio ? light : dark;
}
