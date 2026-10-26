# CAPTURE_PIPELINE — From raw text to a confirmed transaction

**Status:** PROPOSED (UI part needs ADR-UI-010) · **Owner:** Agent 3 (MVP: SMS paste/share, parser, QuickAdd host); Agent 5 for later assistant sources (OCR/voice/text) · **Date:** 2026-10-26
**Depends on:** UI spec AI-01, AI-02, AI-10, QD/SD/IDP/UN (QuickAdd), NM-*, DT-*, CM-01, CM-10, AG-03; `DATA_MODEL.md`; `MVP_SCOPE.md` F09, U-1, U-2, S-05; `AI_TOOL_CONTRACT.md`.

## خلاصه‌ی فارسی (برای صاحب محصول)
- در MVP فقط **چسباندن متن پیامک** یا **Share از سیستم‌عامل** داریم. برنامه مجوز خواندن پیامک نمی‌گیرد (حریم خصوصی و سخت‌گیری فروشگاه‌ها).
- پارسر **قطعی و قاعده‌محور** است (بدون هوش مصنوعی): قالب هر بانک یک فایل قاعده است. متن خام پیامک هرگز ذخیره، لاگ یا پشتیبان‌گیری نمی‌شود؛ فقط هش آن برای تشخیص تکراری.
- خروجی فقط یک **پیش‌نویس** است که در همان QuickAdd با نشان «از پیامک» باز می‌شود. ذخیره فقط با ضربه‌ی صریح کاربر روی «ثبت». مبلغ یا نوع (واریز/برداشت) مشکوک هیچ‌وقت حدس زده نمی‌شود.
- معیار قبولی (S-05): روی مجموعه‌ی ساختگی ≥ ۹۵٪ فیلدها درست و **صفر** وارونگی واریز/برداشت.
- OCR رسید، صدا و متن آزاد همین پیش‌نویس و همین قواعد را بعداً استفاده می‌کنند.

## 1. Scope and principles
| ID | Principle |
|---|---|
| CAP-P1 | A capture never writes data. It produces a `CaptureDraft`; only the user's explicit "ثبت" in QuickAdd saves (AI-01 applies to every automated source). |
| CAP-P2 | Deterministic first. MVP parsing is rule-based and reproducible; no model is called. Models (later) only propose through the same draft type. |
| CAP-P3 | Privacy by construction: raw text lives in memory for the parse only. Never logged, stored, exported, sent to any network or put in crash reports (I-12). |
| CAP-P4 | Wrong is worse than empty. A critical field (amount, direction) with doubt stays empty/asked, never guessed. Zero tolerance for direction inversion. |
| CAP-P5 | Same output type for every source (SMS, receipt OCR, voice, free text) so QuickAdd and the contract tests are reused. |
| CAP-P6 | The UI never parses (CM-01). It calls an application use case and receives a prefill token and view models. |

Sources: `smsPaste`, `smsShare` (MVP); `receiptImage`, `voice`, `freeText` (assistant module, later).

## 2. Pipeline
```
RawCapture(text, source, receivedAt)
  → 1 Normalize → 2 Segment → 3 Classify → 4 Extract → 5 Map → 6 Score → 7 Dedupe → CaptureDraft
```
| Stage | Behavior |
|---|---|
| 1 Normalize | Cap at 4 000 chars (more ⇒ reject). Unicode NFC; map Arabic ي/ك to ی/ک; Persian/Arabic digits to ASCII for matching; remove ZWNJ/ZWJ, bidi marks (LRM/RLM/LRE/RLE/PDF/LRI/RLI/PDI), tatweel; collapse whitespace; unify thousand separators (`,` `٬` `،` `.` when grouped) and decimal separators (`٫`). The original text is kept only for stage 7 hashing. Uses the same `normalizeForSearch` building blocks (spec 3-8) but is a separate function `normalizeForCapture`. |
| 2 Segment | Split a paste into candidate messages (blank-line or sender-line separators). MVP takes the **first financial message** and tells the user how many were found (CPX-06). A queue UI is v0.2 (CAP-Q1). |
| 3 Classify | `financial` / `not_financial` / `unknown_format`. OTP, login codes, promos, balance-only notices, failed/declined transactions ("ناموفق", "عدم موفقیت") and links-only messages are `not_financial` — they must never produce a draft. Classification uses the rule packs' keyword sets plus a generic fallback. |
| 4 Extract | Named fields: `amount`, `unit` (rial/toman/unspecified), `direction` (debit/credit), `date`, `time`, `balanceAfter`, `counterparty` (merchant/payer), `accountHint` (bank id + last digits), `reference`. Rule-pack patterns win; the generic extractor is only used to fill an `unknown_format` hint, never to set direction. |
| 5 Map | `direction → kind` (debit→expense, credit→income). Account: match `accountHint` to `account_hints` (DATA_MODEL §5a); none ⇒ leave to QuickAdd defaults (SD-01). Category: `capture_merchant_map` (learned from the user's confirmed choices) else leave to defaults. Date: Jalali dates in text → Gregorian through the central date layer; invalid/impossible ⇒ `unsure`. Transfers are **never** inferred (CAP-P4): a debit and a matching credit are two separate drafts; the user may switch the type to transfer in QuickAdd. |
| 6 Score | Per field `sure | unsure | missing` — the same three values as AI-10 (§4 below). |
| 7 Dedupe | `externalRef = sha256(normalizedText)` plus a soft duplicate hint (§7). |

```dart
// Illustrative contract (application layer, no Flutter imports).
enum CaptureSource { smsPaste, smsShare, receiptImage, voice, freeText }
enum FieldConfidence { sure, unsure, missing }

final class CaptureField<T> { final T? value; final FieldConfidence confidence; final String? reasonCode; }

final class CaptureDraft {
  final CaptureSource source;
  final CaptureField<TransactionKind> kind;      // expense | income only
  final CaptureField<Money> amount;              // BigInt minor + currency; never double
  final CaptureField<LocalDate> occurredOn;
  final CaptureField<String> note;               // counterparty text, trimmed to 200 (NT-01)
  final CaptureField<AccountId> account;
  final CaptureField<CategoryId> category;
  final String externalRef;                      // sha256 hex; never the text
  final DuplicateHint? duplicate;
}

abstract interface class CaptureFromText {       // use case
  Future<CaptureResult> call(String raw, CaptureSource source);   // sync-safe, <= 50 ms for 1 KB
}
sealed class CaptureResult { }                   // Parsed(prefillToken, summaryVM) | NotFinancial | UnknownFormat(hintVM) | TooLong
```
- `prefillToken` is an opaque id held in memory by the application layer. QuickAdd opens with `QuickAddPrefill(token)`. On "ثبت", `SaveQuickAdd` looks up the token and attaches `origin='sms'` and `externalRef` itself (AI-02: the UI only sends the confirmation). Tokens expire when the window closes or after 30 minutes.

## 3. Rule packs
- Location: `assets/capture/rules/<bank_id>.json` (bundled; **no remote download in v0.x**, supply-chain risk). Written by us from synthetic and anonymized samples; no copied third-party rule sets (license rule in `AGENTS.md`).
- Each pack: `bank_id`, `version`, `senders` (display hints only), `classify` (keyword sets), `templates[]` each with `id`, a linear-time pattern with named groups, `direction`, `unit` (default or detect), `fieldMap`, `fixtures[]` (synthetic samples with expected output).
- Safety: patterns are linted for ReDoS (no nested quantifiers, bounded repeats, input cap 4 000, test with a 200 KB adversarial string within a time budget). A pack with a failing fixture fails CI.
- Sign and wording seeds (to be validated against the owner's anonymized corpus, Q-06; do not trust from memory): amount lines with a trailing `-`/`+`, words such as برداشت، خرید، پرداخت، انتقال (debit side), واریز، دریافت، سپرده (credit side), «مانده/موجودی» = balance-after (never the amount).
- Unit rule: bank SMS amounts are assumed **rial** only if the template says so; when a template is unit-ambiguous, `unit = unspecified` ⇒ amount is `unsure` (§4). Toman text is converted ×10 to rial minor units.
- First banks: 3–5 chosen by the owner (Q-06). Each bank is a separate task (T-xxx) with its own fixtures and review.

## 4. Confidence and what the UI may prefill
| Field | `sure` when | `unsure` when | `missing` when |
|---|---|---|---|
| amount | exactly one amount tagged by the template; unit known; ≤ 18 digits | unit unspecified; more than one candidate with the same tag | none found, or > 18 digits |
| kind | the template fixes direction | — (never `unsure`) | conflicting or absent direction signals |
| occurredOn | parsed and valid | partial (e.g. two-digit year, no year) | none (defaults to today per SD-06) |
| account | `accountHint` matches exactly one active account | matches several | no hint/match |
| category | merchant in `capture_merchant_map` | — | no match |

Prefill rules (MVP, until ADR-UI-010 decides on visual markers):
- **CAP-C1:** `sure` ⇒ prefilled.
- **CAP-C2:** `missing` ⇒ left empty; QuickAdd's normal required-field behavior applies.
- **CAP-C3:** `unsure` for `amount` or `kind` ⇒ treated as `missing` (the user types it; we show what we saw in the hint line CPX-04). `unsure` for date/account/category ⇒ prefilled with the QuickAdd default or best match, no marker.
- **CAP-C4:** the provenance row "از پیامک" (U-2) is always visible when the window was opened from a capture.
- **CAP-C5:** nothing is saved before the user taps "ثبت". Closing with changes follows DR-01.

## 5. UI (new; spec has none — requires ADR-UI-010)
Uses only existing components (AG-03). New component needs go through AGX-01 to Agent 1.
1. **Entry (U-1):** an `IconButton` in the QuickAdd header, label «چسباندن پیامک», visible for `expense` and `income` only, placed next to (not instead of) the existing header actions. With the `assistant` module off nothing else changes (DM-01).
2. **PasteSmsSheet:** a `BottomSheet` (Compact/Medium) or `Dialog` (Expanded/Large) per QT-04 sizing; title «پیامک بانک»; a multiline text field (max 4 000); primary button «خواندن پیامک» (disabled while empty); secondary «چسباندن» which reads the clipboard **only on tap**. Field and clipboard copy are cleared when the sheet closes.
3. **Success:** the sheet closes with the standard motion (MO-11 patterns) and QuickAdd shows the draft with the provenance row (U-2). Focus goes to the amount field, **not** to "ثبت" (AI-01 spirit: no auto-confirm, no initial focus on confirm).
4. **Failure states** (inline `FieldMessage`, no ErrorState because it is user input, cf. AI-12): `NotFinancial` (CPX-02), `UnknownFormat` (CPX-03 + optional amount hint CPX-04), `TooLong` (CPX-05).
5. **Share (Android):** `ACTION_SEND text/plain` opens the app on QuickAdd directly when parsing succeeds; otherwise opens PasteSmsSheet with the text filled and the failure message shown. Desktop: paste only (Ctrl/⌘+V into the field).
6. **Transaction detail (U-2):** a small «از پیامک» row; the original text is **not** shown (it is not stored).
7. Accessibility: field and buttons have semantic labels; result announcements via live region; never color-only (CM-11); touch targets per spec.

Proposed copy (to be inserted in spec §9 as `CPX-*` by Agent 1; Persian per tone rules):
| ID | Where | Text |
|---|---|---|
| CPX-01 | header icon label | «چسباندن پیامک» |
| CPX-02 | not financial | «این پیامک تراکنش مالی به نظر نمی‌رسد.» |
| CPX-03 | unknown format | «قالب این پیامک را نمی‌شناسم. می‌توانید تراکنش را دستی ثبت کنید.» |
| CPX-04 | hint line | «در پیامک دیده شد: {مبلغ}. لطفاً بررسی کنید.» |
| CPX-05 | too long | «متن خیلی طولانی است. فقط خود پیامک بانک را بچسبانید.» |
| CPX-06 | several messages | «{n} پیامک پیدا شد؛ اولی خوانده شد.» |
| CPX-07 | duplicate hint | «شبیه تراکنشی است که قبلاً ثبت کرده‌اید.» |
| CPX-08 | provenance row | «از پیامک» |
| CPX-09 | sheet title | «پیامک بانک» |
| CPX-10 | primary button | «خواندن پیامک» |

## 6. Privacy and platform
- MVP requests **no SMS permission** and no notification-listener access. Reading SMS/notifications automatically is a later, separate decision (ADR + store-policy check; Google restricts SMS permissions, iOS has no equivalent; verify).
- Clipboard is read only on an explicit tap; no background clipboard access.
- Logs/crash reports contain only: result type, rule id, version, timing; never text, amounts or counterparties.
- Rule packs are public in the repo and contain only synthetic examples. Real SMS samples stay outside git (owner's private folder); fixtures derived from them must be anonymized and manually reviewed before commit.
- Backups contain `origin` and `external_ref` (hash) only.

## 7. Duplicate handling
- **Hard:** the same `externalRef` already linked to a non-deleted transaction ⇒ `DuplicateHint(hard)`: QuickAdd opens with the draft and a non-blocking line CPX-07; the user decides (the same bank sends the same text twice legitimately only if the text differs, e.g. by time).
- **Soft:** same account (if known), amount and date ±1 day, kind ⇒ `DuplicateHint(soft)`, same line.
- Idempotency of the save itself is separate (`clientRequestId`, IDP-01…05).

## 8. Test strategy and metrics (feeds S-05)
- **Corpus:** synthetic generator + hand-written fixtures per template: digit variants (Persian/Arabic/Latin), RTL marks, line breaks, rial/toman, 1–18 digit amounts, balance vs amount confusion, two amounts, missing amounts, OTP, promos, failed transactions, duplicates, 200 KB adversarial input.
- **Gates (CI):** every template fixture exact; for supported templates ≥ 95 % of fields exact across the corpus; **0** `kind` inversions (any inversion fails the build); 100 % of OTP/promo/failed fixtures classified `not_financial`; parse ≤ 50 ms for 1 KB on the reference device (Q-09); ReDoS test passes.
- **Application tests:** token expiry; save attaches origin and externalRef; no save without confirm (spy on repository); log scrubber test (no digits-with-currency patterns from fixtures appear in captured logs); idempotent double tap.
- **Widget/golden (MVP profile):** PasteSmsSheet in Compact/Expanded, light/dark, RTL; success/failure states.
- **Ownership (AGR-03/05):** rules, parser, draft→`SaveQuickAdd` glue and the PasteSmsSheet inside QuickAdd (finance forms) Agent 3 after ADR-UI-010; fixtures, matrix and integration tests Agent 5; Android share-intent glue Builder-Platform; component requests to Agent 1 (AGX-02).

## 9. Extension to other sources (reservation)
- `receiptImage`: OCR engine chosen by benchmark (OPEN_SOURCE_AUDIT) on-device first; produces the same `CaptureDraft`; amounts from OCR are always `unsure` unless a total line is unambiguous; image is never persisted unless the user attaches it to a record (separate decision).
- `voice`/`freeText`: speech-to-text/LLM extract via `propose_transaction` tool (AI_TOOL_CONTRACT); output flows into AIActionCard (assistant module) and `SaveQuickAdd`; same confidence semantics.
- Cloud processing of any capture requires explicit per-use consent and is not planned (local H200/phone-local models only).

## 10. Open questions
CAP-Q1: multi-message queue UI (v0.2). CAP-Q2: Q-06 — which 3–5 banks and the anonymized corpus. CAP-Q3: confirm the unit assumption (rial) per bank from real samples. CAP-Q4: should `unsure` amount show an inline marker (ADR-UI-010) instead of being left empty? CAP-Q5: learned `capture_merchant_map` — keep per-device only (default) and include in backup (default yes).
