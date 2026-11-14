// The `worst` reference set (DS-04, DS-06; table 10-2-te; T-022).
//
// The Persian text of W-05 and W-07 is in `FixtureTextFa` (T-025).
// W-09 charts 2 to 4 and W-12 follow the SE-16 interim rule
// (ADVISOR_REPLY-007 Decision 1-4; T-028). Not here: W-10, an assistant
// card (v0.4).

import 'fixture_types.dart';

final BigInt _ten = BigInt.from(10);

const String _se16 = 'SE-16 interim rule (ADVISOR_REPLY-007 Decision 4)';

/// SE-16 item 1: chart 2 value in month [month] (1..12), in toman:
/// `W-02 + floor((m - 1) x 2 x |W-01| / 11)`. The numerator is never
/// negative, so truncating division is the floor.
BigInt se16Chart2Toman(int month) {
  if (month < 1 || month > 12) {
    throw RangeError('SE-16 chart 2 is defined for months 1..12');
  }
  final BigInt w01 = BigInt.parse('987654321012345');
  return -w01 +
      (BigInt.from(month - 1) * BigInt.two * w01) ~/ BigInt.from(11);
}

/// SE-16 item 4: the day [daysBefore] days before 2 Aban 1405 (2026-10-24),
/// for 0..199. Jalali months 1-6 of 1405 have 31 days and Mehr has 30.
FixtureDate se16DaysBeforeAban2(int daysBefore) {
  if (daysBefore < 0 || daysBefore > 199) {
    throw RangeError('W-12 is defined for i = 0..199');
  }
  final int dayOfYear = 6 * 31 + 30 + 2 - daysBefore;
  final int month;
  final int day;
  if (dayOfYear <= 6 * 31) {
    month = (dayOfYear - 1) ~/ 31 + 1;
    day = (dayOfYear - 1) % 31 + 1;
  } else {
    final int rest = dayOfYear - 6 * 31;
    month = 7 + (rest - 1) ~/ 30;
    day = (rest - 1) % 30 + 1;
  }
  final DateTime g =
      DateTime.utc(2026, 10, 24).subtract(Duration(days: daysBefore));
  return FixtureDate(1405, month, day, g.year, g.month, g.day);
}

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

  /// W-09 chart 2 (SE-16 item 1): one series of 12 months from W-02 to
  /// W-01, crossing zero between months 6 and 7 (toman, as IRR).
  static final List<List<FixtureAmount>> w09Chart2 = <List<FixtureAmount>>[
    <FixtureAmount>[
      for (int m = 1; m <= 12; m++)
        FixtureAmount.toman(se16Chart2Toman(m).toString()),
    ],
  ];

  /// W-09 chart 3 (SE-16 item 2): the shape of chart 1, every value 0.
  static final List<List<FixtureAmount>> w09Chart3 = <List<FixtureAmount>>[
    for (int s = 1; s <= 5; s++)
      <FixtureAmount>[
        for (int m = 1; m <= 12; m++) FixtureAmount.toman('0'),
      ],
  ];

  /// W-09 chart 4 (SE-16 item 3): one series, one point (month 1) = W-01.
  static final List<List<FixtureAmount>> w09Chart4 = <List<FixtureAmount>>[
    <FixtureAmount>[w01],
  ];

  /// Text key of the W-05 title (`FixtureTextFa.w05Title`).
  static const String w05TitleKey = 'w05_title';

  /// W-12 (SE-16 item 4): 200 list rows `w12_000`..`w12_199`, i ascending
  /// (dates descending). Even i: W-05 title, 320 000 toman; odd i: title of
  /// table 10-2-be row 1 (`lunch_with_colleagues`), W-01. All expense,
  /// `food`, `cash`, at the DS-01 time of day. List-only: not part of any
  /// DS-03 total or DD-06 balance.
  static final List<FixtureListRow> w12Rows = <FixtureListRow>[
    for (int i = 0; i < 200; i++)
      FixtureListRow(
        'w12_${i.toString().padLeft(3, '0')}',
        FixtureTransaction(
          key: i.isEven ? w05TitleKey : 'lunch_with_colleagues',
          date: se16DaysBeforeAban2(i),
          kind: FixtureKind.expense,
          categoryKey: 'food',
          accountKey: 'cash',
          amount: i.isEven ? FixtureAmount.toman('320000') : w01,
          source: _se16,
        ),
      ),
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
