// Value types of the reference data (ui-spec §10-2, DS-02, DS-07; T-022).
// Pure Dart: no Flutter import, no `double` (MN-01, DS-07).

/// Currencies the fixtures use and their number of minor digits (DD-01).
const Map<String, int> fixtureMinorDigits = <String, int>{
  'IRR': 0,
  'USD': 2,
  'EUR': 2,
  'GBP': 2,
  'AED': 2,
};

final BigInt _ten = BigInt.from(10);

/// A money value: `BigInt` minor units plus a currency code (MN-01, DD-02).
///
/// Values are written as decimal text, never as `int` literals, because
/// 16- to 18-digit amounts do not fit a JavaScript number (SP-02 finding 4).
final class FixtureAmount {
  /// [minorText] is the amount in minor units (rial for IRR, cent for USD).
  FixtureAmount.minor(String minorText, this.currency)
      : minor = BigInt.parse(minorText);

  /// An IRR amount given in toman, the display unit of the tables
  /// (DD-01: one toman is ten rial).
  FixtureAmount.toman(String tomanText)
      : minor = BigInt.parse(tomanText) * _ten,
        currency = 'IRR';

  /// Minor units of [currency].
  final BigInt minor;

  /// ISO-like currency code, a key of [fixtureMinorDigits].
  final String currency;

  /// Canonical decimal text of [minor], as stored (DD-02).
  String get minorText => minor.toString();

  @override
  bool operator ==(Object other) =>
      other is FixtureAmount &&
      other.minor == minor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '$minorText $currency';
}

/// A calendar day given in both calendars, as the tables use Jalali dates.
final class FixtureDate {
  /// Jalali year/month/day and the same day in the Gregorian calendar.
  const FixtureDate(
    this.jalaliYear,
    this.jalaliMonth,
    this.jalaliDay,
    this.gregorianYear,
    this.gregorianMonth,
    this.gregorianDay,
  );

  /// Jalali year.
  final int jalaliYear;

  /// Jalali month, 1 = Farvardin, 7 = Mehr, 8 = Aban.
  final int jalaliMonth;

  /// Jalali day of month.
  final int jalaliDay;

  /// Gregorian year.
  final int gregorianYear;

  /// Gregorian month.
  final int gregorianMonth;

  /// Gregorian day of month.
  final int gregorianDay;

  /// Midnight UTC of the Gregorian day (a day key, not a wall-clock time).
  DateTime get gregorian =>
      DateTime.utc(gregorianYear, gregorianMonth, gregorianDay);
}

/// An exact fraction (arcs, percentage changes); never a `double` (DS-07).
final class FixtureRatio {
  /// [numerator] / [denominator]; [denominator] is positive.
  const FixtureRatio(this.numerator, this.denominator);

  /// Numerator.
  final int numerator;

  /// Denominator (> 0).
  final int denominator;

  /// Exact equality of two fractions by cross-multiplication.
  bool sameValueAs(FixtureRatio other) =>
      BigInt.from(numerator) * BigInt.from(other.denominator) ==
      BigInt.from(other.numerator) * BigInt.from(denominator);
}

/// Account kind (DATA_MODEL `accounts.kind`).
enum FixtureAccountKind {
  /// Cash.
  cash,

  /// Bank account.
  bank,
}

/// Transaction kind; the fixtures contain no transfer (DD-07).
enum FixtureKind {
  /// Expense.
  expense,

  /// Income.
  income,
}

/// One account. Its name is `FixtureTextFa.accounts[key]` (T-025).
final class FixtureAccount {
  /// Creates an account.
  const FixtureAccount({
    required this.key,
    required this.kind,
    required this.opening,
    required this.displayedBalance,
    required this.source,
  });

  /// Stable English key of the account and of its name text.
  final String key;

  /// Cash or bank.
  final FixtureAccountKind kind;

  /// Opening balance chosen so that [displayedBalance] holds (SE-09, DD-06).
  final FixtureAmount opening;

  /// Balance shown in table 10-2-alef at the DS-01 instant.
  final FixtureAmount displayedBalance;

  /// Where the row comes from (spec table and row).
  final String source;
}

/// One stored transaction (or the insert-test draft). Title = text item [key].
final class FixtureTransaction {
  /// Creates a transaction row.
  const FixtureTransaction({
    required this.key,
    required this.date,
    required this.kind,
    required this.categoryKey,
    required this.accountKey,
    required this.amount,
    required this.source,
  });

  /// Stable English key of the row and of its title text.
  final String key;

  /// Day of the transaction.
  final FixtureDate date;

  /// Expense or income.
  final FixtureKind kind;

  /// Category key (see [FixtureSet.expenseCategories]).
  final String categoryKey;

  /// Account key (see [FixtureSet.accounts]).
  final String accountKey;

  /// Positive amount (DD-02).
  final FixtureAmount amount;

  /// Where the row comes from (spec table and row, or the SE-09 interim rule).
  final String source;
}

/// A dated item of a Home widget (upcoming, car reminders).
final class FixtureDatedItem {
  /// Creates a dated item; [amount] is null when the table gives none.
  const FixtureDatedItem(this.key, this.date, [this.amount]);

  /// Stable English key of the item and of its title text.
  final String key;

  /// Day of the item.
  final FixtureDate date;

  /// Amount, when the table gives one.
  final FixtureAmount? amount;
}

/// A quoted price of the market-watch widget (prices are fictitious).
final class FixturePrice {
  /// Creates a price row.
  const FixturePrice(this.key, this.price);

  /// Stable English key of the instrument and of its name text.
  final String key;

  /// Price in toman, stored as IRR.
  final FixtureAmount price;
}

/// One ring arc of the day ring (VI-14). Label text = [key].
final class FixtureArc {
  /// Creates an arc.
  const FixtureArc(this.key, this.fraction);

  /// Stable English key of the arc and of its label text.
  final String key;

  /// Filled fraction.
  final FixtureRatio fraction;
}

/// A done/open list (tasks, habits). Item texts = the keys.
final class FixtureChecklist {
  /// Creates a checklist.
  const FixtureChecklist({required this.done, required this.open});

  /// Keys of the done items, in table order.
  final List<String> done;

  /// Keys of the open items, in table order.
  final List<String> open;

  /// Number of items.
  int get total => done.length + open.length;
}

/// Totals stated by table 10-2-alef, kept to be checked against the rows.
final class FixtureStatedTotals {
  /// Creates the stated totals.
  const FixtureStatedTotals({
    required this.totalBalance,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthBudget,
    required this.previousSamePeriodExpense,
    required this.comparisonPercentLess,
  });

  /// Total balance row.
  final FixtureAmount totalBalance;

  /// Income-this-month row.
  final FixtureAmount monthIncome;

  /// Expense-this-month row.
  final FixtureAmount monthExpense;

  /// Monthly budget row.
  final FixtureAmount monthBudget;

  /// Same-period Mehr spending of table 10-2-pe `monthSpending`.
  final FixtureAmount previousSamePeriodExpense;

  /// The "12 % less than Mehr" figure as an integer percentage (DD-11).
  final int comparisonPercentLess;
}
