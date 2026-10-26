# مشارکت · Contributing

**BlueHesab Mini** (آبی‌حساب) یک برنامه‌ی رایگان، متن‌باز (Apache-2.0)، فارسی‌محور و local-first برای مدیریت مالی شخصی و ماژول‌های اختیاری است. پروژه هنوز در مرحله‌ی **مستندسازی و قرارداد** است؛ کد از بعد از spike و تصویب ADRهای پایه شروع می‌شود.

## قبل از شروع
1. `README.md` و `docs/product/MVP_SCOPE.md` (پس از نوشته‌شدن) را بخوان.
2. `docs/ops/STATUS.md` را ببین تا بدانی پروژه کجاست.
3. برای کار روی رابط: `docs/design/ui-spec/README.md` و فقط فایل‌های مربوط. کل سند را نخوان.
4. مشارکت‌کننده‌ی ایجنت (هوش مصنوعی) باید `AGENTS.md` را هم رعایت کند.

## مسیر کار
issue کوچک و مشخص → شاخه‌ی جدا → کار + آزمون + مستند → PR با شواهد → بازبینی (نه توسط نویسنده) → ادغام.

- نام شاخه: `agent/<نقش>-<شناسه>-<شرح>` یا `area/<حوزه>-<شرح>` یا `fix/<شرح>`.
- commit کوچک و هدف‌دار؛ پیام به انگلیسی؛ شناسه‌ی قاعده یا کار (مثلاً `QD-04`, `T-003`) در پیام بیاید.
- push مستقیم به `main` و force-push ممنوع است.

## قواعد مهم
- **مجوز مشارکت:** با ارسال PR موافقت می‌کنی که مشارکتت تحت Apache-2.0 باشد (بند ۵ مجوز).
- **کد و دارایی‌های دیگران:** هیچ کد، فونت، آیکون، مدل یا داده‌ای را بدون ثبت مجوز دقیق در `docs/research/OPEN_SOURCE_AUDIT.md` وارد نکن. کد GPL/AGPL فقط مرجع است و کپی نمی‌شود.
- **حریم خصوصی:** هیچ پیامک، رسید، داده‌ی مالی یا سلامت واقعی در issue، PR، آزمون یا لاگ نگذار. فقط داده‌ی ساختگی.
- **پول:** `BigInt` واحد کوچک، هرگز `double`.
- **رابط:** فقط توکن و کاتالوگ متن؛ مقدار خام رنگ، فاصله، زمان یا رشته‌ی فارسی در کد نیست.
- **آزمون:** تغییر بدون آزمون پذیرفته نمی‌شود؛ نتیجه‌ی واقعی را بنویس.

## گزارش اشکال و پیشنهاد
از قالب‌های issue استفاده کن. موضوع امنیتی را عمومی نگذار (`SECURITY.md`).

---

## English summary
BlueHesab Mini is a free, open-source (Apache-2.0), Persian-first, local-first personal finance app. It is in the documentation/contract stage. Workflow: small issue → isolated branch → task + tests + docs → PR with evidence → review by someone other than the author → merge. No direct pushes to `main`. Contributions are licensed under Apache-2.0. Do not copy third-party code, fonts, icons, models or data before recording the exact license; GPL/AGPL code is reference-only. Never post real SMS, receipts or financial/health data. Money is `BigInt` minor units, never `double`. Agent contributors must follow `AGENTS.md`.
