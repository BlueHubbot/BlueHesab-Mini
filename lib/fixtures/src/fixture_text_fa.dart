// The Persian text of the reference data (ui-spec §10-2, DS-02; T-025).
//
// Each value is the table cell of `10-style-guide-and-fixtures.md` §10-2
// (table 10-2-be2 for the Mehr rows), copied byte for byte. This
// is test data, not product copy (CM-10): MC-17 allows Persian literals in
// `lib/fixtures/` only, and no file outside `lib/fixtures/` and
// `lib/style_guide/` may import it (SE-15, ADVISOR_REPLY-006).
//
// W-12 rows reuse `w05Title` (key `w05_title`) and the `transactions`
// text of `lunch_with_colleagues` (SE-16, T-028); W-10 is v0.4.

/// Persian text of the `normal` and `worst` sets, grouped by kind because
/// one English key can name two kinds (`tasks` is an arc and a list).
abstract final class FixtureTextFa {
  /// Account names, table 10-2-alef rows 1-3 (keys of `FixtureSet.accounts`).
  static const Map<String, String> accounts = <String, String>{
    'cash': 'نقدی',
    'bank_melli': 'بانک ملی',
    'savings': 'پس‌انداز',
  };

  /// Transaction titles: table 10-2-be rows 1-7 (row 7 = the `coffee` draft)
  /// and table 10-2-be2 rows 1-3 (Mehr 1405).
  static const Map<String, String> transactions = <String, String>{
    'lunch_with_colleagues': 'ناهار با همکاران',
    'snapp_ride': 'اسنپ',
    'weekly_supermarket': 'خرید هفتگی سوپرمارکت',
    'electricity_bill': 'قبض برق',
    'gasoline': 'بنزین',
    'salary_aban': 'حقوق آبان',
    'coffee': 'قهوه',
    'weekly_supermarket_mehr': 'خرید هفتگی سوپرمارکت',
    'gas_bill_mehr': 'قبض گاز',
    'gasoline_mehr': 'بنزین',
  };

  /// Category names: table 10-2-pe (12 expense categories) and the income
  /// category of table 10-2-be row 6.
  static const Map<String, String> categories = <String, String>{
    'food': 'غذا',
    'transport': 'حمل‌ونقل',
    'home': 'خانه',
    'bills': 'قبوض',
    'health': 'سلامت',
    'education': 'آموزش',
    'clothing': 'پوشاک',
    'entertainment': 'سرگرمی',
    'gifts': 'هدیه',
    'car': 'خودرو',
    'online_shopping': 'خرید اینترنتی',
    'other': 'سایر',
    'salary': 'حقوق',
  };

  /// Day-ring arc labels, table 10-2-pe rows 1-3 (keys of `FixtureSet.arcs`).
  static const Map<String, String> arcLabels = <String, String>{
    'budget': 'بودجه',
    'tasks': 'کارها',
    'habits': 'عادت‌ها',
  };

  /// Day-ring arc value texts as displayed with Persian digits, table 10-2-pe
  /// rows 1-3.
  static const Map<String, String> arcValueTexts = <String, String>{
    'budget': '۶۸٪ باقی‌مانده',
    'tasks': '۴ از ۶',
    'habits': '۲ از ۵',
  };

  /// Semantics sentence of the day ring (VI-14), table 10-2-pe row 4.
  static const String ringSemantics =
      'حلقه‌ی روز: بودجه ۶۸ درصد باقی‌مانده، کارها ۴ از ۶، عادت‌ها ۲ از ۵.';

  /// Upcoming items, table 10-2-pe `upcoming`.
  static const Map<String, String> upcoming = <String, String>{
    'team_meeting': 'جلسه‌ی تیم',
    'loan_installment': 'قسط وام',
    'car_periodic_service': 'سرویس دوره‌ای خودرو',
  };

  /// Comparison line of `monthSpending` as displayed, table 10-2-pe (DD-11,
  /// table 10-2-be2).
  static const String monthSpendingComparison =
      '۱۲٪ کمتر از مهر';

  /// Habits, table 10-2-pe `habitsToday` (done first, then open).
  static const Map<String, String> habits = <String, String>{
    'morning_exercise': 'ورزش صبحگاهی',
    'reading': 'مطالعه',
    'drink_water': 'نوشیدن آب',
    'meditation': 'مدیتیشن',
    'early_sleep': 'خواب زودهنگام',
  };

  /// Market-watch instrument names, table 10-2-pe `marketWatch` (prices are
  /// fictitious).
  static const Map<String, String> market = <String, String>{
    'usd': 'دلار آمریکا',
    'gold_18k_per_gram': 'طلای ۱۸ عیار (هر گرم)',
    'emami_coin': 'سکه‌ی امامی',
  };

  /// Car reminders, table 10-2-pe `carReminders`.
  static const Map<String, String> carReminders = <String, String>{
    'periodic_service_40000_km': 'سرویس دوره‌ای ۴۰ هزار کیلومتر',
    'body_insurance_renewal': 'تمدید بیمه‌ی بدنه',
  };

  /// Tasks, table 10-2-pe (four done, then two open).
  static const Map<String, String> tasks = <String, String>{
    'buy_bread': 'خرید نان',
    'pay_electricity_bill': 'پرداخت قبض برق',
    'call_bank': 'تماس با بانک',
    'send_report': 'ارسال گزارش',
    'dentist_appointment': 'نوبت دندان‌پزشکی',
    'oil_change': 'تعویض روغن',
  };

  /// W-05: long title, 43 characters (UTF-16 code units, ZWNJ included).
  static const String w05Title =
      'پرداخت قسط وام مسکن و بیمه‌ی تکمیلی خانواده';

  /// W-07: long category label.
  static const String w07Category =
      'هزینه‌های مربوط به نگهداری و تعمیرات ساختمان';

  /// W-07: subtitle of the long category.
  static const String w07CategorySubtitle =
      'شامل شارژ، آسانسور و نظافت';

  /// W-07: long account name.
  static const String w07Account =
      'حساب مشترک خانوادگی بانک ملی شعبه‌ی مرکزی';

  /// W-07: long date range label as displayed.
  static const String w07Range =
      '۱ فروردین ۱۴۰۵ تا ۲۹ اسفند ۱۴۰۵';
}
