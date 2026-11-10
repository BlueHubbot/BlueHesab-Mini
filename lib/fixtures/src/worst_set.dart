// The `worst` reference set (DS-04, DS-06; table 10-2-te; T-022).
//
// The Persian text of W-05 and W-07 is in `FixtureTextFa` (T-025).
// Not here yet: W-09 charts 2 to 4 (no values given) and W-12 (alternation
// order and dates not given), both ESC-007; W-10 is an assistant card (v0.4).

import 'fixture_types.dart';

final BigInt _ten = BigInt.from(10);

/// DS-06: value of chart series [series] (1..5) in month [month] (1..12),
/// in toman: `s × 10^14 + ((m + 11 × s) mod 12) × 3 × 10^13`.
BigInt ds06Toman(int series, int month) {
  if (series < 1 || series > 5 || month < 1 || month > 12) {
    throw RangeError('DS-06 is defined for series 1..5 and months 1..12');
  }
  return BigInt.from(series) * _ten.pow(14) +
      BigInt.from((month + 11 * series) % 12) * BigInt.from(3) * _ten.pow(13);
}

/// The `worst` set (DS-04).
abstract final class WorstSet {
  /// W-01: 15-digit toman amount.
  static final FixtureAmount w01 = FixtureAmount.toman('987654321012345');

  /// W-02: the same amount, negative.
  static final FixtureAmount w02 = FixtureAmount.toman('-987654321012345');

  /// W-03: 24-character dollar amount with two decimals (cents).
  static final FixtureAmount w03 =
      FixtureAmount.minor('123456789012345678', 'USD');

  /// W-04: rial ceiling, 18 digits.
  static final FixtureAmount w04 =
      FixtureAmount.minor('123456789012345678', 'IRR');

  /// W-06: three currencies (toman W-01, dollar W-03, euro).
  static final List<FixtureAmount> w06ThreeCurrencies = <FixtureAmount>[
    w01,
    w03,
    FixtureAmount.minor('87654321', 'EUR'),
  ];

  /// W-06: the five-currency case adds pound and dirham ("+2 more").
  static final List<FixtureAmount> w06FiveCurrencies = <FixtureAmount>[
    ...w06ThreeCurrencies,
    FixtureAmount.minor('123456', 'GBP'),
    FixtureAmount.minor('9876543', 'AED'),
  ];

  /// W-08: the Latin account name inside a sentence (BidiText).
  static const String w08AccountName = 'Wise EUR';

  /// W-08: the Latin e-mail address inside a sentence (synthetic).
  static const String w08Email = 'ali.rezaei@example.com';

  /// W-09 chart 1: five series × twelve months by DS-06 (toman, as IRR).
  static final List<List<FixtureAmount>> w09Chart1 = <List<FixtureAmount>>[
    for (int s = 1; s <= 5; s++)
      <FixtureAmount>[
        for (int m = 1; m <= 12; m++)
          FixtureAmount.toman(ds06Toman(s, m).toString()),
      ],
  ];

  /// W-11: one numeric column (toman).
  static final List<FixtureAmount> w11Column = <FixtureAmount>[
    FixtureAmount.toman('0'),
    FixtureAmount.toman('12'),
    FixtureAmount.toman('1234'),
    FixtureAmount.toman('123456'),
    w01,
    w02,
  ];

  /// W-11: changes for PercentageChange: 0.125, -0.03, 0 and 12.34.
  static const List<FixtureRatio> w11Changes = <FixtureRatio>[
    FixtureRatio(125, 1000),
    FixtureRatio(-3, 100),
    FixtureRatio(0, 1),
    FixtureRatio(1234, 100),
  ];
}
