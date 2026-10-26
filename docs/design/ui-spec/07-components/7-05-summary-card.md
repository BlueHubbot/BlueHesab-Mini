<!-- split from UI spec · 7-5 · lines 1445-1520 -->

### ۷-۵ کارت خلاصه (`SummaryCard`)

`SummaryCard` تنها قالبِ کارتی است که «یک عدد اصلی» نشان می‌دهد و دو شکل دارد: **کارت قهرمان سطح ۱** (`SummaryCard.hero`؛ مثل «موجودی کل» در خانه یا کارت بالای یک ماژول) و **کارت عدد کوچک سطح ۲** (`SummaryCard.number`؛ مثل ویجت «هزینه‌ی این ماه»). کارت «حلقه‌ی روز» این کامپوننت نیست (۷-۷). کارت منطق دامنه‌ای ندارد: برچسب، مبلغ و جمله‌ها آماده از والد می‌آیند (CM-01) و اسلات آزاد ندارد (CM-02)؛ پس نمی‌شود در آن بیش از سقف‌های HI-03 و HI-04 چیزی چید.

```dart
enum SummaryPlacement { homeBalance, moduleHero }   // نقش عدد از اینجا می‌آید (SC-03)
enum CardState { ready, loading, error, empty }

sealed class HeroValue {
  // پول: کارت هرگز قالب‌بندی نمی‌کند؛ format همان formatter مرکزی است (CA-01، SC-08)
  factory HeroValue.money({required BigInt minor, required MoneyVM Function(BigInt minor) format}) = _MoneyHero;
  // شمارنده، مثل «۳ کار»؛ بدون شمارش MO-14
  factory HeroValue.count({required String numberText, required String unitText, required String spokenText}) = _CountHero;
}

class SummaryRowVM {
  const SummaryRowVM.money({this.label, required MoneyVM this.money}) : valueText = null, spokenText = null;
  const SummaryRowVM.text({required String this.label, required this.valueText, required this.spokenText}) : money = null;
  final String? label;   // null فقط در کارت چندارزی (SC-05)
  final MoneyVM? money;
  final String? valueText, spokenText;
}

class SummaryProgress {
  const SummaryProgress({required this.fraction, required this.semanticLabel, this.statusText});
  final double fraction;       // ۰ تا ۱؛ بیشتر از ۱ فقط با statusText (SC-06)
  final String semanticLabel;  // «۶۰٪ از بودجه مصرف شده»
  final String? statusText;    // «بیش از بودجه»
}

class SummaryCard extends StatelessWidget {
  const SummaryCard.hero({
    required SummaryPlacement placement, required String label, required HeroValue hero,
    List<SummaryRowVM> rows = const [], String? finePrint, VoidCallback? onTap,
    CardState state = CardState.ready, StateVM? stateContent,   // StateVM در ۷-۱۲
  }) : assert(rows.length <= 2, 'HI-03');                // به‌علاوه‌ی assertهای SC-02

  const SummaryCard.number({
    required String title, required HeroValue value, String? comparisonText, SummaryProgress? progress,
    VoidCallback? onTap, CardState state = CardState.ready, StateVM? stateContent,
  }) : assert(wordCount(title) <= 3, 'HI-04');
}
```

**ابعاد کارت قهرمان** (کمینه در مقیاس متن ۱٫۰، واحد px؛ فرمول: ۱۶ + ۲۲ + ۴ + خط عدد + \[۸ + ۲۴ به‌ازای ردیف اول، ۲۴ به‌ازای ردیف دوم\] + ۱۶):

| جایگاه | نقش عدد (ارتفاع خط) | بدون ردیف | یک ردیف | دو ردیف |
| --- | --- | --- | --- | --- |
| `homeBalance` | `display` (۵۸) | ۱۱۶ | ۱۴۸ | ۱۷۲ |
| `moduleHero` در Expanded و Large | `heading` (۴۴) | ۱۰۲ | ۱۳۴ | ۱۵۸ |
| `moduleHero` در Compact و Medium | `title` (۳۴) | ۹۲ | ۱۲۴ | ۱۴۸ |

`finePrint` به ارتفاع کارت ۲۴ (۴ + ۲۰) اضافه می‌کند. کارت `number`: ۱۶ + ۳۰ + ۴ + ۳۰ + ۱۶ = ۹۶؛ `comparisonText` ۲۸ (۴ + ۲۴)، `progress` ۱۶ (۸ + ۸) و `progress.statusText` ۲۸ (۴ + ۲۴) به آن اضافه می‌کنند. همه‌ی این اعداد کمینه‌اند و با مقیاس متن بالاتر رشد می‌کنند (CM-07).

**حالت‌های کارت** (CM-03):

| حالت | ظاهر | رفتار |
| --- | --- | --- |
| عادی | قاب CM-12 و محتوای SC-04 یا SC-06 | اگر `onTap` دارد ضربه‌پذیر است (SC-07) |
| hover، focus، pressed | فقط وقتی ضربه‌پذیر است: لایه‌ی `text-primary` با شفافیت ۰٫۰۸ و ۰٫۱۰ و ۰٫۱۲ روی کل قاب با همان `radius-lg`؛ focus صفحه‌کلید علاوه بر آن حلقه‌ی ۲-۶ دارد | MO-01 |
| disabled | ندارد؛ کارتِ بدون جزئیات ضربه‌پذیر نیست و آیکون ندارد (HI-05) | — |
| loading | `Skeleton` (۷-۱۲) در همان قاب و با همان کمینه‌ی ارتفاع، پس از `skeleton-delay` | ضربه‌پذیر نیست؛ MO-12 |
| error | `ErrorState` کوچک (۷-۱۲) در همان قاب با «تلاش دوباره»؛ فقط همین کارت (HM-07) | ضربه‌ی کل کارت غیرفعال است؛ فقط دکمه‌ی خود ErrorState کار می‌کند |
| empty | `EmptyState` کوچک (۷-۱۲) در همان قاب؛ برچسب و عدد ساخته نمی‌شوند (HM-03) | فقط دکمه‌ی خود EmptyState کار می‌کند |

- **SC-01 (دو شکل و قاب):** `hero` فقط در سطح ۱ و `number` فقط در سطح ۲ می‌آید. هر دو قاب کارت CM-12 را دارند (`surface`، مرز ۱px `border`، `radius-lg`، بدون سایه) و فاصله‌ی داخلی `space-4` از چهار طرف. عرض کارت را والد می‌دهد (HM-06) و ارتفاعش ثابت نیست.
- **SC-02 (ورودی‌ها و assert):** سازنده‌ها این موارد را با `assert` رد می‌کنند (HI-09): در `hero` بیش از دو ردیف؛ `display` همراه `moduleHero`؛ ردیف بی‌برچسب وقتی همه‌ی ردیف‌های کارت بی‌برچسب نیستند؛ `finePrint` وقتی ردیف‌ها بی‌برچسب نیستند. در `number` عنوان بیش از سه کلمه (کلمه یعنی رشته‌ی میان دو فاصله‌ی U+0020 یا U+00A0؛ نیم‌فاصله کلمه را نمی‌شکند: `title.trim().split(RegExp('[ ${String.fromCharCode(0xA0)}]+')).length`) و `progress.fraction` بزرگ‌تر از ۱ بدون `statusText`. در هر دو شکل `state` برابر `error` یا `empty` بدون `stateContent`. ممنوع در کارت: دکمه، نمودار، آیکون تزئینی، `Divider`، کارت تودرتو، `Tooltip` و هر عنصر تعاملی غیر از خود کارت.
- **SC-03 (نقش‌ها و رنگ‌ها):** نقش عدد قهرمان را `placement` تعیین می‌کند، نه والد: `homeBalance` ← `display`؛ `moduleHero` ← `title` در Compact و Medium و `heading` در Expanded و Large (HI-07). برچسب کارت `hero` نقش `label` با `text-secondary` دارد؛ نسبت عدد به برچسب دست‌کم ۱٫۶ است (VI-01: ۳٫۱ و ۲٫۳ و ۱٫۷). عدد قهرمان `homeBalance` همیشه `neutral` است، حتی منفی (VI-20)؛ `positive` و `critical` فقط جایی مجازند که جدول نقشه‌ی اطلاعات همان صفحه (HI-01) صریح بگوید. در کارت `number` عنوان و مقدار هر دو `title-sm` هستند (HI-07)، ولی عنوان `text-secondary` می‌گیرد (برچسبِ عدد است، نه سرتیتر فهرست) و مقدار `text-primary`؛ سلسله‌مراتب با ترتیب و رنگ ساخته می‌شود، نه با اندازه. کارت هیچ تزئین رنگی (نوار، آیکون، پس‌زمینه‌ی رنگی) ندارد.
- **SC-04 (چیدمان `hero`):** از بالا: ردیف برچسب (برچسب در start؛ اگر کارت ضربه‌پذیر است آیکون جهت‌دار `icon-md` با `text-secondary` در end طبق ۲-۷)، `space-1`، عدد قهرمان (`CurrencyAmount` یا شمارنده، تراز start)، و اگر ردیف هست `space-2` و سپس ردیف‌ها بدون فاصله‌ی میانی و بدون `Divider`؛ اگر `finePrint` هست `space-1` و `caption` با `text-secondary`. ردیف پشتیبان: برچسب `body-sm` با `text-secondary` در start و مقدار `body-sm` با `text-primary` در end (`CurrencyAmount` با نقش `body-sm`)؛ کمینه‌ی ارتفاع ۲۴؛ برچسب تا دو خط می‌شکند (CM-07) و مقدار هرگز نمی‌شکند (CA-02)؛ ردیف ضربه‌پذیر نیست. ردیف بی‌برچسب فقط مقدار را در start می‌گذارد. ردیف‌های «درآمد این ماه» و «هزینه‌ی این ماه» همیشه هر دو نشان داده می‌شوند، حتی با مقدار صفر.
- **SC-05 (چند ارز؛ تفسیر IN-7 از HM-03):** وقتی حساب‌های فعال بیش از یک ارز دارند هیچ جمع میان‌ارزی ساخته نمی‌شود (MN-06) و کارت موجودی (`homeBalance`) چنین می‌شود: برچسب «موجودی کل به تفکیک ارز»؛ عدد قهرمان (`display`) موجودی ارز اول؛ ردیف‌های پشتیبان (حداکثر دو، بی‌برچسب) موجودی ارز دوم و سوم؛ و اگر ارزها بیش از سه‌اند یک `finePrint` به شکل «+N ارز دیگر» (N = تعداد ارزها منهای ۳). ردیف‌های «درآمد این ماه» و «هزینه‌ی این ماه» در این حالت ساخته نمی‌شوند (هر دو متعلق به یک ارزند و در حسابداری دیده می‌شوند). ترتیب ارزها همان ترتیب اولین حساب هر ارز در فهرست حساب‌هاست (ترتیب نمایش حسابداری؛ SD-03). کل کارت ضربه‌پذیر است و به حسابداری می‌رود؛ `finePrint` دکمه نیست، چون عنصر تعاملی تودرتو ممنوع است. با یک ارز: برچسب «موجودی کل»، یک عدد قهرمان و دو ردیف «درآمد این ماه» و «هزینه‌ی این ماه». این تفسیر برای تأیید مالک در جدول IN ثبت شده و تا تأیید، همین رفتار ساخته می‌شود.
- **SC-06 (کارت `number` و نوار پیشرفت):** از بالا: عنوان (`title-sm`، `text-secondary`، تا دو خط)، `space-1`، مقدار (`CurrencyAmount` یا شمارنده با نقش `title-sm`)، و به ترتیب اختیاری: `comparisonText` (`body-sm`، `text-secondary`، فاصله‌ی بالا `space-1`) و `progress` (فاصله‌ی بالا `space-2`). `comparisonText` هرگز سبز یا قرمز نیست و جهت را با کلمه می‌گوید («۱۲٪ کمتر از مهر»؛ VI-20، CM-11). `SummaryProgress` یک نوار افقی است: ارتفاع `space-2` (۸)، `radius-full`، ریل `ring-track`، پرشدگی با رنگ تأکید ماژول (`context.accent`)؛ این همان جفت اعتبارسنجی‌شده‌ی کمان حلقه و ریل در ۲-۸ است. `fraction` در بازه‌ی ۰ تا ۱ رسم می‌شود و اگر بزرگ‌تر از ۰ و کوچک‌تر از `space-2` باشد، پرشدگی ۸px دیده می‌شود. وقتی `fraction` بیشتر از ۱ است نوار پر است و `statusText` («بیش از بودجه») زیر نوار با `space-1` و `body-sm` و رنگ `danger` می‌آید؛ قرمز بدون این متن مجاز نیست. نوار هیچ حرکتی ندارد و مقدار تازه آنی می‌نشیند.
- **SC-07 (تعامل):** کارت فقط وقتی ضربه‌پذیر است که صفحه‌ی جزئیات دارد، یعنی `onTap` غیر `null` است (HI-05، MR-04). همه‌ی سطح کارت هدف لمس است. hover، focus و pressed طبق جدول بالا و MO-01 است؛ ریپل ندارد. صفحه‌کلید: کارت ضربه‌پذیر فوکوس می‌گیرد و Enter و Space آن را فعال می‌کنند؛ کارت غیرقابل ضربه فوکوس نمی‌گیرد، آیکون ندارد و hover ندارد.
- **SC-08 (شمارش عدد اصلی؛ MO-14):** شمارش فقط برای `HeroValue.money` اجرا می‌شود، نه برای `count`. دو موقعیت دارد: نخستین نمایش مقدار واقعی پس از بارگذاری (از ۰) و تغییر مقدار در حالی که کارت روی صفحه است (از مقدار نمایش‌داده‌شده‌ی همان لحظه). بازگشت به صفحه، چرخش دستگاه، تغییر تم و rebuild شمارش را تکرار نمی‌کند؛ تغییر ارز یا تغییر نقش عدد آنی است. مدت و منحنی `max` و `decelerate` است. مقدار میانی با `BigInt` محاسبه می‌شود: `from + (delta × k) ~/ 1000` که k = گرد(منحنی(t) × ۱۰۰۰) است؛ ضرب در `int` ممنوع است چون برای مبلغ ۱۸ رقمی سرریز می‌کند. مقدار میانی به مضرب واحد نمایش و به سمت مبدأ گرد می‌شود (تومان: مضرب ۱۰ ریال؛ MN-02) تا رقم اعشار سوسو نزند و از بازه‌ی مبدأ تا مقصد بیرون نرود (MR-02)؛ فریم آخر دقیقاً برابر مقدار واقعی است و از `format` می‌آید. با کاهش حرکت (RM-01) فقط فریم آخر نمایش داده می‌شود. برچسب Semantics در همه‌ی فریم‌ها مقدار نهایی است (CA-05، MR-02).
- **SC-09 (Semantics):** کل کارت یک گره است؛ بقیه `excludeSemantics` می‌شوند. برچسب با جداکننده‌ی «؛ » چنین ساخته می‌شود: برچسب یا عنوان؛ مقدار گفتاری عدد اصلی؛ هر ردیف («برچسب ردیف: مقدار گفتاری» یا فقط مقدار گفتاری)؛ `comparisonText`؛ `progress.semanticLabel` و `statusText`؛ `finePrint`. اگر ضربه‌پذیر است `button: true` دارد. در حالت‌های loading، error و empty گره‌ی خود Skeleton یا ErrorState یا EmptyState خوانده می‌شود (۷-۱۲).
- **SC-10 (آزمون):** آزمون ویجت: ۱) assertهای SC-02 (سه ردیف، عنوان چهارکلمه‌ای، `display` با `moduleHero` همه `AssertionError` می‌دهند)؛ ۲) ارتفاع‌های جدول بالا در عرض ۳۶۰ و مقیاس ۱٫۰ با `tester.getSize` دقیقاً برابرند؛ ۳) کلید `ValueKey('summary-hero-number')` برای سنجش HI-02 در آزمون صفحه موجود است؛ ۴) شمارش با `FakeClock` و `MotionProbe`: فریم اول «۰»، فریم آخر دقیقاً متن `format`، مقدارهای میانی مضرب واحد، برچسب Semantics در همه‌ی فریم‌ها نهایی، و با `disableAnimations` فریم اول همان فریم آخر است؛ ۵) چهار ارز ← یک عدد قهرمان، دو ردیف و `finePrint` «+۱ ارز دیگر» و هیچ مجموع میان‌ارزی؛ ۶) کارت ضربه‌پذیر `button` است و `onTap` را یک‌بار صدا می‌زند، کارت غیرقابل ضربه `InkWell` و آیکون ندارد. golden: سه جایگاه × (تک‌ارزی، چندارزی، خالی، در حال بارگذاری، خطا) در چهار ترکیب جهت × تم، و «بدترین حالت» بخش ۱۰ در مقیاس ۲٫۰.
