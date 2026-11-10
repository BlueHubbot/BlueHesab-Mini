// The `normal` and `empty` reference sets (DS-02, DS-03; tables 10-2-alef,
// 10-2-be, 10-2-pe; SE-09 interim rule; T-022).
//
// Text: every name, title and label is a stable English key; its Persian
// text is in `FixtureTextFa` (T-025, SE-15). `source` names the spec row of each item.

import 'fixture_types.dart';

/// One reference set with the shape of the `normal` set (DS-02).
final class FixtureSet {
  /// Creates a set.
  const FixtureSet({
    required this.name,
    required this.accounts,
    required this.transactions,
    required this.draftTransaction,
    required this.monthlyBudget,
    required this.statedTotals,
    required this.arcs,
    required this.upcoming,
    required this.marketWatch,
    required this.carReminders,
    required this.tasks,
    required this.habits,
    required this.expenseCategories,
    required this.frequentExpenseCategories,
    required this.incomeCategories,
  });

  /// `normal` or `empty`.
  final String name;

  /// Accounts in table order.
  final List<FixtureAccount> accounts;

  /// Stored transactions: table 10-2-be in table order, then the SE-09
  /// Mehr rows.
  final List<FixtureTransaction> transactions;

  /// The insert-test draft (the coffee row, MO-11); not stored (DS-03).
  final FixtureTransaction? draftTransaction;

  /// Monthly overall budget.
  final FixtureAmount? monthlyBudget;

  /// Totals stated by the tables, to be checked against the rows.
  final FixtureStatedTotals? statedTotals;

  /// Day-ring arcs: budget, tasks, habits.
  final List<FixtureArc> arcs;

  /// Home `upcoming` items.
  final List<FixtureDatedItem> upcoming;

  /// Home `marketWatch` prices (fictitious).
  final List<FixturePrice> marketWatch;

  /// Home `carReminders` items.
  final List<FixtureDatedItem> carReminders;

  /// The six tasks.
  final FixtureChecklist tasks;

  /// Today's habits.
  final FixtureChecklist habits;

  /// The 12 expense categories in table order.
  final List<String> expenseCategories;

  /// The most used expense categories, in order.
  final List<String> frequentExpenseCategories;

  /// Income categories used by the rows.
  final List<String> incomeCategories;
}

const FixtureDate _mehr1 = FixtureDate(1405, 7, 1, 2026, 9, 23);
const FixtureDate _mehr2 = FixtureDate(1405, 7, 2, 2026, 9, 24);
const FixtureDate _mehr15 = FixtureDate(1405, 7, 15, 2026, 10, 7);
const FixtureDate _aban1 = FixtureDate(1405, 8, 1, 2026, 10, 23);
const FixtureDate _aban2 = FixtureDate(1405, 8, 2, 2026, 10, 24);
const FixtureDate _aban3 = FixtureDate(1405, 8, 3, 2026, 10, 25);
const FixtureDate _aban4 = FixtureDate(1405, 8, 4, 2026, 10, 26);
const FixtureDate _aban5 = FixtureDate(1405, 8, 5, 2026, 10, 27);
const FixtureDate _aban20 = FixtureDate(1405, 8, 20, 2026, 11, 11);

FixtureTransaction _row(
  String key,
  FixtureDate date,
  FixtureKind kind,
  String category,
  String account,
  String toman,
  String source,
) =>
    FixtureTransaction(
      key: key,
      date: date,
      kind: kind,
      categoryKey: category,
      accountKey: account,
      amount: FixtureAmount.toman(toman),
      source: source,
    );

const String _tBe = 'table 10-2-be';
const String _se09 = 'SE-09 interim rule (Mehr 1405)';

/// The `normal` set (DS-03): one currency, three arcs.
final FixtureSet normalSet = FixtureSet(
  name: 'normal',
  accounts: <FixtureAccount>[
    FixtureAccount(
      key: 'cash',
      kind: FixtureAccountKind.cash,
      opening: FixtureAmount.toman('2265000'),
      displayedBalance: FixtureAmount.toman('850000'),
      source: 'table 10-2-alef row 1',
    ),
    FixtureAccount(
      key: 'bank_melli',
      kind: FixtureAccountKind.bank,
      opening: FixtureAmount.toman('645000'),
      displayedBalance: FixtureAmount.toman('9400000'),
      source: 'table 10-2-alef row 2',
    ),
    FixtureAccount(
      key: 'savings',
      kind: FixtureAccountKind.bank,
      opening: FixtureAmount.toman('30000000'),
      displayedBalance: FixtureAmount.toman('30000000'),
      source: 'table 10-2-alef row 3',
    ),
  ],
  transactions: <FixtureTransaction>[
    _row('lunch_with_colleagues', _aban2, FixtureKind.expense, 'food', 'cash',
        '320000', '$_tBe row 1'),
    _row('snapp_ride', _aban2, FixtureKind.expense, 'transport', 'bank_melli',
        '185000', '$_tBe row 2'),
    _row('weekly_supermarket', _aban1, FixtureKind.expense, 'food',
        'bank_melli', '610000', '$_tBe row 3'),
    _row('electricity_bill', _aban1, FixtureKind.expense, 'bills',
        'bank_melli', '450000', '$_tBe row 4'),
    _row('gasoline', _aban1, FixtureKind.expense, 'car', 'cash', '195000',
        '$_tBe row 5'),
    _row('salary_aban', _aban1, FixtureKind.income, 'salary', 'bank_melli',
        '12000000', '$_tBe row 6'),
    _row('weekly_supermarket_mehr', _mehr1, FixtureKind.expense, 'food',
        'bank_melli', '1200000', '$_se09 row 1'),
    _row('gas_bill_mehr', _mehr2, FixtureKind.expense, 'bills', 'bank_melli',
        '800000', '$_se09 row 2'),
    _row('gasoline_mehr', _mehr15, FixtureKind.expense, 'car', 'cash',
        '900000', '$_se09 row 3 (outside the same-length period)'),
  ],
  draftTransaction: _row('coffee', _aban2, FixtureKind.expense, 'food', 'cash',
      '120000', '$_tBe row 7 (new row; DS-03)'),
  monthlyBudget: FixtureAmount.toman('5500000'),
  statedTotals: FixtureStatedTotals(
    totalBalance: FixtureAmount.toman('40250000'),
    monthIncome: FixtureAmount.toman('12000000'),
    monthExpense: FixtureAmount.toman('1760000'),
    monthBudget: FixtureAmount.toman('5500000'),
    previousSamePeriodExpense: FixtureAmount.toman('2000000'),
    comparisonPercentLess: 12,
  ),
  arcs: const <FixtureArc>[
    FixtureArc('budget', FixtureRatio(68, 100)),
    FixtureArc('tasks', FixtureRatio(4, 6)),
    FixtureArc('habits', FixtureRatio(2, 5)),
  ],
  upcoming: <FixtureDatedItem>[
    const FixtureDatedItem('team_meeting', _aban3),
    FixtureDatedItem('loan_installment', _aban4, FixtureAmount.toman('4200000')),
    const FixtureDatedItem('car_periodic_service', _aban5),
  ],
  marketWatch: <FixturePrice>[
    FixturePrice('usd', FixtureAmount.toman('105500')),
    FixturePrice('gold_18k_per_gram', FixtureAmount.toman('7200000')),
    FixturePrice('emami_coin', FixtureAmount.toman('80000000')),
  ],
  carReminders: const <FixtureDatedItem>[
    FixtureDatedItem('periodic_service_40000_km', _aban5),
    FixtureDatedItem('body_insurance_renewal', _aban20),
  ],
  tasks: const FixtureChecklist(
    done: <String>['buy_bread', 'pay_electricity_bill', 'call_bank', 'send_report'],
    open: <String>['dentist_appointment', 'oil_change'],
  ),
  habits: const FixtureChecklist(
    done: <String>['morning_exercise', 'reading'],
    open: <String>['drink_water', 'meditation', 'early_sleep'],
  ),
  expenseCategories: const <String>[
    'food',
    'transport',
    'home',
    'bills',
    'health',
    'education',
    'clothing',
    'entertainment',
    'gifts',
    'car',
    'online_shopping',
    'other',
  ],
  frequentExpenseCategories: const <String>[
    'food',
    'transport',
    'bills',
    'car',
    'home',
  ],
  incomeCategories: const <String>['salary'],
);

/// The `empty` set: no account, no transaction, no arc (DS-02; VI-15,
/// HM-03, SD-05).
const FixtureSet emptySet = FixtureSet(
  name: 'empty',
  accounts: <FixtureAccount>[],
  transactions: <FixtureTransaction>[],
  draftTransaction: null,
  monthlyBudget: null,
  statedTotals: null,
  arcs: <FixtureArc>[],
  upcoming: <FixtureDatedItem>[],
  marketWatch: <FixturePrice>[],
  carReminders: <FixtureDatedItem>[],
  tasks: FixtureChecklist(done: <String>[], open: <String>[]),
  habits: FixtureChecklist(done: <String>[], open: <String>[]),
  expenseCategories: <String>[],
  frequentExpenseCategories: <String>[],
  incomeCategories: <String>[],
);
