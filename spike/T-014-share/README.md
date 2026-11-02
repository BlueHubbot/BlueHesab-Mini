# spike/T-014-share — Android share intent and clipboard on tap (SP-07, emulator half)

Evidence, not product (spike/README.md). Packet: `docs/agents/tasks/T-014.md`. CI: `.github/workflows/spike-share.yml`.

## What it shows
- A Flutter app with **no plugin** receives `ACTION_SEND` `text/plain`: one `<intent-filter>` on `MainActivity` and `native/MainActivity.kt` (method channel `spike.share/intent`). Cold start: `takeInitialText` (read in `onCreate` before the engine starts). Running app: `onNewIntent` → `sharedText` to Dart.
- The Android folder is **not committed**: CI runs `flutter create --platforms=android --org dev.bluehesab.spike --project-name spike_share .`, then `tool/prepare_android.py` copies `MainActivity.kt` and adds the one filter, and fails if the main manifest asks for a permission.
- `tool/share_cases.py run` sends synthetic texts with `am start` and compares the `SPIKE_SHARE` logcat marker (code-unit length + FNV-1a 32 of the UTF-8 bytes; never the text, CAPTURE_PIPELINE §6) with the values it computes itself.
- `integration_test/clipboard_test.dart` (on the emulator): text on the clipboard is **not** read at start; it fills the field only after the paste tap.
- `aapt2 dump permissions` on the release APK: no SMS permission.

## Findings
Filled from the CI run on the PR (see the handoff there).

## What the real phone must still show (owner, Q-09)
1. Share from the real SMS app through the system chooser (the CI uses an explicit component; the chooser path is only proven by `query-activities` resolution).
2. Copy in another app, then tap paste in the app (the integration test copies from the same app).
3. The Android version and vendor skin of the owner's phone (the emulator is stock API 35).
4. Behaviour when the app is in the background but not on top (share into a task that is not in front).
