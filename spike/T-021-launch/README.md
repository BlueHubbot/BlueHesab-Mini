# spike/T-021-launch — root app on the iOS simulator, web demo in a browser

Answers the launch part of **SP-01** that T-001 and T-009 left open (`docs/architecture/SPIKE_PLAN.md`; SPIKE_REPORT row SP-01), task `docs/agents/tasks/T-021.md`. Evidence, not product.

## What runs
`.github/workflows/spike-launch.yml` builds the **real skeleton app** (root `lib/`, unchanged, pinned Flutter) with the same commands as `ci.yml`, then:

| Job | Does |
|---|---|
| `ios simulator launch` | `flutter build ios --simulator --debug`; boots the newest iPhone simulator; negative control (`simctl launch` of a bundle that is not installed must fail); `simctl install` + `simctl launch`; process alive after 15 s; `simctl io … screenshot` → artifact `t021-ios-screenshot` |
| `web demo in headless chrome` | `flutter build web --release`; `python3 -m http.server` on 127.0.0.1; negative control (an empty page must have no `<flutter-view`); headless Chrome `--dump-dom` and `--screenshot`; the loaded DOM must contain `<flutter-view`; console lines and served requests printed → artifact `t021-web-screenshot` |

No new dependency or action: only the pinned Flutter, Xcode's `simctl`, Python's standard library and the Chrome preinstalled on the runner image. Screenshots show the empty skeleton page only.

**Layout deviation (D0, `spike/README.md` rule 1, as T-009):** not a Dart package; it launches the root app and has no Dart code of its own.

## Findings
Pending the first green CI run.

## Disposition (spike/README.md rule 5)
`DELETE` at the end of M0: the workflow is evidence for SP-01 only; nothing here is promoted.
