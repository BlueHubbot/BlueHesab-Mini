// T-002 spike: the money value type (DD-01…DD-05, I-01, MN-01, AM-01).
//
// Rules this file follows:
// - Amounts are BigInt minor units plus a currency code. No floating-point
//   type appears anywhere on this path (I-01); test/no_float_test.dart greps
//   the whole package for it.
// - Storage form is canonical decimal TEXT: no `+`, no leading zeros,
//   `-` only for negative values, at most 18 digits (DD-02, NM-06).

/// A currency the MVP knows, with the number of minor-unit digits (DD-01).
final class CurrencyCode {
  const CurrencyCode._(this.code, this.minorDigits);

  /// ISO-like code stored in the database, e.g. `IRR`.
  final String code;

  /// Digits of the minor unit: 0 for IRR (rial), 2 for the others (DD-01).
  final int minorDigits;

  static const CurrencyCode irr = CurrencyCode._('IRR', 0);
  static const CurrencyCode usd = CurrencyCode._('USD', 2);
  static const CurrencyCode eur = CurrencyCode._('EUR', 2);
  static const CurrencyCode gbp = CurrencyCode._('GBP', 2);
  static const CurrencyCode aed = CurrencyCode._('AED', 2);
  static const CurrencyCode tryLira = CurrencyCode._('TRY', 2);

  /// The seeded currencies of DATA_MODEL §7, in seed order.
  static const List<CurrencyCode> values = [irr, usd, eur, gbp, aed, tryLira];

  /// Looks up a stored code; unknown codes are rejected, never guessed.
  static CurrencyCode parse(String code) {
    for (final c in values) {
      if (c.code == code) {
        return c;
      }
    }
    throw FormatException('Unknown currency code', code);
  }

  @override
  String toString() => code;
}

/// An exact amount of money: [minor] units of [currency] (DD-01…DD-05).
final class Money {
  /// Creates an amount; |minor| must not exceed [maxMinor] (AM-01, NM-06).
  Money(this.minor, this.currency) {
    if (minor.abs() > maxMinor) {
      throw RangeError('Amount has more than $maxDigits digits: $minor');
    }
  }

  /// Parses the canonical storage form (DD-02). Anything else is rejected.
  factory Money.fromStorage(String text, CurrencyCode currency) {
    if (!isCanonical(text)) {
      throw FormatException('Not a canonical decimal amount', text);
    }
    return Money(BigInt.parse(text), currency);
  }

  /// Most digits an amount may have (AM-01, NM-06, DD-02).
  static const int maxDigits = 18;

  /// 10^18 − 1, the largest allowed magnitude in minor units.
  static final BigInt maxMinor = BigInt.parse('999999999999999999');

  static final RegExp _canonical = RegExp(r'^(0|-?[1-9][0-9]{0,17})$');

  /// Whether [text] is a canonical amount: `0`, or an optional `-` and
  /// 1…18 digits without a leading zero (DD-02).
  static bool isCanonical(String text) => _canonical.hasMatch(text);

  /// Minor units. Exact on every Dart target, including web (DD-05).
  final BigInt minor;

  /// The currency of [minor].
  final CurrencyCode currency;

  /// Canonical decimal TEXT for SQLite, JSON and backups (DD-02).
  String toStorage() => minor.toString();

  /// Sum in the domain (DD-03); both sides must share a currency (DD-04).
  Money operator +(Money other) {
    _sameCurrency(other);
    return Money(minor + other.minor, currency);
  }

  /// Difference in the domain (DD-03); both sides must share a currency.
  Money operator -(Money other) {
    _sameCurrency(other);
    return Money(minor - other.minor, currency);
  }

  void _sameCurrency(Money other) {
    if (other.currency.code != currency.code) {
      throw ArgumentError(
        'Currencies differ: ${currency.code} and ${other.currency.code} '
        '(DD-04: no conversion in v0.1)',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minor == minor &&
      other.currency.code == currency.code;

  @override
  int get hashCode => Object.hash(minor, currency.code);

  @override
  String toString() => '${toStorage()} ${currency.code}';
}
