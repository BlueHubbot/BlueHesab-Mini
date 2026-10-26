<!-- split from UI spec · 7-6 · lines 1521-1576 -->

### ۷-۶ کارت فهرست و ردیف (`ListCard`، `ListRow`)

`ListCard` کارت سطح ۲ برای پرسش «چه چیزی پشت این عدد است؟» است: عنوان کوتاه، حداکثر پنج ردیف و یک اقدام «همه». `ListRow` همان ردیف است و در فهرست‌های تمام‌صفحه هم با همین ابعاد می‌آید (آنجا سقف ۵ ردیف نیست و `ResponsiveList` ردیف‌ها را می‌چیند؛ ۷-۱۶). کارت هرگز اسکرول درونی ندارد (HI-04).

```dart
sealed class RowLeading {
  factory RowLeading.icon(IconData icon, {required ModuleAccent accent}) = _IconLeading;   // چیپ ۴۰×۴۰
  factory RowLeading.check({required bool checked, required ValueChanged<bool> onChanged}) = _CheckLeading;
}
sealed class RowTrailing {
  factory RowTrailing.money(MoneyVM money) = _MoneyTrailing;                                       // CurrencyAmount با نقش body
  factory RowTrailing.text({required String text, required String spokenText}) = _TextTrailing;   // body-sm، text-secondary
}

class ListRow extends StatelessWidget {
  const ListRow({
    required super.key,              // کلید پایدار شناسه‌ی داده، نه اندیس (LC-06)
    required this.title, this.subtitle, this.leading, this.trailing,
    this.onTap,                      // فقط وقتی جزئیات دارد (HI-05)
    this.highlight = false,          // فقط برای ردیفی که کاربر همین لحظه افزوده است (MO-11)
  }) : assert(leading is! _CheckLeading || onTap == null, 'LC-04');
}

class ListCard extends StatelessWidget {
  const ListCard({
    required this.title,             // حداکثر ۳ کلمه (HI-04)
    required this.rows,              // حداکثر ۵
    this.totalCount,                 // کل موارد؛ اگر بیش از ۵ باشد onShowAll اجباری است
    this.onShowAll,                  // اقدام «همه»
    this.state = CardState.ready, this.stateContent,
  }) : assert(rows.length <= 5, 'HI-04'),
       assert((totalCount ?? rows.length) <= 5 || onShowAll != null, 'HI-04');
}
```

**ارتفاع ردیف** (کمینه در مقیاس متن ۱٫۰، واحد px؛ فرمول: ۲ × `space-3` + بلندترین بخش):

| ترکیب | بلندترین بخش | ارتفاع ردیف |
| --- | --- | --- |
| فقط عنوان، بدون leading | عنوان `body` (۲۸) | ۵۲ |
| عنوان و زیرعنوان، بدون leading | ۲۸ + ۲۴ | ۷۶ |
| leading و فقط عنوان | چیپ یا چک‌باکس (۴۰) | ۶۴ |
| leading و عنوان و زیرعنوان | ۲۸ + ۲۴ | ۷۶ |

سرتیتر کارت ۶۰ ارتفاع دارد (۱۶ + ۳۶ + ۸). ارتفاع کارت با n ردیف: ۶۰ + مجموع ارتفاع ردیف‌ها + (n − ۱) برای جداکننده‌ها.

- **LC-01 (قاب و سرتیتر):** قاب CM-12 است و فاصله‌ی داخلی کلی ندارد؛ فاصله‌ها را بخش‌ها می‌دهند. سرتیتر: فاصله‌ی `space-4` از start و end و بالا و `space-2` از پایین؛ عنوان `title-sm` با `text-primary` در start (تا دو خط؛ CM-07) و، اگر `onShowAll` هست، دکمه‌ی «همه» (`Button.tertiary`، اندازه‌ی `sm`، برچسب «همه» و آیکون جهت‌دار `icon-sm` در end دکمه) در end سرتیتر. ارتفاع دیداری سرتیتر ۳۶ و ناحیه‌ی لمس دکمه ۴۴ است (CM-04). دکمه فقط وقتی مقصد دارد دیده می‌شود و وقتی `totalCount` بیش از ۵ است همیشه هست.
- **LC-02 (ردیف):** فاصله‌ی افقی `space-4` و عمودی `space-3`. ترتیب منطقی: leading، `space-3`، ستون متن (Expanded)، `space-3`، trailing و، اگر ضربه‌پذیر است، `space-2` و آیکون جهت‌دار `icon-md` با `text-secondary` در end. ارتفاع طبق جدول بالا است: کمینه `touch-min` و با مقیاس متن رشد می‌کند (CM-07). ستون متن: عنوان `body` با `text-primary` تا دو خط و زیرعنوان `body-sm` با `text-secondary` تا دو خط؛ بیش از دو خط با «…» کوتاه می‌شود و متن کامل در Semantics و صفحه‌ی جزئیات هست. trailing هرگز نمی‌شکند و بریده نمی‌شود (CA-02)، بر ستون متن اولویت دارد و وسط‌چین عمودی است. leading از نوع `icon` چیپی ۴۰×۴۰ (`avatar-md`) با `radius-md`، پس‌زمینه‌ی `{accent}-subtle` و آیکون `icon-md` با رنگ `{accent}` است (جفت اعتبارسنجی‌شده‌ی ۲-۸)؛ `accent` را خود ردیف صریح می‌گیرد، چون ردیف‌های ویجت «رویدادهای نزدیک» هر کدام رنگ ماژول خودشان را دارند. leading از نوع `check` چک‌باکس (۷-۱۶) در وسط یک جایگاه ۴۰×۴۰ است.
- **LC-03 (ضربه‌پذیری و حالت‌ها):** ردیف فقط وقتی `onTap` دارد که جزئیات دارد (HI-05؛ مقصد طبق MR-04). کل ردیف از لبه تا لبه‌ی کارت هدف لمس است. hover، focus و pressed: لایه‌ی `text-primary` با شفافیت ۰٫۰۸ و ۰٫۱۰ و ۰٫۱۲ (MO-01). چون کارت محتوا را با `radius-lg` می‌برد، حلقه‌ی فوکوس ردیف (۲-۶) داخل مرز ردیف رسم می‌شود، نه بیرون آن. ردیف بدون `onTap` فوکوس، hover و آیکون ندارد.
- **LC-04 (ردیف چک‌دار):** در ردیف با leading از نوع `check` کل ردیف هدف تغییر چک است، نه ناوبری؛ پس `onTap` ممنوع است (assert) و جزئیات از «همه» دیده می‌شود. وقتی `checked` است عنوان `text-secondary` می‌شود (بدون خط‌خوردگی) و چک‌باکس هم وضعیت را می‌گوید؛ Semantics مقدار `checked` را اعلام می‌کند.
- **LC-05 (جداکننده):** `Divider` فقط بین ردیف‌های یک کارت می‌آید: ۱px با رنگ `border` و فاصله‌ی `space-4` از دو طرف. بالای ردیف اول، زیر ردیف آخر و در سرتیتر جداکننده نیست (HI-08).
- **LC-06 (درج و حذف؛ MO-11):** هر ردیف کلید پایدار شناسه‌ی داده دارد (نه اندیس). درج و حذف طبق MO-11 و با `app_motion` انجام می‌شود. وقتی کاربر همین لحظه ردیفی افزوده، والد `highlight: true` می‌دهد: پس‌زمینه‌ی ردیف `{accent}-subtle` می‌شود و در `enter` به شفاف می‌رسد؛ هم‌زمان رنگ متن‌های ثانویه‌ی همان ردیف از `text-primary` به `text-secondary` درون‌یابی می‌شود تا هیچ لحظه‌ای جفت ممنوعِ «`text-secondary` روی `*-subtle`» (CM-09) دیده نشود. اگر درجِ یک ردیف، ردیف ششم بسازد آخرین ردیف هم‌زمان حذف می‌شود و ارتفاع کارت یک‌پارچه تغییر می‌کند. با کاهش حرکت همه‌ی این‌ها آنی و بدون هایلایت است.
- **LC-07 (حالت‌ها):** حالت‌های کارت همان جدول ۷-۵ است با این تفاوت‌ها: `error` و `empty` عنوان کارت را نگه می‌دارند و فقط جای ردیف‌ها را با `ErrorState` یا `EmptyState` کوچک عوض می‌کنند (متن خالی هر ویجت از جدول ویجت‌های خانه می‌آید)؛ `loading` نوار عنوان و سه ردیف Skeleton است (۷-۱۲)؛ دکمه‌ی «همه» فقط در حالت `ready` دیده می‌شود.
- **LC-08 (Semantics):** عنوان کارت `header: true` است. هر ردیف یک گره با برچسب «{عنوان}؛ {زیرعنوان}؛ {مقدار گفتاری trailing}» به ترتیب دیداری است؛ ردیف ضربه‌پذیر `button: true` و ردیف چک‌دار `checked` دارد. دکمه‌ی «همه» برچسب «همه‌ی {عنوان کارت}» می‌گیرد (AQ-01).
- **LC-09 (assert و آزمون):** `assert` سازنده‌ها (HI-09): بیش از ۵ ردیف؛ عنوان بیش از سه کلمه (همان شمارش SC-02)؛ `totalCount` بیش از ۵ بدون `onShowAll`؛ ردیف چک‌دار با `onTap`. آزمون ویجت: شش مورد ← پنج ردیف و دکمه‌ی «همه» و هیچ `Scrollable` درون کارت؛ ارتفاع‌های جدول بالا با `tester.getSize`؛ ردیف بدون `onTap` فوکوس‌ناپذیر است؛ درج با `MotionProbe` هایلایت را نشان می‌دهد و با کاهش حرکت نشان نمی‌دهد. golden: پنج ردیف «بدترین حالت» بخش ۱۰ (عنوان دوخطی، مبلغ ۱۵ رقمی) در چهار ترکیب جهت × تم و مقیاس ۱٫۰ و ۲٫۰.
