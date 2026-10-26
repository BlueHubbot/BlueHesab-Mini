<!-- split from UI spec · 7-10 · lines 1809-1922 -->

### ۷-۱۰ برگه‌ی پایین، دیالوگ و پاپ‌اوور (`BottomSheet`، `Dialog`، `Popover`)

این سه کامپوننت «لایه‌ی روی صفحه»‌اند. `BottomSheet` در Compact و Medium جای پنجره‌ی ثبت سریع و انتخاب‌گرهای چیپ است (QT-04، CP-01)؛ `Dialog` در Expanded و Large جای همان پنجره و جای همه‌ی تأییدهاست (NV-04)؛ `Popover` در Expanded و Large جای انتخاب‌گرهای چیپ و فهرست اعلان‌هاست (CP-01، TB-03). قاعده‌های مشترک (مودال‌بودن، درخواست بستن، فوکوس، Semantics) یک‌بار اینجا نوشته شده و برای هر سه یکسان است؛ ظاهر و هندسه‌ی هر کدام در جدول خودش می‌آید.

```dart
enum CloseReason { barrier, drag, escape, systemBack, closeButton }
enum CloseDecision { close, stay }
typedef CloseRequest = FutureOr<CloseDecision> Function(CloseReason reason);

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder bodyBuilder,   // تنها ناحیه‌ی اسکرول‌شونده
  WidgetBuilder? headerBuilder,         // ثابت، زیر دستگیره
  WidgetBuilder? footerBuilder,         // ثابت، چسبیده به پایین
  CloseRequest? onCloseRequested,       // null یعنی هر درخواست بسته می‌کند
  bool dismissible = true,              // false فقط در saving (IDP-02)
  String? semanticTitle,                // نام مسیر برای صفحه‌خوان؛ از کاتالوگ
  FocusNode? initialFocus,              // پیش‌فرض: اولین عنصر فوکوس‌پذیر بدنه
});

enum DialogWidth { form, confirm }      // form: ۴۲۰ (QuickAdd)؛ confirm: حداکثر ۳۶۰

Future<T?> showAppDialog<T>(
  BuildContext context, {
  required DialogWidth width,
  required WidgetBuilder builder,
  CloseRequest? onCloseRequested,
  bool dismissible = true,
  String? semanticTitle,
  FocusNode? initialFocus,
});

enum ConfirmSecondaryKind { destructiveQuiet, tertiary }
enum ConfirmResult { primary, secondary }  // پس‌زمینه و Escape برابر primary هستند

class ConfirmDialogVM {
  const ConfirmDialogVM({
    required this.title,                // از کاتالوگ (QX-19)
    required this.message,
    required this.primaryLabel,         // دکمه‌ی امن و تنها دکمه‌ی پرکننده
    required this.secondaryLabel,
    this.secondaryKind = ConfirmSecondaryKind.destructiveQuiet,
  });
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final ConfirmSecondaryKind secondaryKind;
}

enum PopoverSize { picker, panel }      // ۲۸۰ و ۳۶۰

Future<T?> showAppPopover<T>(
  BuildContext context, {
  required Rect anchor,                 // مستطیل عنصر بازکننده، در مختصات پنجره
  required PopoverSize size,
  required WidgetBuilder builder,
  FocusNode? initialFocus,
});
```

**هندسه‌ی `BottomSheet`:**

| ویژگی | مقدار |
| --- | --- |
| عرض | Compact: تمام عرض پنجره. Medium: `side-panel-width` (۴۲۰) و وسط‌چین افقی. در Expanded و Large برگه‌ی پایین به کار نمی‌رود (به‌جایش `Dialog` و `Popover`) |
| جایگاه | چسبیده به لبه‌ی پایین پنجره؛ اگر صفحه‌کلید باز است لبه‌ی پایین برگه روی لبه‌ی بالای صفحه‌کلید می‌نشیند (بالا آمدن همراه صفحه‌کلید رفتار بومی است؛ KB-01، MT-09) |
| شکل | گوشه‌های بالا `radius-xl`؛ گوشه‌های پایین ۰ |
| سطح | `surface-raised`، مرز ۱px `border`، `elev-2` و `scrim` پشتش (CM-12). مرز روی لبه‌ی بالا و گوشه‌ها و در Medium روی دو لبه‌ی کناری است؛ لبه‌ی پایین و لبه‌هایی که به لبه‌ی پنجره چسبیده‌اند مرز ندارند |
| دستگیره | ناحیه‌ی ۲۰px در بالا (۸ + نوار ۴ + ۸) با نوار ۳۲×۴ از `radius-full` و رنگ `border-strong`. ناحیه‌ی کشیدن تمام عرض و ۴۴px بالای برگه است (دستگیره و ۲۴px نخست سربرگ)؛ بقیه‌ی محتوا برگه را نمی‌کشد |
| ارتفاع | به اندازه‌ی محتوا؛ حداکثر برابر کمینه‌ی ۰٫۹ × ارتفاع پنجره و (ارتفاع پنجره − `viewInsets.bottom` − `padding.top`). در ۳۶۰×۶۴۰ با صفحه‌کلید ۲۶۰px: ۳۸۰ و لبه‌ی پایین برگه روی خط ۳۸۰ |
| فضای ایمن پایین | `viewPadding.bottom` به padding پایین اضافه می‌شود، فقط وقتی صفحه‌کلید بسته است |
| ساختار | از بالا: دستگیره (۲۰)، `header` ثابت (اختیاری)، `body` اسکرول‌شونده، `footer` ثابت (اختیاری). وقتی محتوا از ارتفاع حداکثر بیشتر شود فقط `body` اسکرول می‌شود و `header` و `footer` دیده می‌مانند |

**هندسه‌ی `Dialog`:**

| ویژگی | مقدار |
| --- | --- |
| عرض | `DialogWidth.form`: `side-panel-width` (۴۲۰). `DialogWidth.confirm`: حداکثر ۳۶۰. هر دو حداکثر عرض پنجره منهای ۲×`space-4` و وسط‌چین افقی و عمودی (عمودی در ناحیه‌ی بالای صفحه‌کلید اگر باز باشد) |
| ارتفاع | به اندازه‌ی محتوا؛ حداکثر ۰٫۹ ارتفاع پنجره (QT-04)؛ بیشتر از آن فقط ناحیه‌ی اسکرول محتوای خود فراخواننده اسکرول می‌شود |
| سطح | `surface-raised`، مرز ۱px `border`، `elev-2`، `scrim` و `radius-xl` در هر چهار گوشه (CM-12) |
| قاب | `showAppDialog` فقط سطح، scrim و دام فوکوس را می‌دهد و padding درونی ندارد؛ چیدمان درون `form` را مالک آن (QD) می‌سازد |
| `ConfirmDialog` | padding `space-6` در هر چهار سمت؛ عنوان `title-sm` با `text-primary`؛ `space-2`؛ متن `body` با `text-primary`؛ `space-6`؛ دکمه‌ها زیر هم و تمام‌عرض با اندازه‌ی `md` و فاصله‌ی `space-2`، دکمه‌ی اصلی بالا. در هیچ مقیاس متنی دکمه‌ها کنار هم نمی‌آیند |

**هندسه‌ی `Popover`:**

| ویژگی | مقدار |
| --- | --- |
| عرض | `PopoverSize.picker`: ۲۸۰؛ `PopoverSize.panel`: ۳۶۰؛ هر دو حداکثر عرض پنجره منهای ۲×`space-4` |
| جایگاه | زیر عنصر بازکننده با فاصله‌ی `space-1` و لبه‌ی start هم‌تراز لبه‌ی start عنصر. اگر از پنجره بیرون می‌زند، به‌اندازه‌ی لازم به سمت دیگر جابه‌جا می‌شود تا دست‌کم `space-4` تا لبه‌ی پنجره بماند. اگر زیر عنصر جا نیست و بالای آن جای بیشتری هست، بالای عنصر می‌نشیند؛ وگرنه زیر می‌ماند و ارتفاعش کوتاه می‌شود |
| ارتفاع | به اندازه‌ی محتوا؛ حداکثر کوچک‌تر از ۴۰۰ و (فضای موجود تا لبه‌ی پنجره منهای `space-4`)؛ محتوای بیشتر درون خودش اسکرول می‌شود |
| سطح | `surface-raised`، مرز ۱px `border`، `elev-1`، `radius-lg` (CM-12)؛ scrim ندارد |

**حرکت لایه‌ها** (جدول ۴-۳؛ هر چه اینجا نیامده حرکت ندارد):

| لایه | ورود | خروج | با کاهش حرکت |
| --- | --- | --- | --- |
| `BottomSheet` (MO-08) | از لبه‌ی پایین به‌اندازه‌ی ارتفاع خودش و هم‌زمان محو scrim؛ `enter` و `decelerate` | برعکس؛ `exit` و `accelerate` | محو، بدون جابه‌جایی |
| رها کردن کشیدن (MO-08) | ندارد | از جای فعلی به حالت نهایی (بسته یا برگشته) با `base` و `standard` | آنی |
| `Dialog` و `ConfirmDialog` (MO-09) | شفافیت ۰ به ۱ و مقیاس ۰٫۹۶ به ۱ با scrim؛ `base` و `decelerate` | فقط شفافیت ۱ به ۰ با scrim؛ `exit` و `accelerate` | فقط محو، بدون مقیاس |
| `Popover` | آنی | آنی | آنی |

- **OV-01 (مودال‌بودن):** `BottomSheet` و `Dialog` مودال‌اند: پشت آن‌ها `scrim` (توکن رنگ؛ روشن `rgba(15,23,42,0.40)` و تاریک `rgba(0,0,0,0.60)`) کل پنجره‌ی برنامه را می‌پوشاند و پس‌زمینه ورودی لمس، ماوس، صفحه‌کلید و صفحه‌خوان نمی‌گیرد (از درخت فوکوس و Semantics بیرون است). حداکثر دو مودال هم‌زمان باز است و لایه‌ی دوم فقط در این دو حالت مجاز است: انتخاب‌گر چیپ روی پنجره‌ی ثبت سریع (CP-01) و دیالوگ بستن روی پنجره‌ی ثبت سریع (DR-01)؛ جریان ساخت حساب (SD-05) داخل همان انتخاب‌گر است و لایه‌ی سوم نمی‌سازد. هر لایه scrim خودش را دارد و فقط لایه‌ی بالا ورودی می‌گیرد. `Popover` مودال نیست، ولی هنگام باز بودن نخستین pointer-down بیرون از آن را می‌بندد و به عنصر زیرین نمی‌رسد.
- **OV-02 (درخواست بستن):** پنج راه بستن (ضربه روی پس‌زمینه، کشیدن فقط در `BottomSheet`، Escape، بازگشت سیستم‌عامل و دکمه‌ی بستن) همه به یک تابع `onCloseRequested(reason)` می‌رسند. دکمه‌ی بستن را فراخواننده در `header` می‌گذارد و خودش `closeButton` را گزارش می‌دهد. پاسخ `stay` یعنی هیچ‌چیز بسته نمی‌شود (کشیدن به جای خود برمی‌گردد). `dismissible: false` چهار راه غیر از دکمه را بی‌صدا نادیده می‌گیرد و `onCloseRequested` را صدا نمی‌زند (حالت saving؛ IDP-02). Future برگشتی فقط با بسته شدن واقعی کامل می‌شود.
- **OV-03 (کشیدن `BottomSheet`):** برگه فقط از ناحیه‌ی ۴۴px بالایش کشیده می‌شود؛ بدنه هرگز برگه را نمی‌کشد، تا اسکرول بدنه و کشیدن برگه با هم قاطی نشوند. برگه فقط رو به پایین و یک‌به‌یک با انگشت جابه‌جا می‌شود؛ رو به بالا روی صفر می‌ماند و کشش یا فنر ندارد. هنگام کشیدن شفافیت scrim برابر مقدار پایه × (۱ − جابه‌جایی ÷ ارتفاع برگه) است. با رها کردن: اگر جابه‌جایی دست‌کم ۳۰٪ ارتفاع برگه یا سرعت رو به پایین دست‌کم ۷۰۰px بر ثانیه باشد `onCloseRequested(drag)` صدا زده می‌شود و وگرنه برگه با `base` و `standard` به جای خود برمی‌گردد. پاسخ `stay` هم برگه را برمی‌گرداند و پاسخ `close` آن را از همان نقطه با `base` و `standard` تا بسته شدن کامل می‌برد (MO-08).
- **OV-04 (فوکوس):** الف) هنگام باز شدن فوکوس به `initialFocus` می‌رود؛ پیش‌فرض اولین عنصر فوکوس‌پذیر بدنه است و در `ConfirmDialog` دکمه‌ی امن (primary). ب) تا بسته نشدن مودال، Tab و Shift+Tab فقط میان عناصر خودش و به ترتیب دیداری می‌چرخد و پس‌زمینه فوکوس نمی‌گیرد. پ) پس از بسته شدن فوکوس به عنصری برمی‌گردد که هنگام باز کردن فوکوس داشت (بازکننده)، مگر قاعده‌ی خاص‌تری بگوید: پس از انتخاب در انتخاب‌گر چیپ فوکوس به فیلد اصلی نوع می‌رود (CP-01) و پس از بسته شدن پنجره‌ی ثبت سریع طبق SV-02. اگر آن عنصر دیگر در صفحه نیست، فوکوس به اولین عنصر فوکوس‌پذیر صفحه می‌رود. ت) `Popover` همین قاعده‌ها را دارد و Tab در آن هم می‌چرخد؛ Escape آن را می‌بندد.
- **OV-05 (Semantics):** `BottomSheet` و `Dialog` یک گره‌ی مسیر دارند (`scopesRoute` و `namesRoute`) با نام `semanticTitle` (برای ثبت سریع «ثبت سریع»؛ QX-01؛ برای `ConfirmDialog` عنوانش). دستگیره `excludeSemantics` است. اقدام `dismiss` (ژست escape در VoiceOver و بازگشت در TalkBack) همان `onCloseRequested(systemBack)` را صدا می‌زند. پس‌زمینه از درخت Semantics بیرون است. `Popover` گره‌ی مسیر ندارد؛ باز بودنش را `expanded` بازکننده اعلام می‌کند (CT-02).
- **OV-06 (حرکت):** ردیف‌ها طبق جدول بالا. اگر بستن حین ورود شروع شود حرکت از پیشرفت فعلی برعکس می‌شود و جهشی نیست؛ باز کردن دوباره حین خروج ممکن نیست و مودال تازه‌ای ساخته می‌شود. scrim همیشه محو می‌شود (حتی با کاهش حرکت) و مدت و منحنی لایه‌اش را دارد. بالا آمدن برگه همراه صفحه‌کلید رفتار بومی است و جزو ردیف‌ها نیست (KB-01، MT-09).
- **OV-07 (`ConfirmDialog`):** فقط برای تأیید مخرب یا خروج با تغییر (NV-04، DR-01، QX-19) و با تابع `showConfirmDialog(context, vm)` که `ConfirmResult` برمی‌گرداند. دو دکمه دارد: `primaryLabel` با `AppButtonVariant.primary` (دکمه‌ی امن، یعنی آنچه چیزی را از بین نمی‌برد) و `secondaryLabel` با `destructiveQuiet` یا `tertiary`. دکمه‌ی مخرب هرگز پیش‌فرض فوکوس یا پرکننده نیست؛ Enter روی دکمه‌ی فوکوس‌دار عمل می‌کند و Escape و پس‌زمینه برابر `primary` هستند. دیالوگی با بیش از دو دکمه، فیلد ورودی یا محتوای دلخواه `ConfirmDialog` نیست؛ از `showAppDialog` با `DialogWidth.form` ساخته می‌شود و ردیف تازه در ۷-۰ می‌خواهد.
- **OV-08 (جای `Popover`):** الف) مستطیل بازکننده در مختصات پنجره گرفته می‌شود و ارتفاع محتوا h حداکثر ۴۰۰ است. ب) فضای زیر = ارتفاع پنجره − پایین مستطیل − `space-1` − `space-4` و فضای بالا = بالای مستطیل − `space-1` − `space-4`. پ) اگر h از فضای زیر بیشتر نباشد زیر می‌نشیند؛ وگرنه اگر فضای بالا از فضای زیر بیشتر باشد بالا می‌نشیند با ارتفاع کمینه‌ی h و فضای بالا؛ وگرنه زیر می‌ماند با ارتفاع برابر فضای زیر (و محتوا اسکرول می‌شود). ت) در راستای افقی لبه‌ی start همین‌تراز لبه‌ی start بازکننده است و اگر از پنجره بیرون بزند آن‌قدر جابه‌جا می‌شود که فاصله‌ی `space-4` تا لبه‌ی پنجره بماند. ث) با اسکرول صفحه‌ی پشت، تغییر اندازه‌ی پنجره یا چرخش، `Popover` بسته می‌شود.
- **OV-09 (رنگ تأکید):** هر سه لایه accent بازکننده را در لحظه‌ی باز کردن می‌گیرند و زیر `AccentScope` همان accent ساخته می‌شوند (لایه‌ها زیر Navigator هستند، نه زیر صفحه)، مگر ریشه‌ی خودشان صریحاً چیز دیگری بگذارد (QD-01: در ثبت سریع `primary`). هیچ لایه‌ای رنگ ماژول جاری را از مسیر نمی‌خواند.
- **OV-10 (ممنوع‌ها):** کشیدن برگه با بدنه؛ برگه‌ی تمام‌صفحه یا بلندتر از ۹۰٪ پنجره؛ scrim یا سایه‌ی سفارشی؛ `Popover` با scrim؛ مودالِ سوم؛ `Dialog` روی `Popover`؛ `BottomSheet` در Expanded و Large؛ `Popover` در Compact و Medium (نوار بالا و اعلان‌ها فقط در Expanded و Large هستند؛ TB-01)؛ انیمیشن برای `Popover`؛ دکمه‌ی بستن بدون `semanticLabel`.
- **OV-11 (آزمون):** در چهار نمای مرجع (Compact ۳۶۰×۶۴۰، Medium ۷۶۸×۱۰۲۴، Expanded ۱۰۲۴×۷۶۸، Large ۱۴۴۰×۹۰۰): الف) هندسه: `BottomSheet` در Compact عرض ۳۶۰ و در Medium عرض ۴۲۰ با فاصله‌ی ۱۷۴ از دو سمت؛ `Dialog` فرم در Expanded و Large عرض ۴۲۰؛ `ConfirmDialog` در Compact عرض ۳۲۸ و در Expanded عرض ۳۶۰. ب) با `viewInsets.bottom = 260` در Compact: حداکثر ارتفاع برگه ۳۸۰ و لبه‌ی پایین آن روی خط ۳۸۰ است. پ) کشیدن برگه‌ی ۳۰۰px: رها کردن در ۸۹px با سرعت ۰ برمی‌گردد، در ۹۱px بسته می‌شود، در ۱۰px با سرعت ۸۰۰px بر ثانیه بسته می‌شود و با ۶۰۰px بر ثانیه برمی‌گردد؛ با پاسخ `stay` در هر حالت برمی‌گردد. ت) با `dismissible: false` پس‌زمینه، کشیدن، Escape و بازگشت سیستم‌عامل `onCloseRequested` را صدا نمی‌زنند. ث) فوکوس: اولیه، چرخش Tab و Shift+Tab، بازگشت به بازکننده و نبودن بازکننده. ج) `ConfirmDialog`: فوکوس اولیه روی دکمه‌ی اصلی، Escape و پس‌زمینه برابر `primary`، دکمه‌ها زیر هم در مقیاس متن ۱٫۰ و ۲٫۰. چ) `Popover`: زیر، بالا و ارتفاع‌کوتاه‌شده با مختصات OV-08 و بسته شدن با اولین کلیک بیرون که به عنصر زیرین نمی‌رسد. ح) با `MotionProbe` و `FakeClock`: ورود `BottomSheet` در ۰ و ۱۶۰ و ۳۲۰ms جابه‌جایی باقی‌مانده‌ی ۱۰۰٪ و ۱۱٪ (با خطای ۲٪) و ۰٪ ارتفاع برگه است؛ خروج در ۱۰۰ و ۲۰۰ms جابه‌جایی ۳۷٪ (با خطای ۲٪) و ۱۰۰٪؛ `Dialog` در ۱۲۰ms شفافیت ۰٫۸۹ و مقیاس ۰٫۹۹۶ (با خطای ۰٫۰۲) و در ۲۴۰ms شفافیت ۱ و مقیاس ۱؛ خروج `Dialog` در ۱۰۰ms شفافیت ۰٫۶۳ و در ۲۰۰ms صفر؛ `Popover` در همان فریم کامل دیده می‌شود؛ با `disableAnimations` برگه و دیالوگ فقط با محو و بدون جابه‌جایی و مقیاس ظاهر می‌شوند. خ) golden: برگه (Compact و Medium)، دیالوگ فرم (Expanded)، `ConfirmDialog` (Compact و Expanded)، `Popover` (زیر و بالا) در چهار ترکیب جهت × تم، و برگه‌ی Compact با صفحه‌کلید در مقیاس ۲٫۰. (QT-04، CP-01، NV-04، DR-01، SV-02، IDP-02، MO-08، MO-09، KB-01)
