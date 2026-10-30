# spike/T-008-modules — module registry toy (SP-12)

**Task:** `docs/agents/tasks/T-008.md` · **Answers:** SP-12 (state/routing candidates with the module registry, MDC-A3; one module registered/unregistered without core change, MDC-T7) · **Rules:** MDC-A2, MDC-A3, MDC-A4, MDC-A7, MDC-T1, MDC-T2 (MVP), MDC-T4, MDC-T7, DM-01, DM-03…DM-05, ND-04, CM-10 · Evidence, not product (`spike/README.md`).

## What is here
- `lib/core/` — `ModuleDescriptor` (MODULE_CONTRACT §3 reduced to id, default state, title key, root path, routes, Home cards), `module_registry.dart` (Riverpod: `moduleListProvider`, `enabledModulesProvider`, `activeModulesProvider`), `app_router.dart` (go_router table from the registry; `disabledRedirect` for DM-05; `onException` → `/home` for MDC-T4), core pages and `ModuleDisabledPage`, `SpikeApp` (RTL forced).
- `lib/modules/budget/` — the budget descriptor: `/budget`, `/budget/limits`, one Home card. Imports only `core`.
- `lib/app/module_list.dart` — the one list (MDC-A3); `lib/main.dart` overrides `moduleListProvider` with it. The core default is an empty list.
- `tool/remove_module.py` — used only by the CI job "module removed (MDC-T7)" on its throw-away checkout.

Titles are copy-catalog keys (`dest.budget`, `dmx10.title`), never display text (CM-10). No tokens or styling.

## Tests
| File | Runs on | Covers |
|---|---|---|
| `test/registry_test.dart` | VM + Chrome | defaults, list order, disable/enable at once, unknown id ignored, budget paths under `/budget` |
| `test/redirect_test.dart` | VM + Chrome | DM-05 decision, look-alike prefixes, `/` → `/home`, absent modules |
| `test/app_widget_test.dart` | VM + Chrome | nav and Home cards from enabled modules; disable/enable live, router not rebuilt; DM-05 for current page and deep link with "enable" and "home" buttons; unknown paths → `/home`; RTL deep link `/budget/limits` with back button right of the title, back button and system back → `/budget`; empty module list leaves no budget route, nav item or card |
| `test/core_test.dart` | VM + Chrome + MDC-T7 job | core destinations with whatever `module_list.dart` holds; never names a module |
| `test/import_lint_test.dart` | VM | core imports no `modules/`/`app/`; budget imports only core; `module_list.dart` is the only non-module file naming a module |
| `test/evidence_test.dart` | VM | pinned versions, resolved graph members, OS |

CI: `.github/workflows/spike-modules.yml`.

## Findings (SP-12)
Evidence: CI on `640ed43` (Flutter 3.47.8, Dart 3.13.7): `00:03 +23: All tests passed!` (Linux), `00:04 +23` (Windows), `00:05 +23` (macOS), Chrome `00:07 +19`; MDC-T7 job `No issues found!` and `00:01 +3: All tests passed!`; license scan 38 packages, 0 failing; analyzer clean. Every test was green on the first run with the lockfile.

- **M1 · MDC-T7 holds.** Deleting the two `module:budget` lines in `app/module_list.dart` and the `lib/modules/budget/` folder leaves `lib/core/` unchanged (checked with `git status` in the job), the analyzer clean and the core tests green. One module = one import + one list line.
- **M2 · Registry over Riverpod.** A plain `Provider` for the module list (overridden by the app), a `Notifier<Set<String>>` for enabled ids and a derived `Provider` for active modules is enough; no code generation, no `riverpod_annotation`. Riverpod batches rebuilds: a synchronous test sees each step only if it reads the derived provider in between (recorded in `registry_test.dart`); widgets see every change after a frame.
- **M3 · Router over go_router.** The router is built once from the module list; enable/disable re-runs the top-level `redirect` through `refreshListenable` (a `ChangeNotifier` pinged by `ref.listen`), so the page of a module that is switched off becomes `ModuleDisabledPage` at once and the router object stays the same (DM-04: no restart). Paths of absent modules are not routes at all; `onException` sends them to `/home` without an exception (MDC-T4). The top-level `redirect` also runs for unmatched paths before `onException`, which makes `/` → `/home` one line.
- **M4 · RTL back and deep links.** Deep link `/budget/limits` builds the stack `/budget` → `/budget/limits` from the nested route; under RTL the AppBar back button is right of the title; the back button and the system back (`handlePopRoute`) both return to `/budget`. Same on VM and Chrome.
- **M5 · Real runtime graph (audit row "spike must verify").** `flutter pub deps --no-dev`: `flutter_riverpod` 3.4.3 → `collection flutter flutter_test meta riverpod state_notifier`; `riverpod` 3.4.3 → `async clock collection listen meta stack_trace state_notifier test_api uuid`; `go_router` 18.1.0 → `collection cupertino_ui flutter flutter_web_plugins logging material_ui meta`; `material_ui` 1.9.0 and `cupertino_ui` 1.1.5 → `flutter_localizations intl` (and `material_color_utilities`, `vector_math`). So `flutter_test` and `test_api` are runtime dependencies of the Riverpod packages, and `uuid`/`crypto`/`fixnum`/`listen`/`intl` arrive transitively. All 38 packages are permissive (MIT, BSD-3-Clause, Apache-2.0); the audit rows for `flutter_riverpod` and `go_router` should record this list.
- **M6 · Versions.** `flutter_riverpod` 3.4.3 and `go_router` 18.1.0 resolve with Flutter 3.47.8 exactly as pinned; `go_router` pulls `material_ui` 1.9.0 / `cupertino_ui` 1.1.5, which resolve too (the risk in the packet did not happen).
- **M7 · Web.** The widget tests compile and pass in Chrome. A full `flutter build web` of the toy was not done (no `web/` folder in the spike); the app's own web-demo build job stays the evidence for the product.
- **M8 · Not covered.** Persistence of `modules.enabled`, bottom navigation and pins (BN-02), shell routes (`StatefulShellRoute`) for a persistent bottom bar, QuickAdd/DayRing contributions, `flutter_localizations` locale setup (RTL was forced with `Directionality`).

## Input for the state/routing ADR (proposal only)
Riverpod (plain `Provider`/`Notifier`, no codegen) for the registry and go_router for routes meet MDC-A3/A4/A7, DM-03…DM-05 and MDC-T7 in this toy. Before adopting: record M5 in the audit rows; decide whether test-only packages in the runtime graph are acceptable (whether any of their code reaches a release build was not measured here; they are in the lock and the license notices either way); try `StatefulShellRoute` with the bottom bar in the first shell task.
