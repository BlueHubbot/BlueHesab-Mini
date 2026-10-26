# MODULE_CONTRACT — Optional modules and the core

**Status:** PROPOSED (accepted with ADR-0009) · **Owner:** Lead architect · **Date:** 2026-10-26
**Depends on:** UI spec ND-01…ND-05, DM-01…DM-07, IN-2, IN-4, IN-6, QT-01, QT-05, MM-01…MM-04, MMX-01…MMX-14; `DATA_MODEL.md` §9 (MG-05); `MVP_SCOPE.md`.

## خلاصه‌ی فارسی
- چهار بخش «هسته» همیشه روشن‌اند (خانه، حسابداری، گزارش‌ها، تنظیمات). شش ماژول اختیاری‌اند: بودجه، کارها، سلامت، خودرو، بازارها، دستیار.
- در نسخه‌ی MVP فقط **بودجه** ساخته می‌شود و پیش‌فرض روشن است. ماژول‌های ساخته‌نشده اصلاً در برنامه ثبت نمی‌شوند، پس هیچ ردی ندارند (DM-01) و «به‌زودی» هم نشان داده نمی‌شود.
- هسته هرگز ماژول را import نمی‌کند؛ ماژول هم ماژول دیگر را import نمی‌کند. همه‌چیز از راه یک «توصیف‌گر» (`ModuleDescriptor`) ثبت می‌شود و فقط چند نقطه‌ی اتصال مجاز است.
- خاموش‌کردن ماژول داده‌ای را پاک نمی‌کند. «حذف داده‌های ماژول» عمل جدا و مخرب با تأیید است.
- هر ماژول جدول (`m_<id>_`) و مهاجرت خودش را دارد.

## 1. Vocabulary and scope
- **Core** (always on, no switch; ND-02): `home`, `accounting`, `reports`, `settings`. Core also owns the model-connection layer (IN-6), the date layer, money, copy catalog, tokens and navigation.
- **Optional modules:** `budget`, `tasks`, `health`, `car`, `markets`, `assistant`. Adding or removing a destination requires an ADR (ND-02).
- **MVP v0.1:** only `budget` exists (default ON). `tasks`, `health`, `car`, `markets`, `assistant` have no descriptor, no route, no tables, no copy keys in the build (so DM-01 holds by construction). Their spec rows stay in the catalog for later waves.

## 2. Architecture rules
| ID | Rule |
|---|---|
| MDC-A1 | Layering per module: `presentation` → `application` (use cases, ports) → `domain` → `data`. UI never touches DB/network/AI (CM-01). |
| MDC-A2 | `core` imports nothing from `modules/*`. A module imports only `core` public APIs (`package:bluehesab/core/...`), never another module. Enforced by an import-lint script in CI (see §9). |
| MDC-A3 | The core discovers modules only through `ModuleRegistry` built from `ModuleDescriptor`s listed in one file (`app/module_list.dart`). Adding a module = one descriptor + one line there. |
| MDC-A4 | Navigation, QuickAdd tabs, Home widgets, DayRing arcs, report sections, global search, reminders and links are all built from the registry filtered by enabled state (ND-01, DM-01). No hand-written lists elsewhere. |
| MDC-A5 | Cross-module needs go through a **core port** (interface in `core/ports/`), implemented by the providing module and registered in its descriptor. Example: reports ask `ReportSectionProvider`s; QuickAdd asks `QuickAddTypeProvider`s. Calling a port of a disabled module is impossible because it is not registered. |
| MDC-A6 | The finance core must work with every optional module off (MMX-01, DM-06). A module never changes core behavior, only adds contributions. |
| MDC-A7 | A module owns its routes (`/budget`, `/budget/...`) and registers children in its own section of the route table (ND-04). |

## 3. The descriptor
```dart
// Illustrative. Names are the contract; Agent 3/4/5 refine signatures inside their task.
abstract interface class ModuleDescriptor {
  DestinationId get id;                    // one of the optional DestinationIds
  int get schemaVersion;                   // module tables version (MG-05)
  bool get defaultEnabled;                 // MVP: budget = true
  List<ModuleMigration> get migrations;    // forward-only, own tables m_<id>_*
  Destination get destination;             // spec 5-1 row; titles from l10n keys
  List<RouteBase> get routes;              // go_router routes (candidate)
  List<QuickAddTypeContribution> get quickAddTypes;   // QT-01 (tasks only in later waves)
  List<HomeWidgetContribution> get homeWidgets;       // HM-xx cards; may be empty
  DayRingArcContribution? get dayRingArc;             // DayRing arc source; budget arc in MVP
  List<ReportSectionContribution> get reportSections; // appear only when enabled
  List<SearchProvider> get searchProviders;           // global search results
  List<ReminderSource> get reminders;                 // notification-shade items
  List<AiToolDescriptor> get aiTools;                 // AI_TOOL_CONTRACT; empty in MVP
  Widget? settingsPage(BuildContext c);               // module settings, incl. "delete module data"
  Future<void> deleteAllData(ModuleDataEraser eraser); // destructive, confirmed by UI (DM-03)
}
```
Rules for contributions:
- Each contribution is a pure description plus use-case handles; it never holds mutable global state.
- A contribution that depends on the module's own data (e.g. budget arc) returns an empty/absent result when there is no data; the host decides the empty state (VI-15).
- Titles, descriptions and hints come from the copy catalog (DMX-0x rows); no Persian strings in the descriptor (CM-10).

## 4. Enabled state and lifecycle
- State is stored as setting `modules.enabled` (array of ids) — see DATA_MODEL §6. Core ids are not stored; they are always on. First run writes defaults from the registry (`defaultEnabled`).
- `ModuleRegistry.enabled` is a stream; every consumer (nav, QuickAdd, Home, DayRing, search, reports, reminders) rebuilds from it. There is **no restart** for enable/disable (DM-04).
- **Disable (DM-03):** write the setting, emit the stream, show the toast with Undo. No data deleted, no dialog. Undo restores the previous array (idempotent).
- **Enable (DM-04):** write the setting; destination returns to its previous pinned place (BN-02, HM-05); arc returns; toast.
- **Direct route to a disabled module (DM-05):** the router redirect renders `ModuleDisabledPage`; it never appears in navigation.
- **Delete module data:** only via the module's settings page, destructive style, confirmation dialog, a recovery point first (DATA_MODEL MG-02 pattern); calls `deleteAllData`. After deletion the module may stay enabled and shows its empty state.
- **Financial data created by a module (DM-06):** transactions a module writes through the accounting use cases belong to the core (`origin` stays truthful) and remain after the module is disabled; only module-specific filters, chips and links hide.
- **Pins and Home layout:** disabled destinations disappear from `effectivePins` and the home layout without deleting the saved preference, so re-enabling restores them (5-2 vectors).

## 5. Persistence contract
- Table prefix `m_<id>_`; foreign keys from a module table to core tables are allowed (e.g. `m_budget_limits.category_id`); core tables never reference module tables.
- Each module has an entry in `module_schema(module_id, version)`; module migrations run after core migrations in the same transaction batch; a failing module migration rolls back everything of that launch (MG-02 recovery file applies).
- Export/backup: a module contributes a named section to the backup (`budget_limits` in v0.1) through a `BackupSection` port; restore validates each section by its declared schema version. A backup from a build with a module that is absent here is rejected with a clear message rather than silently dropping data (I-10).
- Module data is never used by another module; shared meaning goes through core entities.

## 6. The `budget` module (MVP)
| Aspect | Contract |
|---|---|
| Destination | `budget`, route `/budget`, accent `accent-finance`, group "مالی", owner Agent 3; pinnable (BN-02). Default ON. |
| Entities | `m_budget_limits` (DATA_MODEL §5). Optionally goals (saving targets) later, not in v0.1. |
| Use cases | `SetBudgetLimit`, `GetBudgetPeriod(month, calendar)`, `ListBudgetPeriods`, `SupersedeBudgetLimit`. All math in domain with `BigInt` (DD-09). |
| Contributions | Home budget progress bar and `DayRing` budget arc (needs this module; spec 1-3; the day-ring empty text VI-15 is amended by SE-12). **Not in v0.1:** a report section (the budget page already shows limit against spending per category; a `ReportSectionContribution` may come later) and the reminder when a category exceeds its limit. |
| Reads from core | categories (read-only), transactions aggregate per category and month via a core read port `SpendingQuery` (returns per-category sums computed in the domain, not SQL). |
| Disabled | Home progress bar, arc, nav item and settings entry vanish; the day-ring card follows the interim rule of SE-12; `m_budget_limits` kept. |
| Copy | DMX-02 for the settings description; budget screens use the copy catalog rows added by task cards (UI-delta U-4). |

## 7. Later modules (reservations, not designs)
| Module | Reserved contributions | Notes |
|---|---|---|
| `tasks` | QuickAdd type `task` (QT-01/02), DayRing tasks arc, Home card, reminders, calendar | needs a reminders/notification design (ADR later); no finance coupling |
| `health` | habits arc, Home card; health data is sensitive | privacy note DMX-01; never in AI context without explicit user opt-in |
| `car` | transaction helper (fuel/service) that writes accounting transactions through core use cases (DM-06); document reminders | owner Agent 4 |
| `markets` | prices, holdings; needs network and a data-source decision (Q-05) | the only module that may use network by itself; offline-first cache; every outbound request listed in `PRIVACY.md` |
| `assistant` | smart-input button in QuickAdd (QT-05), AssistantPage, `AiToolDescriptor`s | core keeps the model-connection layer (IN-6); the module is only UI + tool registration; see `AI_TOOL_CONTRACT.md` |

A later module is accepted only when: a task packet exists, its descriptor passes the import-lint, its row in MMX is filled, and its copy and tokens are in the catalogs.

## 8. Cross-module events
- v0.1 has no event bus. Needed notifications use Drift/stream queries on core data. If a bus is needed later, it lives in `core/`, carries typed immutable events, and is added by ADR. Modules never subscribe to each other.

## 9. Enforcement and tests
| ID | Check |
|---|---|
| MDC-T1 | Import-lint (`tool/lint/imports.dart`): `core/**` must not import `modules/**`; `modules/<a>/**` must not import `modules/<b>/**`; `presentation` must not import `data`. Runs in CI and as part of `ui_check`. |
| MDC-T2 | Registry matrix test = MM-01…MM-04. **MVP profile (ADR-UI-009):** the matrix contains the combinations that exist in the build — `budget` off and `budget` on — and the test asserts that absent modules leave no trace by scanning destination catalog, routes, copy keys, QuickAdd types and Home contributions for the ids `tasks|health|car|markets|assistant`. The full MMX-01…MMX-14 table activates as each module ships and is mandatory at GTX-05. |
| MDC-T3 | Disable/enable round trip: data in module tables identical before and after; core queries unchanged (I-11). |
| MDC-T4 | `DM-05` redirect test for a disabled module route and for an unknown module id (no crash, falls back to Home). |
| MDC-T5 | Migration test per module (empty → latest, previous fixture → latest). |
| MDC-T6 | Backup round trip includes the module section; a backup with an unknown section is rejected without changes. |
| MDC-T7 | Removing `budget` from `app/module_list.dart` compiles and passes all core tests (core independence proof). |

## 10. Open questions
MQ-1: should `markets` be allowed its own network layer or go through a core `NetworkPort` with a global allowlist (recommend the port; decide at module start). MQ-2: reminders and notifications architecture (per platform) — ADR when `tasks` starts. MQ-3: module-level encryption/privacy flags for `health`. MQ-4: do module settings pages live inside "تنظیمات › ماژول‌ها" or inside the module page (current spec: module page, DM-03).
