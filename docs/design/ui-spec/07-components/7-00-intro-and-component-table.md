<!-- split from UI spec · section 7 intro · lines 1210-1242 -->

## ۷. مشخصات دقیق کامپوننت‌های اولویت‌دار با حالت‌ها و آزمون

**وضعیت:** پیشنهاد (بخشی از `ADR-UI-001`). مالک قرارداد کامپوننت‌های مشترک Agent 1 است و هر تغییر در API، اندازه یا حالت‌های این بخش فقط با تأیید او و همراه با به‌روزرسانی جدول‌ها و آزمون‌های همین بخش انجام می‌شود. کدهای Dart نمونه‌اند (فریم‌ورک هنوز در دست ارزیابی است)؛ نام‌ها، اندازه‌ها، حالت‌ها و آزمون‌ها قرارداد هستند و با تغییر فریم‌ورک حفظ می‌شوند.

هر کامپوننت با یک قالب ثابت شرح داده می‌شود: هدف، API نوع‌دار، اندازه و توکن‌ها، حالت‌ها، قواعد شماره‌دار و آزمون. چیزی که در بخش‌های ۱ تا ۶ آمده تکرار نمی‌شود و با شناسه ارجاع می‌گیرد؛ اگر متنی با آن‌ها نخواند، بخش مرجع برنده است و تناقض باید به Agent 1 گزارش شود. همه‌ی اندازه‌ها از توکن‌های بخش ۲ و همه‌ی متن‌ها از نقش‌های بخش ۳ می‌آیند.

| کامپوننت‌ها | پیشوند قاعده | بخش | ردیف‌های حرکت (۴-۳) |
| --- | --- | --- | --- |
| `Button`، `IconButton` | `BU` | ۷-۲ | MO-01، MO-13 |
| `TextField`، `NumberField`، `FieldMessage` | `FD` | ۷-۳ | MO-01 |
| `CurrencyAmount` | `CA` | ۷-۴ | ندارد |
| `SummaryCard` | `SC` | ۷-۵ | MO-14 |
| `ListCard`، `ListRow` | `LC` | ۷-۶ | MO-11 |
| `DayRing` | `DY` | ۷-۷ | MO-15 |
| `PulseDot` | `PD` | ۷-۸ | MO-17، MO-18 |
| `Chip`، `Tabs` | `CT` | ۷-۹ | MO-01، MO-03 |
| `BottomSheet`، `Dialog`، `Popover` | `OV` | ۷-۱۰ | MO-08، MO-09 |
| `QuickAdd` (مونتاژ) | `QD` | ۷-۱۱ | MO-08، MO-09، SV-01 |
| `EmptyState`، `ErrorState`، `Skeleton` | `ST` | ۷-۱۲ | MO-12 |
| `Toast` | `TO` | ۷-۱۳ | MO-10 |
| `OfflineBanner`، `SyncStatus` | `OS` | ۷-۱۴ | ندارد |
| `PageHeader` | `PH` | ۷-۱۵ | ندارد |
| `ResponsiveList` | `RL` | ۷-۱۶ | MO-11 |
| `Checkbox`، `Switch`، `SwitchRow` | `TG` | ۷-۱۶ | MO-01، MO-02 |
| `Select`، `DatePicker` (واریانت chip) | `PK` | ۷-۱۶ | MO-01 |
| `Badge` | `BG` | ۷-۱۶ | ندارد |
| `Divider` | `DV` | ۷-۱۶ | ندارد |
| `Tooltip` | `TP` | ۷-۱۶ | ندارد |
| `NumericCell`، `BidiText`، `PercentageChange`، `NumericColumnMetrics` | `NC` | ۷-۱۶ | ندارد |
| `FilterBar` | `FB` | ۷-۱۶ | MO-01 |
| `ChartContainer`، `ChartDataTable` | `CC` | ۷-۱۶ | MO-16 |
| `AIActionCard` | `AI` | بخش ۸ | MO-11، MO-17 (MO-17 فقط از طریق `PulseDot`) |
