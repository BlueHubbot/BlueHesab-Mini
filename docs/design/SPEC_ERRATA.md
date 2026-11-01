# Spec Errata — known gaps in the UI constitution (v1)

**Status:** 2026-10-26 · **Register owner:** Product/Contracts hat (Agent 1) · **Found by:** the Max consistency audit (`docs/ops/CONSISTENCY_AUDIT.md`) · **Rule IDs:** SE-01…SE-12 (project-owned namespace, not part of the spec).

## خلاصه‌ی فارسی
- در بازبینی نهایی، **۱۲ مورد** در متن قانون اساسی UI پیدا شد: **۱۰ مورد نیازمند اصلاح یا ثبت** (SE-01…06، 08، 09، 11، 12) و **۲ مورد اطلاعاتی** (SE-07، SE-10). هیچ‌کدام مانع شروع spike نیست؛ سه مورد با اهمیت متوسط (SE-04، SE-08، SE-09) و یک مورد کم‌اهمیت که از اولین اجرای برنامه دیده می‌شود (SE-12) پیش از کار QuickAdd/خانه/fixtureها باید بسته شوند.
- **هیچ فایلی در `docs/design/ui-spec/` تغییر نکرده است.** طبق AG-02 فقط Product/Contracts (Agent 1) مشخصات را عوض می‌کند؛ این فایل ثبت و پیشنهاد است. تا بسته شدن هر مورد، «قاعده‌ی موقت» همان ردیف معتبر است تا ایجنت‌ها برای هر مورد متوقف نشوند.
- ادعاهای عددی (۲۱۰ بررسی کنتراست، کمینه‌های جدول A-4، جمع‌های AX-06، شمار ردیف‌های ماتریس‌های GMX، ۲۴ قاعده‌ی ماشین‌چک، شمار شناسه‌ها) مستقل بازمحاسبه شد و درست بود؛ فقط یک عبارت کلامی (SE-06) با عدد اندازه‌گیری‌شده کاملاً هم‌خوان نبود.

## How this register works
- A spec change is made by the Product/Contracts hat in a reviewed PR that cites the erratum ID. Other hats raise a request (AGX-01) and get accepted / rejected / alternative (AG-16).
- **Kinds:** `contradiction` (two texts disagree), `gap` (a needed rule, row or data is missing), `clarify` (wording points to the wrong thing), `record` (a process record the spec asks for is missing), `info` (no change needed; written down so nobody re-discovers it).
- **Interim rule** = what project work does until the erratum is closed. It never contradicts a safety guarantee (ADR-UI-009 §2). When the spec is amended, delete the interim rule and set the status to `CLOSED` with the PR link.
- `docs_check` (R3/R5) treats `SE-NN` as a project namespace; it verifies that every cited `SE-NN` is defined in this file.

## Register
| ID | Kind | Severity | Where | Needed by | Status |
|---|---|---|---|---|---|
| SE-01 | clarify | low | 14 · GTX-03 | before v0.4 (smart input is `NOT_IN_BUILD` in v0.1) | OPEN |
| SE-02 | clarify | low | 13 · AG-10 ↔ 06 §6-7 | next housekeeping pass | OPEN |
| SE-03 | clarify | low | 09 intro ↔ 10-1-الف | next housekeeping pass | OPEN |
| SE-04 | gap | **medium** | 05 · HM-04 ↔ 09 · HMX | before the Home task (M2) | OPEN (DD-11 written) |
| SE-05 | record | low | 13 · AGR-05 ↔ 14 · EOX-01 | before the first `app_fixtures` task (M0) | OPEN |
| SE-06 | clarify | low | 02 · `border-strong` ↔ 11 · VTG-06 | next housekeeping pass | OPEN |
| SE-07 | info | — | 06 · QE-03 ↔ 10 · DS-02 | — | INFO |
| SE-08 | contradiction | **medium** | 03 · NM-06 ↔ 06 · AM-01, TQ-13 | before the QuickAdd task (M2) | OPEN |
| SE-09 | gap | **medium** | 10 · tables 10-2-ب, 10-2-پ | before the first `app_fixtures` task (M0) | OPEN |
| SE-10 | info | — | 08 · AI-14 ↔ 07-8 · PD-05 | — | INFO |
| SE-11 | gap | low | 08 · AIX-11 ↔ 06 · QX-16 | before v0.4 | OPEN |
| SE-12 | gap | low | 01 · VI-15 ↔ 09 · HMX-01 ↔ 05 · DM-01 | before the Home task (M2) | OPEN |
| SE-13 | gap | **medium** | 02 · colour roles, A · A-2-a/A-3, 11 · VTG-01…VTG-10 ↔ ADR-UI-011 | before T-012 lands tokens v2 (blocks T-010, T-013) | OPEN (ESC-002 answered: ADVISOR_REPLY-002, B + A; waits for owner values) |

Line numbers are those of the files at the date above; search the quoted text if a file has moved.

## Details

### SE-01 · GTX-03 sends smart-input acceptance to a copy catalog
- **Evidence:** `14-execution-order-and-gates.md:41`: gate GTX-03 lists «ورودی هوشمند طبق AIX». AIX-01…28 are copy strings (`08-assistant-ui.md`, table 8-4-الف), not behavior rules. The rule that opens the flow is QT-05 (`06:28`), the tests are AI-17 (`08:218`) and AMT-08 (`11:119`).
- **Proposed text:** replace «ورودی هوشمند طبق AIX» with «ورودی هوشمند (QT-05) طبق AI-17 و AMT-08».
- **Interim rule:** judge the smart-input clause by QT-05, AI-17 and AMT-08. In the v0.1 MVP profile the clause is reported as `NOT_IN_BUILD` (ADR-UI-009 §1), so nothing blocks GTX-03.

### SE-02 · AG-10 points to «the table before HI-01», which has no name
- **Evidence:** `13-agent-protocol.md:37` (AG-10): the level of each item is one of «سه سطح الگوی اطلاعات (جدول پیش از HI-01)». The three-level table starts at `06-quickadd-and-three-tier.md:277` and has no caption or number; HI-01 itself is at `06:283`.
- **Proposed text:** give the table the caption «جدول ۶-۷-الف: سه سطح اطلاعات» and change AG-10 to «(جدول ۶-۷-الف)».
- **Interim rule:** read «the table before HI-01» as the table at `06:277`.

### SE-03 · The copy-catalog intro lists families incompletely; SGX is outside by design but not said
- **Evidence:** `09-tone-and-copy.md:7` says texts given earlier under their own IDs are repeated in tables 9-4 «تا کاتالوگ کامل باشد» and lists «QX، STX، TOX، OSX، PHX، TGX، PKX، FBX، CCX و AIX». Table 9-4-ث does repeat DMX and HMX, which the list omits. SGX-01…09 (`10-style-guide-and-fixtures.md:16-28`) are not in the catalog; that is intended: SG-04 (`10:12`) exempts the Style Guide folder from the CM-10 check and MC-17 (`11:42`) lists that folder as an allowed place for Persian literals. TN-12 only requires rows for families of section 9.
- **Proposed text:** in `09:7` extend the list to «… CCX، AIX، DMX و HMX» and add «متن‌های صفحه‌ی Style Guide (SGX، جدول ۱۰-۱-الف) عمداً بیرون کاتالوگ‌اند، چون آن صفحه فقط در ساخت توسعه است (SG-04، MC-17)».
- **Interim rule:** treat SGX as outside the catalog; DMX and HMX are inside.

### SE-04 · The Home «compare with last month» line has no basis rule and no copy rows
- **Evidence:** `05-navigation-home-modules.md:139` (HM-04, widget `monthSpending`): «یک عدد اصلی و یک خط مقایسه («۱۲٪ کمتر از مهر»)». The fixture (`10:73`, table 10-2-پ) says the compared amount is «مقدار هم‌بازه‌ی مهر ۲٬۰۰۰٬۰۰۰ تومان», that is, the **same elapsed period** of the previous month (1 760 000 vs 2 000 000 gives 12 %). No rule states that basis, how the percentage is rounded, or when the line is hidden; `09-tone-and-copy.md` (HMX-01…07) has no row for the «کمتر / بیشتر» sentence with its two parameters. The Reports page (F08, «مقایسه با ماه قبل») needs the same rule.
- **Proposed text (rule, in HM-04 or as a new HM rule right after it):** «خط مقایسه، هزینه‌ی بازه‌ی گذشته‌ی ماه جاری را با همان تعداد روز از ابتدای ماه قبل می‌سنجد؛ ماه تمام‌شده با کل ماه قبل. درصد عدد صحیح است و از نیم به بالا گرد می‌شود. اگر ماه قبل هزینه نداشته یا درصد گردشده صفر است، خط نمایش داده نمی‌شود.»
- **Proposed text (copy rows):** `| HMX-NN | خط مقایسه‌ی «هزینه‌ی این ماه» (HM-04) | کمتر: «{n}٪ کمتر از {ماه}»؛ بیشتر: «{n}٪ بیشتر از {ماه}»؛ {n} با حالت ارقام کاربر (NM-01)، {ماه} نام ماه از لایه‌ی تاریخ |` with keys `hmx.NN.less` and `hmx.NN.more` (KN-01); the Product/Contracts hat picks the next free number.
- **Interim rule:** compute with `DATA_MODEL.md` **DD-11** (the project-level algorithm, which already contains the rounding and hiding rules). Until the HMX row exists, Builder-UI raises an AGX-01 request and uses the two strings above from the generated catalog; no Persian literal in the widget (CM-10).

### SE-05 · AGR-05 hands `app_fixtures` to Agent 5 «تأیید Agent 1» but no approval is recorded
- **Evidence:** `13-agent-protocol.md:24` (AGR-05): the package `app_fixtures` is «تقسیم تازه؛ تأیید Agent 1». `14-execution-order-and-gates.md:20` (EOX-01) already assumes Agent 5 builds it in wave 0. No document records Agent 1's answer (AG-16).
- **Proposed text:** once approved, replace the parenthetical with «(تأییدشده در AGX-NN)» or delete it.
- **Interim rule:** the Tester hat owns `app_fixtures`; Product/Contracts records «accepted» in the first fixtures task packet and in `docs/ops/AGENT_LOG.md`.

### SE-06 · `border-strong` is described as «کمینه ۳٫۳:۱» but only 3:1 is required
- **Evidence:** `02-tokens.md:29`: «(کمینه ۳٫۳:۱)». The check threshold is 3 (VTG-06, `11:70`; table A-4-a, `A-appendix-tokens.md:535`). Recomputed from `design_tokens.json`: light minimum 3.3095 (shown 3.31), dark minimum **3.2982** on `surface-raised` (shown 3.30). The tokens pass; only the sentence over-promises by 0.002.
- **Proposed text:** «(کمینه ۳:۱؛ VTG-06)».
- **Interim rule:** the threshold 3:1 governs; `tool/docs_check` (T2) and `ui_check` use the table numbers.

### SE-07 · QE-03 does not name its fixture (info)
- **Evidence:** `06-quickadd-and-three-tier.md:11` (QE-03) types «۱۲۵۰۰۰» but names no dataset; with `empty` the main button is disabled (SD-05, `06:101`). `10-style-guide-and-fixtures.md:33` (DS-02) already says a test that brings its own data (it names QE-03 and SD-05) runs over `normal`; UT-03 (`11:159`) names `normal` too.
- **Change needed:** none. Optional wording: add «روی داده‌ی `normal`» to QE-03.
- **Interim rule:** QE-03 runs over `normal`.

### SE-08 · Amount overflow: a message (NM-06) or silence (AM-01, TQ-13)?
- **Evidence:** `03-typography-rtl.md:73` (NM-06): beyond 18 digits «از آن بیشتر را فیلد نمی‌پذیرد و **پیام فارسی نشان می‌دهد**». `06-quickadd-and-three-tier.md:42` (AM-01): «رقم بعدی پذیرفته نمی‌شود». `06:337` (TQ-13): «رقم بعدی **بی‌صدا و بدون پیام** پذیرفته نمی‌شود». FD-03 (`7-03-fields.md:79`) also clips text silently. The copy catalog has no row for an overflow message.
- **Options:** (A) silent, as AM-01 and TQ-13 say: edit NM-06 to «از آن بیشتر را فیلد بی‌صدا نمی‌پذیرد (AM-01)». (B) keep a message: add a catalog row (`QX-NN`, e.g. «به بیشترین تعداد رقم رسیده‌اید.») shown as a polite live-region announcement, and change TQ-13. A silent field can confuse a screen-reader user who keeps typing; that is the only argument for B.
- **Interim rule:** A (it matches the written tests). Add the screen-reader case to the AMT list when the first TalkBack run happens; Product/Contracts decides between A and B then.

### SE-09 · The reference data cannot produce the «۱۲٪ کمتر از مهر» figure
- **Evidence:** `10-style-guide-and-fixtures.md:73` (table 10-2-پ) shows «۱۲٪ کمتر از مهر» from a same-period Mehr amount of 2 000 000 toman, but table 10-2-ب (`10:52-62`) has only Aban 1405 rows, and DS-03 (`10:34`) checks sums only for Aban. A real computation (DD-11) over the fixture finds no previous-month spending and hides the line, so the golden would differ from the spec.
- **Proposed data (new table «جدول ۱۰-۲-ب۲: تراکنش‌های مهر ۱۴۰۵ (`normal`)»):** `۱ مهر · خرید هفتگی سوپرمارکت · هزینه · غذا · بانک ملی · ۱٬۲۰۰٬۰۰۰`; `۲ مهر · قبض گاز · هزینه · قبوض · بانک ملی · ۸۰۰٬۰۰۰`; `۱۵ مهر · بنزین · هزینه · خودرو · نقدی · ۹۰۰٬۰۰۰` (outside the same-length period, so it proves the exclusion). The first two sum to 2 000 000. Opening balances are chosen so the displayed balances of table 10-2-الف stay unchanged (DD-06). DS-03 gains «مقدار هم‌بازه‌ی مهر برابر جمع ۱ و ۲ مهر است»; DS-07 «ترتیب و تعداد ردیف‌ها همان جدول‌هاست» then counts the new table.
- **Interim rule:** `app_fixtures` includes the three Mehr rows and a README line that says they extend table 10-2-ب; the Home golden «۱۲٪ کمتر از مهر» is then produced by the real use case.

### SE-10 · `PulseDotState.error` exists but the assistant never uses it (info)
- **Evidence:** `07-components/7-08-pulse-dot.md:8` and PD-05 (`7-08:57`) define `error`; AI-14 (`08-assistant-ui.md:175`) says the assistant does not use it because failures use `FieldMessage` with an error icon (PD-05).
- **Change needed:** none. The component keeps its own state-table tests (CM-13); v0.1 uses PulseDot only where the shell needs it, for example the temporary brand mark (Q-10).
- **Interim rule:** none.

### SE-11 · The assistant has one generic save error; QuickAdd has four reasons
- **Evidence:** `08-assistant-ui.md:195` (AIX-11) and `09-tone-and-copy.md:172`: «ذخیره نشد. دوباره تلاش کنید.» for `saveError`. QuickAdd (`06:260`, QX-16; `09:101`) distinguishes `unknown`, `storageFull`, `accountMissing`, `idempotencyConflict`. Confirming an assistant card can fail for the same reasons.
- **Proposed text:** «AIX-11 به ترتیب `reason` همان رشته‌های QX-16 را دارد (`unknown` همان متن فعلی است).»
- **Interim rule (v0.4):** reuse the QX-16 strings for the assistant's save errors.

### SE-12 · The day-ring empty text advertises a habit (and a budget) whatever modules exist
- **Evidence:** `01-identity.md:96` (VI-15) and `09-tone-and-copy.md:205` (HMX-01) fix one sentence: «برای دیدن وضعیت امروز، یک بودجه یا یک عادت اضافه کنید.» HM-01 (`05-navigation-home-modules.md:122`) makes the day-ring card fixed, and HM-02 (`05:123`) shows this `EmptyState` whenever no arc exists. Arcs belong to modules (DM-01, `05:151`, lists the DayRing arcs among the things that vanish with a disabled module), and v0.1 builds only `budget` (`MVP_SCOPE.md` U-6, ADR-UI-009 §4). So a first-run user who has no budget limit yet is told to add a habit, a feature that does not exist; and with the budget module switched off the sentence names a disabled module. DM-01 says a disabled module leaves no trace in the interface, but its list of places does not mention empty-state text.
- **Proposed text:** HMX-01 becomes a family of variants chosen by the enabled arc-providing modules: each module's descriptor supplies its own noun phrase as a catalog key (the budget one is «یک بودجه», the habit one «یک عادت», as in the current sentence) and the sentence lists only the enabled ones, joined with «یا». Add to HM-02: when no arc-providing module is enabled the card is not shown (DM-01); or, if Product/Contracts prefers to keep HM-01's «ثابت», a neutral sentence that names no module. Add empty-state text to the places DM-01 lists.
- **Interim rule:** v0.1 uses the budget-only variant «برای دیدن وضعیت امروز، یک بودجه اضافه کنید.» (the current sentence without «یا یک عادت») taken from the generated catalog: Builder-UI raises an AGX-01 request and puts no literal in the widget (CM-10). With the budget module off, the day-ring card is omitted (DM-01), so that no sentence names a disabled module.

### SE-13 · Themes v2 (ADR-UI-011) define 8 colour roles; the token contract needs 46 per theme
- **Evidence:** `design/brand/themes-v2.json` gives each of the four themes `bg`, `surface`, `surface2`, `ink`, `text2`, `line`, `accent`, `onaccent` (plus on-bg text, mascot, scene, activity). Table A-2-a (AXT-02/03, `A-appendix-tokens.md`) and the contrast groups VTG-01…VTG-10 (`11-testing-and-machine-checks.md`, 210 checks) require 46 roles in a light/dark pair, among them `success`, `warning`, `danger`, `info`, the module accents and their hover/pressed/subtle variants. The old palette is still written out in `02-tokens.md` (7 hex mentions of the v1 base colours) and `A-appendix-tokens.md` (12). Clay `accent` on Clay `surface` is 4.45:1 (VTG-02 needs 4.5 for `primary`), and Clay `ink`/`text2` on Clay `bg` are 3.12/1.41 (VTG-01 needs 4.5 on `background`); measured by `test/tool/themes_v2_contrast_test.dart` (T-012).
- **Options:** see ESC-002 (A: full role table from the owner/designer; B: derived roles by a written rule with owner review of status colours; C: shrink the role set and rewrite the VTG groups).
- **Chosen (ADVISOR_REPLY-002, 2026-11-01):** B for the mechanical roles (states, subtle tints, focus, disabled, inverse, scrim, shadows, border-strong) by the rule in `docs/agents/tasks/T-012.md` ("Derivation rule", code `lib/design/tokens/theme_derivation.dart`); A for `success`, `warning`, `danger`, `info` and the three module accents (owner approves; PROPOSED candidates in `design/brand/themes-v3-candidate.json`). C rejected.
- **Clay text variant:** new role `primary-text` (all themes) = `primary` or its nearest shade reaching 4.5:1 on every text surface; it replaces `primary` in VTG-02 and VTG-04. `primary` stays the fill/brand colour (VTG-03, VTG-07, VTG-08, VTG-10). Table A-2-a gets the row through AG-02 in the same PR that lands tokens v2 (Action 5), not before: the spec-sync test binds A-2-a to the v1.1 token file.
- **Clay background exception:** on Clay, `background` is not a text surface for any VTG group; VTG-01 on it is `on_bg_text` ≥ 4.5 and `on_bg_text2` ≥ 3 (large text only). Reason: ADR-UI-011 "Consequences"; no colour can reach 4.5:1 on both the mid-tone background and the cream surfaces. Clay therefore runs 87 VTG-01…09 pairs instead of 105. VT-03's fixed count (210 for two themes) is replaced by the per-theme counts in the candidate table when tokens v2 land (Action 5).
- **Interim rule:** `design/tokens/design_tokens.json` v1.1 stays the binding token file for code until the owner approves the owner values and T-012 lands tokens v2 (ADVISOR_REPLY-002 Actions 4–5); nothing in `lib/**` uses v2 values yet. Wherever ADR-UI-011 / `themes-v2.json` do define a value (brand, mascot, scene, activity, the 8 roles), ADR-UI-011 values win over the old palette text in `02-tokens.md` and appendix A for design work. On the Clay background only `on_bg_text` carries small text (ADR-UI-011 "Consequences"). Every v2 text pair is checked with the contrast guard (`lib/design/tokens/contrast_guard.dart`).

## Closing checklist (per erratum)
1. Request recorded (AGX-01) and answered (AG-16); 2. the spec text amended in a PR that names the erratum ID; 3. `docs_check --strict` and the self-test pass; 4. tokens untouched or their checksum regenerated through an ADR (AX-02); 5. this table row set to `CLOSED` with the PR link; 6. interim rule deleted.
