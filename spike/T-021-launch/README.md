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
CI run [42166935068](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/42166935068) on `88e7fb5` (Flutter 3.47.8 pinned; runners macos-15, ubuntu-24.04).

| # | Finding |
|---|---|
| L1 | **iOS simulator:** the root app (`flutter build ios --simulator --debug`, `Runner.app` 141108 KB) installed and launched on iOS 26.2 iPhone 17 Pro: `io.github.bluehubbot.bluehesabMini: 9369`; after 15 s still running (`launchctl: 9369 0 UIKitApplication:io.github.bluehubbot.bluehesabMini`, RSS 169296 KB). `SPIKE_EVIDENCE ios_sim running_after_15s=true pid=9369 device=iOS-26-2:iPhone_17_Pro`. Screenshot: artifact `t021-ios-screenshot`. |
| L2 | **iOS negative control:** `simctl launch` of `io.github.bluehubbot.notInstalled` failed (`FBSOpenApplicationServiceErrorDomain, code=4`), so the launch check can fail. |
| L3 | **Web demo:** `flutter build web --release` served from 127.0.0.1 and opened in headless Google Chrome 156.0.8078.79: the loaded DOM has `<flutter-view>`, `<flt-glass-pane>` and the semantics/text-editing hosts; 0 console errors. `SPIKE_EVIDENCE web_demo flutter_view=true console_errors=0`. Screenshots: artifact `t021-web-screenshot` (the skeleton page is empty by design). |
| L4 | **Web negative control:** an empty page under the same Chrome check has no `<flutter-view` (notice "no <flutter-view on the empty page, as expected"). |
| L5 | **Web notes:** the local server was asked only for `/`, `flutter_bootstrap.js`, `manifest.json`, `main.dart.js`, `favicon.png`, `icons/Icon-192.png`, `assets/FontManifest.json`; no renderer (CanvasKit/wasm) file was requested from it. Chrome logged "Automatic fallback to software WebGL has been deprecated" (no GPU on the runner). Whether the demo needs Google's CDN (`--no-web-resources-cdn`) is not shown here; it matters only for an offline demo host (ADR-0009, web = demo only). |

## Disposition (spike/README.md rule 5)
`DELETE` at the end of M0: the workflow is evidence for SP-01 only; nothing here is promoted.
