# spike/T-014-share — Android share intent and clipboard on tap (SP-07, emulator half)

Evidence, not product (spike/README.md). Packet: `docs/agents/tasks/T-014.md`. CI: `.github/workflows/spike-share.yml`.

## What it shows
- A Flutter app with **no plugin** receives `ACTION_SEND` `text/plain`: one `<intent-filter>` on `MainActivity` and `native/MainActivity.kt` (method channel `spike.share/intent`). Cold start: `takeInitialText` (read in `onCreate` before the engine starts). Running app: `onNewIntent` → `sharedText` to Dart.
- The Android folder is **not committed**: CI runs `flutter create --platforms=android --org dev.bluehesab.spike --project-name spike_share .`, then `tool/prepare_android.py` copies `MainActivity.kt` and adds the one filter, and fails if the main manifest asks for a permission.
- `tool/share_cases.py run` sends synthetic texts with `am start` and compares the `SPIKE_SHARE` logcat marker (code-unit length + FNV-1a 32 of the UTF-8 bytes; never the text, CAPTURE_PIPELINE §6) with the values it computes itself.
- `integration_test/clipboard_test.dart` (on the emulator): text on the clipboard is **not** read at start; it fills the field only after the paste tap.
- `aapt2 dump permissions` on the release APK: no SMS permission.

## Findings (CI, API 35 x86_64 emulator, Flutter 3.47.8)
- S1. Implicit resolution: `cmd package query-activities -a android.intent.action.SEND -t text/plain` lists `dev.bluehesab.spike.spike_share/.MainActivity`.
- S2. Cold start: ASCII (30 code units, `3b97f3c3`), Persian with Persian digits, `٬` and an LTR number (33, `e6c70ebc`) and 4 000 characters (`ca532708`) arrived exactly. `adb shell` passes UTF-8 text unchanged.
- S3. Running app: the second share arrived exactly through `onNewIntent` (`singleTop` from the template; `am` reports delivery to the running top-most instance), so one Dart listener covers the warm path.
- S4. Clipboard: with text already on the clipboard the field stays empty at start and fills only after the tap (`integration_test`, `00:03 +1: All tests passed!`).
- S5. Permissions of the release APK: none requested by the spike; the manifest merger adds AndroidX's signature-level `<app id>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (internal, no user prompt). No SMS permission.
- S6. No plugin needed: about 50 lines of Kotlin and a 40-line Dart wrapper. Proposal for the M2 capture task: keep this shape behind a share port (builder-platform digest) instead of a receiver plugin, so no audit row is needed.
- S7. `flutter create .` in an existing package rewrites `pubspec.lock` and adds `test/widget_test.dart`; the workflow restores tracked files and removes the extra file before checking the tree. `pub get` then printed `Upgrading analysis_options.yaml to exclude build and platform directories.`, so `android/**` is now excluded in the committed file.
- S8. Release APK size 47.6 MB universal (Flutter engine for three ABIs; T-009 measures the real app).

## What the real phone must still show (owner, Q-09)
1. Share from the real SMS app through the system chooser (the CI uses an explicit component; the chooser path is only proven by `query-activities` resolution).
2. Copy in another app, then tap paste in the app (the integration test copies from the same app).
3. The Android version and vendor skin of the owner's phone (the emulator is stock API 35).
4. Behaviour when the app is in the background but not on top (share into a task that is not in front).
