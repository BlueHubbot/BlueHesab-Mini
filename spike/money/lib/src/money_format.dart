// T-002 spike: the central number island formatter and parser for money
// (MN-02, MN-03, NM-01…NM-03, NM-05, NM-06). Integer arithmetic only (I-01).
//
// The formatter returns the number island only. The unit word ("rial",
// "toman", …) is a separate widget fed from the copy catalog (MN-03, RT-07,
// CM-10), so no user-facing word appears here. The symbols below are the CLDR
// `fa` symbols of the NM-02 table, written as escapes.

import 'money.dart';

/// Digit shapes (NM-01). `auto` is resolved by the caller from the locale.
enum DigitMode {
  /// U+06F0…U+06F9 with the Persian separators of NM-02.
  persian,

  /// ASCII digits with `,` and `.`.
  latin,
}

/// How rial amounts are shown (MN-02); toman = rial ÷ 10.
enum RialDisplayUnit {
  /// The stored value as is.
  rial,

  /// Rial ÷ 10, with one fraction digit only when the rial amount is not a
  /// multiple of 10.
  toman,
}

const String _lrm = '\u200E';
const String _minus = '\u2212';
const String _faGroup = '\u066C';
const String _faDecimal = '\u066B';
const int _faZero = 0x06F0;
const int _arZero = 0x0660;
const int _asciiZero = 0x30;

/// Formats and parses the number island of an amount.
final class MoneyFormatter {
  const MoneyFormatter({
    this.digits = DigitMode.persian,
    this.rialUnit = RialDisplayUnit.toman,
  });

  /// Digit shapes and separators (NM-01, NM-02).
  final DigitMode digits;

  /// Display unit for IRR (MN-02). Other currencies ignore it.
  final RialDisplayUnit rialUnit;

  /// Fraction digits between the stored minor unit and the display unit.
  ///
  /// Spike assumption, no rule ID: non-IRR currencies always show all
  /// `minorDigits` (listed under "Open questions" in the spike README).
  int scaleFor(CurrencyCode currency) {
    if (currency.code == CurrencyCode.irr.code) {
      return rialUnit == RialDisplayUnit.toman ? 1 : 0;
    }
    return currency.minorDigits;
  }

  /// The exact number island of [money] (NM-02, NM-03): for -123456 rial
  /// shown in toman with Persian digits, U+200E U+2212 then 12,345.6 written
  /// with U+06F0… digits, U+066C as group and U+066B as decimal mark.
  String formatNumber(Money money) {
    final scale = scaleFor(money.currency);
    final magnitude = money.minor.abs().toString();
    var whole = magnitude;
    var fraction = '';
    if (scale > 0) {
      final padded = magnitude.padLeft(scale + 1, '0');
      whole = padded.substring(0, padded.length - scale);
      fraction = padded.substring(padded.length - scale);
      final isToman = money.currency.code == CurrencyCode.irr.code;
      if (isToman && fraction == '0') {
        fraction = ''; // MN-02: whole toman shows no fraction digit.
      }
    }
    final persian = digits == DigitMode.persian;
    final buffer = StringBuffer();
    if (money.minor.isNegative) {
      buffer.write('$_lrm$_minus'); // NM-02 table, both digit modes.
    }
    buffer.write(_group(whole, persian ? _faGroup : ','));
    if (fraction.isNotEmpty) {
      buffer
        ..write(persian ? _faDecimal : '.')
        ..write(fraction);
    }
    final latin = buffer.toString();
    return persian ? _toPersianDigits(latin) : latin;
  }

  /// Parses user input back to minor units (NM-05). Accepts Persian, Arabic
  /// and Latin digits, drops group separators, reads `٫`, `.` or `/` as the
  /// decimal mark and `−` or `-` as the sign. More than 18 digits throws a
  /// [RangeError] (NM-06; the UI reaction is SE-08, still open).
  Money parseNumber(String input, CurrencyCode currency) {
    final scale = scaleFor(currency);
    var negative = false;
    var seenDecimal = false;
    final whole = StringBuffer();
    final fraction = StringBuffer();
    var sawDigit = false;
    var position = 0;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final digit = _digitValue(rune);
      if (digit != null) {
        sawDigit = true;
        (seenDecimal ? fraction : whole).write(digit);
      } else if (_ignored.contains(char)) {
        // group separators and direction marks (NM-05)
      } else if ((char == _minus || char == '-') && !sawDigit && !negative) {
        negative = true;
      } else if (_decimalMarks.contains(char) && !seenDecimal) {
        seenDecimal = true;
      } else {
        throw FormatException('Unexpected character in amount', input, position);
      }
      position++;
    }
    if (!sawDigit) {
      throw FormatException('No digits in amount', input);
    }
    if (fraction.length > scale) {
      throw FormatException('Too many fraction digits for $currency', input);
    }
    final minorText = '$whole${fraction.toString().padRight(scale, '0')}';
    final magnitude = BigInt.parse(minorText.isEmpty ? '0' : minorText);
    return Money(negative ? -magnitude : magnitude, currency);
  }

  static const Set<String> _ignored = {
    _faGroup, ',', '\u060C', ' ', '\u200C', '\u00A0', _lrm, '\u200F',
  };

  static const Set<String> _decimalMarks = {_faDecimal, '.', '/'};

  static int? _digitValue(int rune) {
    for (final zero in const [_asciiZero, _faZero, _arZero]) {
      if (rune >= zero && rune <= zero + 9) {
        return rune - zero;
      }
    }
    return null;
  }

  static String _group(String digits, String separator) {
    final head = digits.length % 3 == 0 ? 3 : digits.length % 3;
    final buffer = StringBuffer(digits.substring(0, head));
    for (var i = head; i < digits.length; i += 3) {
      buffer
        ..write(separator)
        ..write(digits.substring(i, i + 3));
    }
    return buffer.toString();
  }

  static String _toPersianDigits(String latin) {
    final units = latin.codeUnits.map((u) {
      final isDigit = u >= _asciiZero && u <= _asciiZero + 9;
      return isDigit ? u - _asciiZero + _faZero : u;
    });
    return String.fromCharCodes(units);
  }
}
