// WCAG contrast for VT-02: relative luminance of each colour and the ratio
// (L1 + 0.05) / (L2 + 0.05), with no intermediate rounding. Rounding to two
// decimals happens only when a minimum is compared with table 2-8 (VT-03).

import 'dart:math' as math;

/// Parses `#RRGGBB` into its three channels; returns null otherwise.
List<int>? parseHex(String hex) {
  if (!isHex6(hex)) {
    return null;
  }
  return <int>[
    int.parse(hex.substring(1, 3), radix: 16),
    int.parse(hex.substring(3, 5), radix: 16),
    int.parse(hex.substring(5, 7), radix: 16),
  ];
}

final RegExp _hex6 = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// Whether [value] is a six-digit hex colour (VT-01 step 5).
bool isHex6(String value) => _hex6.hasMatch(value);

double _channel(int c) {
  final double s = c / 255;
  return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

/// Relative luminance of a `#RRGGBB` colour.
double relativeLuminance(String hex) {
  final List<int> rgb = parseHex(hex)!;
  return 0.2126 * _channel(rgb[0]) +
      0.7152 * _channel(rgb[1]) +
      0.0722 * _channel(rgb[2]);
}

/// WCAG contrast ratio of two colours (order does not matter).
double contrastRatio(String a, String b) {
  final double la = relativeLuminance(a);
  final double lb = relativeLuminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// A ratio passes when it is at or above the threshold (VT-02): exactly
/// 4.5 passes a 4.5 group, 4.4 fails it (VR-07 b).
bool meetsThreshold(double ratio, double threshold) => ratio >= threshold;

/// [value] rounded to two decimals, as an integer number of hundredths, so
/// two values are compared without floating-point noise (VT-03, AX-05).
int hundredths(double value) => (value * 100).round();
