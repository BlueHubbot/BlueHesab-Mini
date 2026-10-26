<!-- split from UI spec · section 8 · lines 3442-3658 -->

## ۸. رابط دستیار هوشمند

وضعیت: پیشنهاد (Proposed) و ذیل ADR-UI-001. مالک قرارداد این بخش Agent 1 است؛ پیاده‌سازی AssistantPage و AIActionCard با Agent 5 (ورودی هوشمند) است. این بخش فقط رابط را تعریف می‌کند: مدل، تبدیل گفتار، OCR و امتیاز اطمینان در use-case هستند و از راه ViewModel می‌رسند (CM-01). ماژول assistant اختیاری است و فقط وقتی فعال است که مقصد دستیار و دکمه‌ی «ورودی هوشمند» ثبت سریع دیده می‌شوند (IN-6، DM-01، QT-05). پیشوند قاعده‌ها AI و پیشوند متن‌ها AIX است.

### ۸-۱ اصل‌ها

- **AI-01 (پیشنهاد است، نه واقعیت):** هر خروجی مدل یک پیشنهاد است و با نشان «پیشنهاد» و دکمه‌ی تأیید صریح دیده می‌شود (VI-05). تا ضربه‌ی کاربر روی «تأیید و ثبت» هیچ داده‌ای ذخیره یا عوض نمی‌شود. تأیید خودکار، تأیید با زمان‌سنج، تأیید با Enter روی یک فیلد و فوکوس اولیه روی دکمه‌ی تأیید ممنوع است.
- **AI-02 (مرز و منبع داده):** کامپوننت‌ها هیچ‌جا مدل را صدا نمی‌زنند و اطمینان را حساب نمی‌کنند؛ همه‌چیز از ViewModel می‌آید (CM-01). متن‌ها از کاتالوگ AIX یا از ViewModel‌اند (CM-10) و مبلغ همیشه با `MoneyVM` و `CurrencyAmount` نشان داده می‌شود، نه با الحاق رشته (MN-03). ثبت پس از تأیید از همان use-case ثبت سریع (`SaveQuickAdd`) می‌گذرد، با همان idempotency (IDP-01 تا IDP-05)، همان Toast موفقیت با «واگرد» (SV-03، UN-01) و همان خطاهای ثبت؛ نشانه‌ی منشأ «دستیار» را use-case می‌گذارد و UI فقط تأیید را می‌فرستد.
- **AI-03 (یک درخواست در هر زمان):** تا وقتی کارتی در `processing` است نوار ورودی `busy` است و ارسال، ضبط و افزودن عکس غیرفعال‌اند. پس در هر لحظه حداکثر یک PulseDot در حالت thinking هست (VI-06، PD-02) و این قاعده به‌جای assert با ساختار برقرار می‌شود.

### ۸-۲ صفحه‌ی دستیار (AssistantPage)

```dart
// نمونه؛ نام‌ها و مقدارها قرارداد است (CM-02).
enum AssistantInputMode { idle, recording, busy, offline, off }   // off: مدل در تنظیمات خاموش است

sealed class AssistantTurn { const AssistantTurn(); }
final class UserTurn extends AssistantTurn { const UserTurn(this.text); final String text; }     // متن تایپ‌شده، متن تبدیل‌شده‌ی صدا یا متن OCR
final class ReplyTurn extends AssistantTurn { const ReplyTurn(this.text); final String text; }   // پاسخ متنی؛ هر تکه که برسد همان لحظه اضافه می‌شود (MT-10)
final class CardTurn extends AssistantTurn { const CardTurn(this.id, this.card); final String id; final AIActionCard card; }

class AssistantLabels {                     // همه از کاتالوگ AIX (CM-10)
  const AssistantLabels({
    required this.inputHint, required this.send, required this.record, required this.stopRecording,
    required this.addImage, required this.recordingText, required this.cloudNote,
    required this.offlineHint, required this.offTitle, required this.openSettings,
    required this.emptyTitle, required this.emptyDescription,
  });
  final String inputHint, send, record, stopRecording, addImage, recordingText, cloudNote,
      offlineHint, offTitle, openSettings, emptyTitle, emptyDescription;
}

class AssistantPage extends StatelessWidget {
  const AssistantPage({
    super.key,
    required this.status,                   // ModelStatus از ۷-۸
    required this.turns,
    required this.inputMode,
    required this.controller,               // TextEditingController نوار ورودی
    required this.labels,
    required this.onSend,
    required this.onToggleRecording,
    required this.onPickImage,
    this.onOpenSettings,                    // الزامی وقتی inputMode == off
  });
  final ModelStatus status;
  final List<AssistantTurn> turns;
  final AssistantInputMode inputMode;
  final TextEditingController controller;
  final AssistantLabels labels;
  final VoidCallback onSend, onToggleRecording, onPickImage;
  final VoidCallback? onOpenSettings;
}
```

جدول ۸-۲-الف: ساختار AssistantPage از بالا (PG-01)

| ترتیب | عنصر | اندازه و فاصله | منبع |
| --- | --- | --- | --- |
| ۱ | `PageHeader` | عنوان «دستیار» (در Expanded و Large عنوان در TopBar است)؛ بدون اقدام | PG-01، TB-01 |
| ۲ | `OfflineBanner` | فقط وقتی آفلاین است | PG-01 |
| ۳ | ردیف وضعیت مدل | `ModelStatusDot` در start با فاصله‌ی `space-4`؛ فاصله‌ی بالا `space-2`؛ ارتفاع از خط `caption` (۲۰)؛ اسکرول نمی‌شود | PD-06 |
| ۴ | گفتگو | تنها ناحیه‌ی اسکرول؛ ستون حداکثر `reading-max-width` (۷۲۰) وسط‌چین؛ فاصله‌ی افقی `space-4`؛ فاصله‌ی نوبت‌ها `space-4`؛ فضای انتهایی `space-4` (دکمه‌ی QuickAdd ندارد) | QA-02، QA-03 |
| ۵ | نوبت کاربر | قاب CM-12 (`surface`، مرز ۱px، `radius-lg`)؛ فاصله‌ی داخلی افقی `space-3` و عمودی `space-2`؛ متن `body`؛ در end؛ حداکثر ۸۰٪ ستون | CM-12 |
| ۶ | پاسخ متنی | بدون قاب؛ `body` و `text-primary`؛ در start؛ تمام ستون | — |
| ۷ | `AIActionCard` | تمام ستون | ۸-۳ |
| ۸ | یادداشت ابری | `caption` و `text-secondary` با فاصله‌ی افقی `space-4` و فاصله‌ی پایین `space-1`؛ فقط وقتی مدل ابری است | AI-06 |
| ۹ | نوار ورودی | ثابت پایین، بالای نوار پایین و ناحیه‌ی امن و صفحه‌کلید؛ فاصله‌ی افقی `space-4` و عمودی `space-2`؛ پس‌زمینه‌ی `background` و بدون مرز؛ ارتفاع یک‌خطی ۶۰ (۴۴ + ۲ × `space-2`) و حداکثر ۱۲۸ (فیلد چهار خط) | AI-05 |

- **AI-04 (ساختار):** صفحه همان ترتیب جدول ۸-۲-الف را دارد و کاری جز نمایش `turns` نمی‌کند. گفتگوی خالی `EmptyState` regular است (ST-02) با آیکون ماژول assistant (IN-2)، عنوان `emptyTitle`، توضیح `emptyDescription` و بدون اقدام. گفتگو فقط وقتی به آخرین نوبت می‌رود که کاربر پیش‌تر پایین بوده است؛ وگرنه جای اسکرول حفظ می‌شود (NV-01). نوبت تازه‌ی `ReplyTurn` متن را تکه‌تکه و بدون جلوه‌ی تایپ اضافه می‌کند (MT-10).
- **AI-05 (نوار ورودی):** از end به start: دکمه‌ی ارسال یا ضبط (فقط یکی؛ ارسال وقتی متن خالی نیست و ضبط وقتی خالی است)، فیلد، دکمه‌ی افزودن عکس. هر دکمه `IconButton` ۴۴×۴۴ با برچسب و Tooltip هم‌نام است (BU-08)؛ آیکون ارسال جهت‌دار است و در RTL آینه می‌شود (۲-۷). فیلد `AppTextField` چندخطی است، تا چهار خط بزرگ می‌شود و بعد خودش اسکرول می‌کند. برچسب دیداری بالای فیلد ندارد و `hint` و `semanticLabel` آن یک متن (AIX-18) است؛ این سومین استثنای FD-01 است (پس از NT-01 و جست‌وجوی انتخابگر) و تأیید Agent 1 می‌خواهد. ارسال فقط با دکمه است؛ میان‌بر صفحه‌کلید در ADR-UI-008 ثبت می‌شود (QA-05). در `recording` یک سطر «در حال ضبط…» (AIX-23، `body-sm` و `text-secondary`، بی‌زمان‌سنج و بی‌انیمیشن) بالای فیلد هست و دکمه‌ی ضبط به «توقف ضبط» (AIX-21) تبدیل می‌شود. دکمه‌ی «ورودی هوشمند» ثبت سریع (QT-05) پنجره را می‌بندد و صفحه‌ی دستیار را با MO-04 باز می‌کند و فوکوس روی فیلد است؛ ضبط خودکار شروع نمی‌شود. اگر اجازه‌ی میکروفون یا دوربین داده نشود یک `ReplyTurn` با AIX-28 می‌آید و دوباره درخواست نمی‌شود مگر با ضربه‌ی تازه.

جدول ۸-۲-ب: وضعیت مدل و رفتار صفحه (PD-06)

| ModelStatus | `AssistantInputMode` | نوار ورودی | کارت‌های موجود |
| --- | --- | --- | --- |
| `local` (محلی) | `idle` یا `busy` یا `recording` | فعال | عادی |
| `cloud` (ابری) | همان | فعال و AIX-24 بالای فیلد | عادی |
| `offline` (آفلاین) | `offline` | فیلد و سه دکمه غیرفعال؛ `hint` برابر AIX-25 | تأیید و رد کار می‌کنند، چون ثبت محلی است و به مدل نیاز ندارد |
| `disabled` (غیرفعال) | `off` | جای نوار، `EmptyState` کوچک با AIX-26 و یک دکمه‌ی secondary با AIX-27 که `onOpenSettings` را صدا می‌زند (ST-04، ST-05) | عادی |

- **AI-06 (وضعیت مدل):** وضعیت مدل همیشه با `ModelStatusDot` در ردیف ۳ جدول ۸-۲-الف دیده می‌شود، با شکل و برچسب متنی، نه با رنگ تنها (جدول ۱-۲، CM-11)؛ ردیف تعاملی نیست و Tooltip ندارد. تغییر وضعیت مدل ردیف را آنی عوض می‌کند و هیچ نبضی نمی‌زند؛ تنها حرکت این ناحیه thinking کارت است (AI-14). رفتار صفحه برای هر وضعیت فقط جدول ۸-۲-ب است؛ ابری‌بودن را نباید فقط از شکل نقطه فهمید، پس AIX-24 همیشه کنار فیلد هست.

### ۸-۳ کارت پیشنهاد (AIActionCard)

```dart
// نمونه؛ نام‌ها و مقدارها قرارداد است (CM-02).
enum AICardState { processing, suggested, saving, saved, failed }
enum AIConfidence { sure, unsure, missing }                 // AI-10

class AILabels {                                            // همه از کاتالوگ AIX (CM-10)
  const AILabels({
    required this.proposal, required this.savedBadge, required this.processing,
    required this.confirm, required this.confirmLoading, required this.dismiss,
    required this.why, required this.unsure, required this.missing,
    required this.confirmDisabledReason, required this.retry, required this.openRecord,
  });
  final String proposal, savedBadge, processing, confirm, confirmLoading, dismiss, why,
      unsure, missing, confirmDisabledReason, retry, openRecord;
}

class AIFieldVM {
  AIFieldVM({required this.id, required this.confidence, required this.control})
      : assert(control is AppNumberField || control is AppTextField ||
               control is AppSelect || control is AppDatePicker, 'AI-07');
  final String id;               // amount، category، account، toAccount، date، note، title، due
  final AIConfidence confidence;
  final Widget control;          // همان ویجت‌های ثبت سریع؛ برچسب را خود کنترل دارد
}

class AIActionCard extends StatefulWidget {
  AIActionCard({
    super.key,
    required this.state,
    required this.labels,
    required this.semanticSummary,        // «پیشنهاد ثبت هزینه؛ ۲ مورد نیاز به بررسی.» را use-case می‌سازد
    this.title,                           // «ثبت هزینه»؛ حداکثر سه کلمه (HI-04)
    this.fields = const [],               // ۱ تا ۶؛ فقط در suggested و saving
    this.why,                             // متن «چرا؟»؛ null یعنی دکمه نیست
    this.isNewest = true,                 // فقط جدیدترین کارت دکمه‌ی پر دارد (AI-09)
    this.saveError,                       // FieldMessage خطا بالای دکمه (BU-04)
    this.processError,                    // FieldMessage خطا در failed
    this.savedAmount, this.savedDetail,   // فقط در saved
    this.onConfirm, this.onDismiss, this.onRetry, this.onOpenRecord,
  })  : assert(state != AICardState.suggested && state != AICardState.saving ||
               (title != null && fields.isNotEmpty && fields.length <= 6), 'AI-08'),
        assert(title == null || wordCount(title) <= 3, 'HI-04'),
        assert(state != AICardState.saved || (title != null && savedAmount != null), 'AI-12'),
        assert(state != AICardState.failed || (processError != null && onRetry != null), 'AI-12');
  final AICardState state;
  final AILabels labels;
  final String semanticSummary;
  final String? title, why, saveError, processError, savedDetail;
  final List<AIFieldVM> fields;
  final bool isNewest;
  final MoneyVM? savedAmount;
  final VoidCallback? onConfirm, onDismiss, onRetry, onOpenRecord;
  @override
  State<AIActionCard> createState() => throw UnimplementedError();
}
```

جدول ۸-۳-الف: چیدمان کارت (قاب CM-12، فاصله‌ی داخلی کلی `space-4`)

| بخش | محتوا و اندازه | فاصله تا بخش بعد |
| --- | --- | --- |
| سرتیتر (`suggested`، `saving`، `saved`) | عنوان `title-sm` و `text-primary` و `AppBadge.status` کنارش در یک `Wrap` با فاصله‌ی `space-2` (BG-07): «پیشنهاد» با tone اطلاعات (`info`) و آیکون، و در `saved` «ثبت شد» با tone موفقیت (`success`) و آیکون تیک | `space-3` |
| سرتیتر (`processing`) | `PulseDot` با اندازه‌ی `md` در start، `space-2` و AIX-03 با `body-sm` و `text-secondary`؛ ارتفاع ۲۴؛ نه عنوان دارد نه Badge | کارت تمام می‌شود |
| فیلدها | کنترل‌های `AIFieldVM` به ترتیب `fields`؛ مبلغ و عنوان کار اول؛ چیپ‌ها پس از آن در `ChipRow` (حداکثر ۳)؛ transfer چیپ‌های مبدأ و مقصد را با جداکننده‌ی جهت‌دار (CT-04) و تاریخ را در `ChipRow` جدا دارد | `space-3` میان کنترل‌ها؛ `space-4` تا دکمه‌ی اصلی |
| نشانه‌ی فیلد | زیر کنترل‌های `unsure` و `missing`: آیکون `icon-sm` و متن `caption` با `text-primary` (AI-10) | `space-1` بالا |
| دکمه‌ی اصلی | `Button.primary` اندازه‌ی `lg` (۴۸)؛ در Compact تمام‌عرض و در بقیه به اندازه‌ی محتوا در end؛ وقتی غیرفعال است `disabledReason` زیرش می‌آید (BU-06) | `space-2` |
| ردیف دوم | «چرا؟» در start و «رد» در end، هر دو `Button.tertiary` اندازه‌ی `sm` با ناحیه‌ی لمس ۴۴ (CM-04) | `space-2` تا متن «چرا؟» |
| متن «چرا؟» | فقط وقتی باز است: `body-sm` و `text-secondary`، تا هر چند خط که لازم باشد | — |
| سرتیتر و خلاصه‌ی `saved` | ردیف: `CurrencyAmount` با نقش `body` و `savedDetail` با `body-sm` و `text-secondary`؛ «مشاهده» (`tertiary`، `sm`) در end فقط اگر `onOpenRecord` هست | — |

جدول ۸-۳-ب: حالت‌های کارت

| حالت | محتوا | دکمه‌ها | فیلدها |
| --- | --- | --- | --- |
| `processing` | PulseDot thinking و AIX-03 | هیچ | — |
| `suggested` | سرتیتر، فیلدها، دکمه‌ها | تأیید فعال مگر `missing` یا `onConfirm == null`؛ «چرا؟» اگر `why` هست؛ «رد» | قابل‌ویرایش |
| `saving` | همان `suggested` | دکمه‌ی اصلی `loading` با AIX-05 (BU-04، MO-13)؛ «چرا؟» و «رد» غیرفعال | `IgnorePointer` و `ExcludeFocus` (مثل IDP-02) |
| `saved` | سرتیتر با «ثبت شد» و خلاصه | فقط «مشاهده» | حذف می‌شوند |
| `failed` | `FieldMessage` خطا با `processError` | «تلاش دوباره» (`secondary`، `md`، `loading` با BU-04) و «رد» | — |

- **AI-07 (کنترل‌ها):** فیلدهای قابل‌ویرایش همان کنترل‌های ثبت سریع‌اند: `AppNumberField` برای مبلغ (با `maxIntegerDigits` و `fractionDigits` ارز، AM-01)، `AppTextField` برای یادداشت و عنوان کار، و `AppSelect` و `AppDatePicker` در `ChipRow` برای دسته، حساب و تاریخ (CP-01)؛ نوع و ترتیب فیلد هر `QuickAddType` همان جدول ۷-۱۱ است (QT-01) و کارت نوع تازه نمی‌سازد. سازنده `AIFieldVM` هر ویجت دیگری را assert می‌کند. ویرایش فیلد را فراخواننده به ViewModel می‌برد و اطمینان فیلد ویرایش‌شده را `sure` می‌کند؛ کارت خودش وضعیتی نگه نمی‌دارد جز بازبودن «چرا؟». یادداشت بدون مقدار با دکمه‌ی متنی «افزودن یادداشت» باز می‌شود (NT-01). چون `AppSelect` و `AppDatePicker` در همین کارت هستند، همان قاعده‌های PK و Popover یا BottomSheet برای باز شدن‌شان برقرار است.
- **AI-08 (ساختار کارت):** چیدمان جدول ۸-۳-الف است و هیچ ارتفاعی ثابت نیست (CM-07)؛ فاصله‌ها با `tester.getRect` سنجیده می‌شوند. عنوان کارت حداکثر سه کلمه است (HI-04): «ثبت هزینه»، «ثبت درآمد»، «ثبت انتقال»، «افزودن کار». هر کارت یک پیشنهاد برای یک اقدام است؛ پیشنهاد چندمرحله‌ای یا فهرستی از پیشنهادها در این نسخه نیست.
- **AI-09 (دکمه‌ها):** فقط یک دکمه‌ی پر در صفحه هست (BU-01، PG-03): دکمه‌ی تأیید جدیدترین کارتِ `suggested` یا `saving` `primary` است (`isNewest`) و همین دکمه‌ی پرِ صفحه است. کارت‌های `suggested` قدیمی‌تر همان دکمه را `secondary` با همان برچسب دارند. صفحه `isNewest` را از ترتیب `turns` حساب می‌کند. برچسب‌ها حداکثر سه کلمه‌اند (BU-03). دکمه‌ی تأیید وقتی غیرفعال است که فیلدی `missing` باشد یا `onConfirm` نباشد؛ دلیلش AIX-10 زیر دکمه است و تنها `primary` با اندازه‌ی `lg` چنین خطی دارد (BU-06). ضربه‌ی دوباره حین `saving` فراخوانی دوم نمی‌سازد (BU-05).
- **AI-10 (عدم قطعیت):** اطمینان هر فیلد یکی از سه مقدار است. `sure`: بدون نشانه. `unsure`: زیر کنترل آیکون هشدار (`icon-sm`، رنگ `warning`) و AIX-08 با `caption` و `text-primary`. `missing`: آیکون خطا (`icon-sm`، رنگ `danger`) و AIX-09. رنگ هرگز تنها نیست (CM-11، TK-04) و متن `text-secondary` نیست چون روی سطح قاب است و جفت‌رنگ باید در ۲-۸ باشد (CM-09). `unsure` تأیید را مسدود نمی‌کند؛ ضربه‌ی صریح کاربر بر «تأیید و ثبت» همان بازبینی است. `missing` تأیید را غیرفعال می‌کند. نشانه‌ی فیلد بلافاصله پس از ویرایش آن فیلد (تغییر ViewModel) برداشته می‌شود و حرکت ندارد. شمار فیلدهای `unsure` و `missing` در `semanticSummary` می‌آید.
- **AI-11 («چرا؟»):** «چرا؟» تنها بازشونده‌ی کارت است (HI-06): بسته شروع می‌شود، باز و بسته شدن آنی است (MT-04)، تودرتو ندارد و `Semantics.expanded` می‌گیرد. متن را use-case می‌دهد (دو تا سه جمله: از کدام بخش ورودی هر مقدار آمد و کدام حدس بود) و هیچ اطلاعات ضروری فقط در آن نیست (HI-06). بازبودن در State کارت است و با بازسازی ویجت یا اسکرول از دست نمی‌رود، ولی با تغییر `state` بسته می‌شود.
- **AI-12 (حالت‌ها):** حالت‌ها جدول ۸-۳-ب است. شکست پردازش و شکست ثبت اقدام کاربرند، نه بارگذاری داده، پس `ErrorState` نمی‌گیرند (ST-03): شکست پردازش در `failed` با `FieldMessage` و «تلاش دوباره» دیده می‌شود و شکست ثبت در `suggested` با `saveError` بالای دکمه‌ی اصلی و بدون از دست رفتن ویرایش‌ها. وقتی مدل چیزی برای ثبت پیدا نکند کارتی ساخته نمی‌شود و `ReplyTurn` با AIX-17 می‌آید. در `saved` فیلدها برداشته می‌شوند و کارت دیگر ویرایش‌پذیر نیست؛ ثبت واگرد را فقط Toast دارد (SV-03).
- **AI-13 (رد و واگرد):** «رد» دیالوگ تأیید ندارد، چون هیچ داده‌ای ذخیره نشده است (مثل DM-03). کارت با MO-11 (حذف) می‌رود و Toast با AIX-14 و دکمه‌ی «واگرد» (`toast-undo-visible`) می‌آید؛ تا بسته شدن Toast ViewModel ویرایش‌ها را نگه می‌دارد و «واگرد» کارت را با همان فیلدها و MO-11 (درج) برمی‌گرداند. «رد» در `failed` کارت را بدون Toast برمی‌دارد.
- **AI-14 (پردازش و PulseDot):** PulseDot در `processing` با حالت `thinking` و اندازه‌ی `md` است و AIX-03 همیشه کنارش هست، با هر تنظیم حرکت (PD-04). جایگاه PulseDot همین سرتیتر کارت است و ModelStatusDot ردیف صفحه است؛ هر دو جایگاه سوم PD-01 را می‌سازند و جای دیگری PulseDot دیده نمی‌شود. `error` برای PulseDot در این نسخه استفاده نمی‌شود، چون شکست پردازش با `FieldMessage` و آیکون خطا نشان داده می‌شود (PD-05). تایپ‌شدن ساختگی، شمارش معکوس و هر جلوه‌ی انتظار دیگر ممنوع است (MT-10).
- **AI-15 (حرکت):** کارت فقط یک ردیف حرکت دارد، MO-11: درج با `base` و `decelerate` و حذف با `exit` و `accelerate`؛ با کاهش حرکت آنی است و بدون هایلایت. thinking همان MO-17 است و از راه PulseDot می‌آید (جدول ۷-۰). تغییر `state`، تغییر نشانه‌ی فیلد، باز و بسته شدن «چرا؟» و تغییر وضعیت مدل حرکت ندارند.
- **AI-16 (Semantics و فوکوس):** هر کارت یک گره‌ی `container` با برچسب `semanticSummary` است و عنوانش `header` است؛ کنترل‌های درونش گره‌های خودشان را دارند. هنگام ورود کارت به `suggested` برچسب یک‌بار با liveRegion از نوع polite خوانده می‌شود و فوکوس را نمی‌گیرد. `processing` متن AIX-03 را با liveRegion polite یک‌بار می‌خواند (PD-04) و PulseDot خودش `excludeSemantics` است (PD-06). Badge و نشانه‌های فیلد برچسب خودشان را دارند و آیکون‌هایشان `ExcludeSemantics` است (BG-08). ترتیب Tab: فیلدها به ترتیب دیداری، سپس دکمه‌ی اصلی، «چرا؟» و «رد». پس از «رد» یا ثبت موفق فوکوس به فیلد ورودی صفحه برمی‌گردد.

### ۸-۴ متن‌ها

جدول ۸-۴-الف: متن‌های AIX (کاتالوگ بخش ۹ همین ردیف‌ها را دارد)

| شناسه | متن | کاربرد |
| --- | --- | --- |
| AIX-01 | پیشنهاد | نشان کارت |
| AIX-02 | ثبت شد | نشان کارت ثبت‌شده |
| AIX-03 | در حال پردازش… | کنار PulseDot (PD-04) |
| AIX-04 | تأیید و ثبت | دکمه‌ی اصلی کارت |
| AIX-05 | در حال ذخیره… | `loadingLabel` دکمه‌ی اصلی |
| AIX-06 | رد | دکمه‌ی رد |
| AIX-07 | چرا؟ | بازشونده |
| AIX-08 | نیاز به بررسی | نشانه‌ی `unsure` |
| AIX-09 | لازم است | نشانه‌ی `missing` |
| AIX-10 | ابتدا مورد الزامی را تکمیل کنید. | `disabledReason` دکمه‌ی اصلی |
| AIX-11 | ذخیره نشد. دوباره تلاش کنید. | `saveError` |
| AIX-12 | پردازش انجام نشد. | `processError` |
| AIX-13 | مشاهده | باز کردن رکورد ثبت‌شده |
| AIX-14 | پیشنهاد رد شد. | Toast رد |
| AIX-15 | چه کاری انجام بدهم؟ | عنوان گفتگوی خالی |
| AIX-16 | با نوشتن، گفتن یا عکس رسید بگویید چه چیزی ثبت شود. | توضیح گفتگوی خالی |
| AIX-17 | چیزی برای ثبت پیدا نشد. | `ReplyTurn` بدون کارت |
| AIX-18 | بنویسید چه چیزی ثبت شود | `hint` و `semanticLabel` فیلد |
| AIX-19 | ارسال | برچسب دکمه‌ی ارسال |
| AIX-20 | ضبط صدا | برچسب دکمه‌ی ضبط |
| AIX-21 | توقف ضبط | برچسب دکمه در `recording` |
| AIX-22 | افزودن عکس | برچسب دکمه‌ی عکس |
| AIX-23 | در حال ضبط… | سطر `recording` |
| AIX-24 | پردازش روی سرور انجام می‌شود. | یادداشت مدل ابری |
| AIX-25 | برای استفاده از دستیار به مدل نیاز است. | `hint` در `offline` |
| AIX-26 | دستیار خاموش است. | پیام `off` |
| AIX-27 | باز کردن تنظیمات | دکمه‌ی `off` |
| AIX-28 | اجازه‌ی دسترسی داده نشد. | `ReplyTurn` پس از رد مجوز |

«تلاش دوباره» از جدول ۷-۱۲-ث و «واگرد» از Toast (TO) می‌آیند و AIX ندارند.

### ۸-۵ آزمون

- **AI-17 (آزمون):** مطابق CM-13: الف) یک آزمون ویجت برای هر ردیف جدول‌های ۸-۲-الف، ۸-۲-ب، ۸-۳-الف و ۸-۳-ب؛ فاصله‌ها با `tester.getRect` در عرض ۳۶۰ و ۷۶۸ و ۱۰۲۴ و ۱۴۴۰ و مقیاس ۱٫۰ و ۱٫۵ و ۲٫۰ و ارتفاع نوار ورودی ۶۰ و ۱۲۸. ب) assertها: کارت `suggested` بدون عنوان یا با ۷ فیلد، عنوان چهارکلمه‌ای، `saved` بدون `savedAmount`، `failed` بدون `onRetry`، کنترلی جز چهار نوع مجاز؛ وجود دو کارت `processing` در یک صفحه (AI-03). پ) تأیید: بدون ضربه‌ی کاربر `onConfirm` صدا زده نمی‌شود حتی با Enter روی فیلد؛ با فیلد `missing` دکمه غیرفعال است و AIX-10 دیده می‌شود؛ با `unsure` فعال است؛ ویرایش فیلد نشانه را برمی‌دارد؛ ضربه‌ی دوباره حین `saving` فراخوانی دوم نمی‌سازد. ت) دکمه‌ی پر: با سه کارت `suggested` فقط جدیدترین `primary` است. ث) حالت‌ها: `saving` فیلدها را `IgnorePointer` و `ExcludeFocus` می‌کند؛ `saveError` ویرایش‌ها را نگه می‌دارد؛ `failed` «تلاش دوباره» را با loading دارد؛ «رد» Toast و «واگرد» کارت را با همان فیلدها برمی‌گرداند. ج) وضعیت مدل: چهار وضعیت، چهار رفتار جدول ۸-۲-ب؛ در `offline` تأیید کار می‌کند؛ در `off` دکمه‌ی تنظیمات `onOpenSettings` را صدا می‌زند. چ) حرکت با FakeClock و MotionProbe (MX-08): درج کارت در ۰ و ۱۲۰ و ۲۴۰ms ارتفاع ۰٪ و ۸۹٪ (با خطای ۲٪) و ۱۰۰٪؛ در `processing` `activeLoopCount` برابر ۱ و `activeCount` صفر است؛ با کاهش حرکت هر دو صفر و درج آنی؛ باز و بسته شدن «چرا؟» و تغییر نشانه صفر انیمیشن؛ تغییر `ModelStatus` صفر انیمیشن. ح) Semantics: `semanticSummary` یک‌بار با liveRegion polite، `header` عنوان، `expanded` «چرا؟»، PulseDot و آیکون‌ها بیرون از درخت، ترتیب Tab. خ) تضاد: `text-primary` روی `surface` و آیکون‌های `warning` و `danger` روی `surface` در هر دو تم (بخش ۱۱). د) golden: روشن و تاریک × RTL و LTR × مقیاس ۱٫۰ و ۲٫۰ برای `processing`، `suggested` عادی، `suggested` با `unsure` و `missing` و «چرا؟» باز، `saving`، `saved`، `failed`، چهار وضعیت مدل و گفتگوی خالی؛ و «بدترین حالت» بخش ۱۰: مبلغ ۱۵ رقمی، عنوان دوخطی، سه نشانه‌ی فیلد، متن «چرا؟» پنج‌خطی.
