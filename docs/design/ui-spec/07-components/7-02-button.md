<!-- split from UI spec · 7-2 · lines 1259-1326 -->

### ۷-۲ دکمه و دکمه‌ی آیکونی (`Button` و `IconButton`)

`Button` برچسب متنی دارد؛ `IconButton` فقط آیکون دارد و همیشه برچسب دسترس‌پذیری و Tooltip هم‌نام دارد. نقش هر واریانت ثابت است و هیچ صفحه‌ای واریانت تازه نمی‌سازد (CM-02).

```dart
// نمونه؛ نام‌ها و مقدارها قرارداد است (CM-02).
enum AppButtonVariant { primary, secondary, tertiary, destructive, destructiveQuiet }
enum AppButtonSize { md, lg, sm } // md=control-md 44، lg=control-lg 48، sm=control-sm 36

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,                 // از کاتالوگ متن (CM-10)
    required this.onPressed,             // null یعنی disabled
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,                    // فقط یک آیکون icon-md
    this.loading = false,
    this.loadingLabel,                   // مثل «در حال ذخیره…»
    this.expand = false,                 // تمام‌عرض
    this.disabledReason,                 // فقط primary با اندازه‌ی lg
  })  : assert(!loading || loadingLabel != null),
        assert(disabledReason == null ||
            (variant == AppButtonVariant.primary && size == AppButtonSize.lg));
}

enum AppIconButtonVariant { standard, filled }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.semanticLabel,         // فارسی؛ همان متن Tooltip
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
  });
}
```

| واریانت | سطح | مرز | محتوا | کاربرد |
| --- | --- | --- | --- | --- |
| `primary` | پرکننده‌ی `context.accent` (بیرون `AccentScope` برابر `primary`) | ندارد | `on-fill` | اقدام اصلی؛ در هر صفحه یا دیالوگ فقط یکی (PG-03) |
| `secondary` | `surface` | ۱px `border-strong` | `text-primary` | اقدام جایگزین |
| `tertiary` | شفاف | ندارد | `context.accent` | اقدام کم‌اهمیت و «همه» (HI-04) |
| `destructive` | پرکننده‌ی `danger` | ندارد | `on-fill` | فقط دکمه‌ی تأییدکننده‌ی دیالوگِ عملیات مخرب، وقتی خودِ حذف گزینه‌ی اصلی دیالوگ است |
| `destructiveQuiet` | شفاف | ۱px `danger` | `danger` | گزینه‌ی مخرب ثانویه در دیالوگی که گزینه‌ی اصلی‌اش امن است (NV-04، «دور انداختن») |

هندسه‌ی مشترک: شعاع `radius-md`؛ برچسب `label`؛ فاصله‌ی افقی داخلی `space-4` (`md` و `lg`) و `space-3` (`sm`)؛ فاصله‌ی آیکون و متن `space-2`؛ کمینه‌ی عرض `touch-min`؛ ارتفاع هر اندازه حداقل است، نه ثابت (CM-07).

| حالت | قاعده |
| --- | --- |
| عادی | طبق جدول واریانت‌ها |
| hover (فقط ماوس) | `primary` و `destructive`: توکن `*-hover`؛ بقیه: لایه‌ی `text-primary` با شفافیت ۰٫۰۸ (MO-01) |
| pressed | `primary` و `destructive`: توکن `*-pressed`؛ بقیه: لایه‌ی `text-primary` با شفافیت ۰٫۱۲ |
| focus (صفحه‌کلید) | حلقه‌ی ۲px با `focus-ring` و فاصله‌ی ۲px از لبه؛ بریده نمی‌شود (جدول ۲-۶) |
| disabled | سطح: `text-primary` با شفافیت ۰٫۱۲؛ محتوا و مرز: `text-primary` با شفافیت ۰٫۳۸؛ `onPressed` برابر null؛ `Semantics(enabled: false)` (BU-06) |
| loading | BU-04 |
| error | ندارد؛ خطا با `FieldMessage` بالای دکمه یا نزدیک فیلد نشان داده می‌شود (۷-۳) |

- **BU-01 (نقش‌ها):** در هر صفحه یا دیالوگ فقط یک دکمه‌ی پرکننده (`primary` یا `destructive`) هست (PG-03). پرکننده‌ی `primary` همیشه `context.accent` است؛ دکمه‌ی ثبت سریع و خودِ دکمه‌ی `QuickAdd` همیشه `primary` می‌مانند، چون ریشه‌ی پنجره‌ی ثبت سریع `AccentScope` را صریحاً روی `primary` می‌گذارد (QD-01) و دکمه‌ی `QuickAdd` بیرون هر `AccentScope` است. رنگ ماژول هیچ‌جای دیگر برای پرکننده‌ی دکمه استفاده نمی‌شود.
- **BU-02 (اندازه):** `md` پیش‌فرض است؛ `lg` برای دکمه‌ی اصلی تمام‌عرضِ پایین‌چسب در فرم‌های موبایل (PG-03، BT-01)؛ `sm` فقط برای میانبرهای ضرب (AM-03) و برای جدول و نوار ابزار در Expanded و Large (CM-04).
- **BU-03 (برچسب):** برچسب فعل امری یا اسم کوتاه است («ثبت»، «افزودن»، «ساخت حساب»)، حداکثر سه کلمه، بدون نقطه و بدون «…». «…» فقط در `loadingLabel` می‌آید. اگر در عرض جا نشد تا دو خط می‌شکند و ارتفاع دکمه بیشتر می‌شود (CM-07).
- **BU-04 (loading؛ MO-13):** دکمه‌ی در حال `loading` غیرفعال و بی‌اثر است. برچسب با crossfade (`micro`) به `loadingLabel` تغییر می‌کند؛ `loadingLabel` فعل در حال انجام با «…» است («در حال ذخیره…»). پس از `skeleton-delay` (۴۰۰ms) اسپینر ۱۶px (`icon-sm`، هم‌رنگ محتوای دکمه) در start خط ظاهر می‌شود و با `spinner-loop` (۸۰۰ms) و منحنی خطی می‌چرخد؛ اگر عملیات پیش از ۴۰۰ms تمام شود اسپینر هرگز ساخته نمی‌شود. عرض دکمه از بزرگ‌ترین عرض `label` و `loadingLabel` محاسبه می‌شود و در تمام مدت ثابت می‌ماند. با کاهش حرکت فقط متن می‌ماند (RM-03). برچسب Semantics در loading همان `loadingLabel` بدون «…» است، `enabled` برابر false است و فوکوس روی دکمه می‌ماند.
- **BU-05 (ضربه‌ی دوباره):** ضربه، Enter یا Space روی دکمه‌ی در حال `loading` فراخوانی دوم ایجاد نمی‌کند (TQ-02). وقتی عملیات با خطای قابل‌بازیابی تمام شد، دکمه دوباره فعال است و فوکوس را از دست نداده است.
- **BU-06 (disabled و دلیل):** دکمه‌ی غیرفعال اطلاعاتش را پنهان نمی‌کند. فقط دکمه‌ی `primary` با اندازه‌ی `lg` می‌تواند `disabledReason` داشته باشد: یک خط `caption` با `text-secondary` که بالای دکمه می‌آید (در ناحیه‌ی ثابت پایین، بالای دکمه‌ی پایین‌چسب؛ PG-03) و در `hint` گره‌ی Semantics هم تکرار می‌شود. وقتی دلیل بدیهی است (مبلغ خالی در QuickAdd؛ AM-04) یا دکمه فقط به‌خاطر `loading` غیرفعال است، `disabledReason` داده نمی‌شود. خط دلیل خطا نیست و `danger` نمی‌گیرد.
- **BU-07 (آیکون):** `leadingIcon` یک آیکون `icon-md` در start است. آیکون پایانی فقط شورون جهت‌دار در دکمه‌ی `tertiary` «همه» است (HI-04). آیکون‌های جهت‌دار طبق ۲-۷ در RTL آینه می‌شوند.
- **BU-08 (`IconButton`):** آیکون `icon-md` در ناحیه‌ی ۴۴×۴۴؛ `semanticLabel` الزامی است و همان متن Tooltip (hover و لمس طولانی) است. `standard` سطح ندارد و hover و pressed را به شکل دایره‌ی ۴۴ (`radius-full`) با لایه‌ی `text-primary` نشان می‌دهد. `filled` فقط برای دکمه‌ی `QuickAdd` است: دایره‌ی `fab` (۵۶) با پرکننده‌ی `primary` و آیکون `icon-lg` با `on-fill`. `IconButton` حالت loading ندارد؛ کار طولانی با `Button` یا `SyncStatus` نشان داده می‌شود.
- **BU-09 (آزمون):** برای هر واریانت در هر حالت جدول بالا یک آزمون ویجت و یک golden؛ عرض در loading با عرض عادی برابر است (اختلاف صفر پیکسل)؛ ضربه‌ی دوم در loading `onPressed` را صدا نمی‌زند؛ اندازه‌ی ناحیه‌ی لمس هر اندازه دست‌کم ۴۴×۴۴ است (`tester.getSize`)؛ حلقه‌ی فوکوس با Tab دیده می‌شود و با لمس دیده نمی‌شود؛ برچسب Semantics شامل برچسب دیداری است؛ اسپینر پیش از ۴۰۰ms وجود ندارد (MX-01) و با کاهش حرکت هرگز ساخته نمی‌شود (MX-02).
- **BU-10 (ارتفاع در مقیاس متن):** ارتفاع هر اندازه حداقل است (CM-07) و از ارتفاع خط label (۲۲×s) می‌آید: sm برابر `max(36, 22×s + 8)` یعنی ۳۶ و ۴۱ و ۵۲؛ md برابر `max(44, 22×s + 16)` یعنی ۴۴ و ۴۹ و ۶۰؛ lg برابر `max(48, 22×s + 16)` یعنی ۴۸ و ۴۹ و ۶۰، در مقیاس متن s = ۱٫۰ و ۱٫۵ و ۲٫۰. برای s میان این نقطه‌ها نتیجه به بالا به px کامل گرد می‌شود. ناحیه‌ی لمس هر اندازه بیشینه‌ی ۴۴ و ارتفاع دیداری است (CM-04). این اعداد همان‌هایی‌اند که جدول‌های ۷-۱۱-الف تا ث مصرف می‌کنند: میانبرهای «هزار» و «میلیون» (AM-03) با sm، دکمه‌ی اصلی ثبت سریع (BT-01) با lg، و «افزودن یادداشت» و «جزئیات بیشتر» (NT-01، QT-04) با md. آزمون: ارتفاع دکمه‌ی تک‌خطی هر اندازه در سه مقیاس برابر اعداد بالا است (tester.getSize) و در loading تغییر نمی‌کند (BU-09).
