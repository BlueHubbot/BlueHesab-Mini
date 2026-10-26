# Glossary (v2, bilingual)

Persian terms are the ones the product uses (copy catalog, section 9 of the spec); the English column is what code, ADRs and commits use.

## Product and money
| English | فارسی | Meaning |
|---|---|---|
| Local-first | محلی‌محور | Core workflows use data on the device and need no server. |
| Offline | آفلاین | No network; v0.1 never needs one. |
| Minor unit | کوچک‌ترین واحد | Smallest unit of a currency: rial for IRR (0 decimals), 1/100 for USD, EUR, GBP, AED, TRY (DD-01). |
| `BigInt` money | مبلغ صحیح بزرگ | Amount as an arbitrary-size integer of minor units plus a currency code; stored as decimal TEXT; never `double` (DD-02, I-01). |
| Toman / rial | تومان / ریال | Display units; 1 toman = 10 rial. The stored value is always rial (MN-02). |
| Jalali (Shamsi) calendar | تقویم شمسی | Default display calendar; dates are stored as `yyyy-MM-dd`, instants as UTC. |
| QuickAdd | ثبت سریع | The always-available record window (expense, income, transfer in v0.1). |
| DayRing | حلقه‌ی روز | Home's ring of progress arcs (budget arc in v0.1). |
| Draft (CaptureDraft) | پیش‌نویس | Fields proposed by SMS/OCR/AI; becomes a record only after the user confirms (CAPT-001). |
| Idempotency key (`clientRequestId`) | شناسه‌ی یکتای ثبت | Makes a repeated save produce one record (I-05). |
| Soft delete / undo | حذف نرم / واگرد | `deleted_at` marks a record; undo reverses it (DD-08). |
| Tombstone | نشانه‌ی حذف | Retained deletion marker; needed only for a future sync. |
| Backup file | فایل پشتیبان | `.bluehesab` JSON export; unencrypted in v0.1 (BACKUP_RESTORE). |

## Architecture
| English | فارسی | Meaning |
|---|---|---|
| Module / ModuleRegistry | ماژول | Independently enabled feature declared by a descriptor; leaves no trace when off or not built (DM-01, MODULE_CONTRACT). |
| Adapter / Port | درگاه / آداپتر | Interface that hides a platform or provider implementation. |
| ADR | سند تصمیم معماری | Architecture Decision Record; `ADR-NNNN` product/architecture, `ADR-UI-NNN` UI. |
| Design token | توکن طراحی | Named visual value from `design/tokens/design_tokens.json`. |
| Golden test | آزمون تصویر مرجع | Visual regression comparison on the fixed Linux CI image. |
| Capability matrix | ماتریس توانایی | What each platform has been shown to do, with evidence (PLATFORM_MATRIX). |
| Source of truth | مرجع نهایی | Authoritative document for a topic; see the order in `AGENTS.md`. |
| Spike | آزمون فنی | Time-boxed experiment that decides a technology (SPIKE_PLAN). |

## Process and agents
| English | فارسی | Meaning |
|---|---|---|
| UI constitution | قانون اساسی رابط | The UI spec in `docs/design/ui-spec/` (about 930 rules). |
| Gate (GTX-01…06) | دروازه | Checkpoint a milestone must pass; some are decided by the owner (D3). |
| MVP profile | پروفایل MVP | Declared, reported lighter gates for v0.1 (ADR-UI-009). |
| `NOT_IN_BUILD` | در نسخه نیست | Row of the spec that is not part of the current build; reported, never silently skipped. |
| Lead | سرپرست | The only agent that talks to the owner; keeps STATUS. |
| Advisor | مشاور | Independent reviewer at gates and on escalation. |
| Hat | کلاه (نقش) | One role worn by one session at a time (Architect, Builder-UI, Tester, …). |
| Task packet | کارت وظیفه | `docs/agents/tasks/T-XXX.md`; no packet, no work. |
| ESC / ADVISOR_REPLY | پرسش / پاسخ مشاور | One-page escalation file and its answer, exchanged through git. |
| D0–D3 | رده‌ی تصمیم | Who decides: agent, Lead, Advisor, owner. |
| Circuit breaker (CB-1…9) | قطع‌کننده | Rule that stops a loop, overspending or out-of-repo work. |
| Handoff | تحویل | The written end-of-task report from `docs/agents/HANDOFF_TEMPLATE.md`. |
| Digest | چکیده‌ی نقش | Short per-hat reading list in `docs/agents/digests/`. |
