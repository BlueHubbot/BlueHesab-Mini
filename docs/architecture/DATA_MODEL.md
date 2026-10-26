# DATA_MODEL — Financial data contract (MVP v0.1)

**Status:** PROPOSED (to be accepted with ADR-0003 after the spike) · **Owner:** Lead architect (domain: Agent 3) · **Date:** 2026-10-26
**Depends on:** `MVP_SCOPE.md`, UI spec rules MN-01…MN-06, DT-01…DT-05, NM-*, SD-*, IDP-*, UN-01, DS-*.

## خلاصه‌ی فارسی (برای صاحب محصول)
- پول همیشه «عدد صحیح واحد کوچک + کد ارز» است (ریال برای IRR) و در پایگاه‌داده **متن ده‌دهی** ذخیره می‌شود؛ هیچ `double` و هیچ جمع‌زدن در SQL نیست، همه‌ی محاسبه‌ها در لایه‌ی دامنه با `BigInt`.
- انتقال یک رکورد است (مبدأ و مقصد) و هرگز درآمد یا هزینه حساب نمی‌شود.
- تاریخ تراکنش میلادی `yyyy-MM-dd` ذخیره می‌شود؛ شمسی فقط نمایش است. لحظه‌ها UTC.
- حذف و واگرد با «حذف نرم» انجام می‌شود؛ ثبت بدون تکرار با جدول idempotency.
- ماژول‌ها جدول خودشان را با پیشوند `m_<module>_` و مهاجرت خودشان دارند؛ خاموش‌شدن ماژول هیچ داده‌ای را حذف نمی‌کند.
- سقف مبلغ ۱۸ رقم (AM-01). پشتیبان‌گیری مبلغ‌ها را به‌صورت رشته می‌نویسد.

## 1. Principles
1. Local-first. The local database is authoritative until a sync design is accepted (ADR-0005/0006).
2. Normalized storage; locale, calendar, numerals and display unit are presentation only and never mutate stored values (FIN-003).
3. The database stores; the domain layer calculates. No arithmetic on money in SQL.
4. Stable client-generated IDs, versioned forward-only migrations, soft deletes: all chosen so future sync is possible without a rewrite.
5. The UI never touches this layer directly (CM-01); it receives view models.

## 2. Identifiers
- Record IDs: UUIDv7 as lowercase hyphenated `TEXT` (time-ordered, generated on the client). Tie-breaks for "registration order" use `created_at` then `id`.
- `clientRequestId`: UUIDv4 created per QuickAdd window (IDP-01); stored in `idempotency`.
- Never expose row ids or numeric auto-increment keys.

## 3. Money
```dart
// Illustrative; the invariants are the contract.
final class Money {
  final BigInt minor;          // minor units of [currency]; |minor| <= 10^18 - 1 (AM-01, NM-06)
  final CurrencyCode currency; // ISO-like code, e.g. IRR
}
```
- **DD-01:** The minor unit is the rial for IRR (0 decimals) and 1/100 for USD, EUR, GBP, AED, TRY. A currency table fixes `minor_digits`. Toman is a display unit: `IRR / 10`; a rial amount not divisible by 10 shows one decimal in toman (MN-02).
- **DD-02 (storage):** amounts are stored as canonical decimal integer `TEXT` (no `+`, no leading zeros, `-` only for opening balances). A `CHECK` constraint enforces the pattern and length ≤ 18 digits. JSON, backups and DTOs carry money as strings, never as JSON numbers.
- **DD-03 (arithmetic):** all sums, balances, budget math and report totals use `BigInt` in the domain. Sorting or filtering by amount happens in memory. Rounding is only for compact display (MN-04) and is integer half-up.
- **DD-04 (currencies):** a transaction's currency equals the currency of its account(s). v0.1 has no conversion; transfers are same-currency only (SD-03); totals are per currency and never summed across currencies (SC-05, MN-06, IN-7). Cross-currency transfers and conversion (rate + time + source, MN-06, SD-03) are out of v0.1.
- **DD-05 (web):** `BigInt` is exact on every Dart target including web; any transport that turns money into a JSON number or JS `Number` is a defect (RKX-01).
- **Decision record:** TEXT vs INTEGER. `INTEGER` (64-bit) fits 18 digits but SQL `SUM` can overflow and web SQLite handles big integers differently. TEXT plus domain arithmetic is portable and safe at personal scale. **Revisit trigger:** list/report time exceeds the frame or response budget with ≥ 20k transactions; then add a transactionally maintained balance cache (verified by a recompute command), not SQL sums.

## 4. Time and calendar
- **DT-A:** instants (`created_at`, `updated_at`, `deleted_at`) are ISO-8601 UTC strings with milliseconds, e.g. `2026-10-24T06:55:00.000Z` (DT-01).
- **DT-B:** transaction date `occurred_on` is a date-only `TEXT` `yyyy-MM-dd` (Gregorian reference). No Jalali string is ever stored.
- **DT-C:** "today" is computed in the user's IANA time zone (setting `app.timezone`, default device zone) at the moment QuickAdd opens and is frozen for that window (SD-06). DST/zone rules come from the tz database, never hand-written (DT-02).
- **DT-D:** all Jalali/Gregorian conversion, month length and month arithmetic happens in one central date layer (DT-05, ADR-UI-004); the schema contains no calendar math.

## 5. Entities (MVP)

```sql
-- Illustrative DDL. Names, constraints and invariants are the contract.
PRAGMA foreign_keys = ON;

CREATE TABLE currencies (
  code TEXT PRIMARY KEY,                 -- 'IRR','USD','EUR','GBP','AED','TRY'
  minor_digits INTEGER NOT NULL CHECK (minor_digits BETWEEN 0 AND 4)
);

CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,                   -- JSON-encoded scalar/array
  updated_at TEXT NOT NULL
);

CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_norm TEXT NOT NULL,               -- normalizeForSearch(name) (UI spec 3-8)
  kind TEXT NOT NULL CHECK (kind IN ('cash','bank')),
  currency TEXT NOT NULL REFERENCES currencies(code),
  opening_balance_minor TEXT NOT NULL DEFAULT '0'
    CHECK (opening_balance_minor = '0'
        OR (opening_balance_minor GLOB '[1-9]*' AND opening_balance_minor NOT GLOB '*[^0-9]*' AND length(opening_balance_minor) <= 18)
        OR (opening_balance_minor GLOB '-[1-9]*' AND substr(opening_balance_minor, 2) NOT GLOB '*[^0-9]*' AND length(opening_balance_minor) <= 19)),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  deleted_at TEXT
);
CREATE UNIQUE INDEX ux_accounts_active_name
  ON accounts(name_norm) WHERE archived_at IS NULL AND deleted_at IS NULL;   -- QX-21

CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('expense','income')),
  name TEXT NOT NULL,
  name_norm TEXT NOT NULL,
  system_key TEXT,                       -- stable identity for seeded categories, else NULL
  icon_id TEXT NOT NULL,                 -- logical id (ADR-UI-005)
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
);
CREATE UNIQUE INDEX ux_categories_active
  ON categories(kind, name_norm) WHERE archived_at IS NULL;

CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('expense','income','transfer')),
  amount_minor TEXT NOT NULL
    CHECK (amount_minor GLOB '[1-9]*' AND amount_minor NOT GLOB '*[^0-9]*' AND length(amount_minor) <= 18),
  currency TEXT NOT NULL REFERENCES currencies(code),
  account_id TEXT NOT NULL REFERENCES accounts(id),       -- source for transfer
  to_account_id TEXT REFERENCES accounts(id),             -- transfer only
  category_id TEXT REFERENCES categories(id),             -- not for transfer; NULL = uncategorized
  occurred_on TEXT NOT NULL,                              -- yyyy-MM-dd
  note TEXT,                                              -- trimmed, <= 200 chars (NT-01)
  note_norm TEXT,
  origin TEXT NOT NULL DEFAULT 'manual' CHECK (origin IN ('manual','sms','import','assistant')),
  external_ref TEXT,                                      -- e.g. sha256 of a parsed SMS (dedupe hint)
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  CHECK ((kind = 'transfer') = (to_account_id IS NOT NULL)),
  CHECK (kind <> 'transfer' OR category_id IS NULL),
  CHECK (to_account_id IS NULL OR to_account_id <> account_id)
);
CREATE INDEX ix_tx_date ON transactions(occurred_on) WHERE deleted_at IS NULL;
CREATE INDEX ix_tx_account_date ON transactions(account_id, occurred_on) WHERE deleted_at IS NULL;
CREATE INDEX ix_tx_category_date ON transactions(category_id, occurred_on) WHERE deleted_at IS NULL;
CREATE INDEX ix_tx_external_ref ON transactions(external_ref) WHERE external_ref IS NOT NULL;

CREATE TABLE idempotency (
  client_request_id TEXT PRIMARY KEY,
  record_kind TEXT NOT NULL,             -- 'transaction' (later: 'task', ...)
  record_id TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- Module `budget` (optional, default ON). Budget limits are versioned instead of overwritten.
CREATE TABLE m_budget_limits (
  id TEXT PRIMARY KEY,
  scope TEXT NOT NULL CHECK (scope IN ('overall','category')),
  category_id TEXT REFERENCES categories(id),
  currency TEXT NOT NULL REFERENCES currencies(code),
  limit_minor TEXT NOT NULL CHECK (limit_minor GLOB '[1-9]*' AND limit_minor NOT GLOB '*[^0-9]*' AND length(limit_minor) <= 18),
  calendar TEXT NOT NULL CHECK (calendar IN ('jalali','gregorian')),   -- month boundaries, fixed at creation
  valid_from TEXT NOT NULL,              -- yyyy-MM-dd, first day of the first period it applies to
  superseded_at TEXT,
  created_at TEXT NOT NULL,
  CHECK ((scope = 'category') = (category_id IS NOT NULL))
);
```
- The SQL of this section and of 5a is executed on a real SQLite by `tool/docs_check/check_data_model_ddl.py` (part of CI), which checks the constraints above. It guards this document; it is not the production migration (ADR-0003).

### 5a. Capture helpers (used by `CAPTURE_PIPELINE.md`)
```sql
-- Optional matching hints so a parsed SMS can suggest an account. Never holds full card numbers.
CREATE TABLE account_hints (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id),
  bank_id TEXT,                          -- rule-pack id, optional
  last_digits TEXT CHECK (last_digits IS NULL OR (length(last_digits) BETWEEN 2 AND 4 AND last_digits NOT GLOB '*[^0-9]*')),
  created_at TEXT NOT NULL
);
CREATE INDEX ix_account_hints_account ON account_hints(account_id);

-- Learned from the user's confirmed choices only; per device; included in backup.
CREATE TABLE capture_merchant_map (
  merchant_norm TEXT PRIMARY KEY,        -- normalizeForCapture(counterparty), <= 80 chars
  category_id TEXT NOT NULL REFERENCES categories(id),
  uses INTEGER NOT NULL DEFAULT 1,
  updated_at TEXT NOT NULL
);
```
- Hints store at most the last four digits. `capture_merchant_map` never stores message text, only the normalized counterparty label the user already saw and confirmed.

- **DD-06 (balance):** `balance(account) = opening + Σ income − Σ expense + Σ incoming transfers − Σ outgoing transfers` over non-deleted transactions of that account, in `BigInt`. Archived accounts keep their history and appear in reports; they are never suggested as defaults (SD-01). Future-dated transactions are included in v0.1 (open question DQ-1, owner Agent 3).
- **DD-07 (transfers):** one row, never two. Excluded from income, expense and net everywhere (FIN-002). Source and destination differ and share the currency.
- **DD-08 (deletion):** `deleted_at` soft delete for transactions (user delete and `UndoQuickAdd`). Deleted rows are excluded from every query, list, report and export, and purged by maintenance after 30 days (proposed). An account with any non-deleted transaction can only be archived; hard removal only when it never had transactions. Categories are archived, never deleted; transactions keep their `category_id`.
- **DD-09 (budget periods):** a period is one calendar month in the budget's `calendar`. The effective limit for a period is the row with the latest `valid_from ≤ period_start` that is not superseded before it. Spent amount = Σ expense (not transfers) of the category/overall in that period and currency, computed in the domain. Past months keep their original limits.
- **DD-10 (search):** `note_norm` and `name_norm` hold `normalizeForSearch` output (UI spec 3-8). Stored user text is never rewritten by normalization.
- **DD-11 (month comparison):** the Home `monthSpending` comparison line and the Reports "compare with previous month" row use the **same elapsed period** when the month is the current one: current = first day of the month … today; previous = the same number of days counted from the first day of the previous month (clamped to that month's last day), both in the user's report calendar (DD-09). A completed month is compared with the full previous month. Both sums are expenses only (transfers excluded, DD-07), in one currency (SC-05), computed in the domain with `BigInt`. The percentage is an integer: `sign × (2·|Δ|·100 + previous) ÷ (2·previous)` with integer division (round half up on the magnitude, no `double`). The comparison is shown only when `previous > 0` and the rounded percentage is not 0; otherwise the line is omitted. The UI spec's fixture already means this (DS-03, table 10-2-پ: «مقدار هم‌بازه‌ی مهر»); vector: 1 760 000 vs 2 000 000 toman → 12 % less. Two spec gaps remain until Product/Contracts closes them (`docs/design/SPEC_ERRATA.md`): the wording rows are missing from the copy catalog (SE-04), and the reference fixtures contain no Mehr rows, so the figure «۱۲٪ کمتر از مهر» cannot be computed from them (SE-09).

## 6. Settings keys (typed, validated in the domain)
`ui.theme` (light|dark|system), `ui.digitMode` (auto|persian|latin), `ui.displayUnit` (rial|toman), `ui.calendar` (jalali|gregorian), `ui.weekStart` (sat|sun|mon), `ui.homeLayout` (HM-05), `nav.pins` (BN-02), `modules.enabled` (array of module ids, MODULE_CONTRACT), `app.defaultCurrency` (default IRR), `app.timezone` (IANA), `app.firstRunDone`, `app.schemaVersion` (informational). Unknown keys are ignored, never deleted.

## 7. Seeds
- Currencies: IRR(0), USD(2), EUR(2), GBP(2), AED(2), TRY(2).
- Categories seeded **once at first run from the copy catalog** (so names are user data afterward): expense: غذا، حمل‌ونقل، قبوض، خودرو، خانه و اجاره، سلامت، آموزش، تفریح، خرید و پوشاک، سایر؛ income: حقوق، درآمد جانبی، هدیه، سایر. Each gets a `system_key`. (Fixtures use غذا، حمل‌ونقل، قبوض، خودرو، حقوق.)
- No default account is created (SD-05); the user creates accounts explicitly.

## 8. Idempotency and undo
- `SaveQuickAdd(draft, clientRequestId)` runs in one DB transaction: look up `idempotency`; if found return the stored record with `wasDuplicate = true`; otherwise insert the record and the idempotency row together. Returns only after commit (IDP-01…05).
- `UndoQuickAdd(recordId)` soft-deletes; calling it again has no further effect (UN-01). A replay of the same `clientRequestId` after an undo returns `wasDuplicate = true` and does **not** recreate the record.
- A save never half-succeeds: record and idempotency row commit atomically.

## 9. Migrations
- **MG-01:** `PRAGMA user_version` is the monotonic schema version; `schema_migrations(version, applied_at, checksum)` records history. Migrations are forward-only and run inside one transaction.
- **MG-02:** before applying migrations the app copies the database file to a recovery file (keep the last 3). If migration fails: roll back, keep the old database, show a recoverable error.
- **MG-03:** if `user_version` is higher than the app supports, the app refuses to open the data and says so; downgrade is never assumed safe (RELEASE).
- **MG-04:** every migration has a test that upgrades from the previous schema fixture and from an empty database to the same final schema.
- **MG-05 (modules):** a module owns tables prefixed `m_<moduleId>_`, declares its own migration list and `module_schema(module_id, version)` row; the core never reads module tables. Disabling a module changes only `modules.enabled` (DM-03 in the UI spec); no data is deleted. "Delete module data" is an explicit destructive action owned by that module.

## 10. Export / backup data contract
The file format is specified in `docs/BACKUP_RESTORE.md` (H6). This model fixes the content rules:
- JSON, UTF-8; top-level `format` = `bluehesab-backup`, `format_version`, `schema_version`, `exported_at`, `app_version`, entity arrays (`accounts`, `account_hints`, `categories`, `capture_merchant_map`, `transactions`, `budget_limits`, `settings`), and `checksum` (sha256 of the canonical body without the checksum field).
- All money fields are decimal strings. Soft-deleted rows and idempotency rows are excluded.
- Restore validates structure, counts, checksum, referential integrity and `schema_version` before touching the database; it creates a recovery point first; malformed files are rejected without changes (CORE-004).
- Encryption of the file and the database at rest is open (ADR-0003, Q open); the model does not depend on it.

## 11. Invariants (tests required, owner Agent 3, runner Agent 5)
| ID | Invariant |
|---|---|
| I-01 | No `double`/`num` on any money path; amounts never exceed 18 digits; the 18-digit maximum survives write → read → format → export → import on every target (DS-07, ADRX-07). |
| I-02 | Changing locale, calendar, digits or display unit changes no stored value. |
| I-03 | Transfers never appear in income, expense or net; moving money between own accounts leaves total balance of that currency unchanged. |
| I-04 | Transaction currency equals its account currency; transfer accounts share currency and differ. |
| I-05 | Same `clientRequestId` ⇒ at most one record, including across process restarts and after undo. |
| I-06 | Undo and user delete never remove rows physically before purge; deleted rows are invisible everywhere. |
| I-07 | Account balance equals opening plus the sum of effects; recomputing from scratch always matches any cache. |
| I-08 | Month totals use the budget/report calendar boundaries exactly (DT-05 vectors). |
| I-09 | Backup export then restore on a clean install yields identical logical data (hash of canonical JSON equal). |
| I-10 | Restoring a corrupt or newer-version backup changes nothing and reports why. |
| I-11 | Module off/on leaves all data intact; the core works with every module off (MMX-01). |
| I-12 | Raw SMS text, receipt images and voice are never stored, logged or exported (attachments a user may add later are a separate decision, BR-3); logs hold no financial data; `external_ref` holds a hash only. |

## 12. Open questions
DQ-1: do future-dated transactions count in the current balance? (default: yes). DQ-2: purge window for deleted rows (default 30 days). DQ-3: keep per-budget `calendar` fixed at creation or follow the display calendar (default: fixed). DQ-4: encryption at rest (ADR-0003). DQ-5: minimum SQLite version and binding (spike). Record decisions in `AGENT_LOG.md` and, when architectural, in an ADR.
