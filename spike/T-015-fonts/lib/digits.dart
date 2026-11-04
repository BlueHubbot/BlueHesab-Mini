// T-015 (SP-03): Persian digit input in a number field. Spike only; the app's
// parser belongs to the central formatter (UI spec §3-3, I-01). Money is
// BigInt, never double.

/// Persian (U+06F0..U+06F9) and Arabic-Indic (U+0660..U+0669) digits to ASCII.
String toAsciiDigits(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x06F0 && rune <= 0x06F9) {
      out.writeCharCode(0x30 + rune - 0x06F0);
    } else if (rune >= 0x0660 && rune <= 0x0669) {
      out.writeCharCode(0x30 + rune - 0x0660);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// Thousands separators accepted while typing: Arabic thousands U+066C,
/// ASCII comma, ZWNJ-free spaces.
const Set<int> _separators = {0x066C, 0x2C, 0x20, 0x00A0, 0x202F};

/// Parses a typed integer amount in minor units; null when it is not a
/// plain non-negative integer after separators are removed.
BigInt? parseTypedAmount(String input) {
  final ascii = toAsciiDigits(input);
  final digits = StringBuffer();
  for (final rune in ascii.runes) {
    if (_separators.contains(rune)) continue;
    if (rune < 0x30 || rune > 0x39) return null;
    digits.writeCharCode(rune);
  }
  if (digits.isEmpty) return null;
  return BigInt.parse(digits.toString());
}
