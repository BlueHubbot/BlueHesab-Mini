# spike/T-009-platform — sizes, cold start, unsigned desktop packages

Answers **SP-09** (sizes, cold start) and the DMG / zip / checksum / clean-install part of **SP-10** (`docs/architecture/SPIKE_PLAN.md`), task `docs/agents/tasks/T-009.md`. Evidence, not product.

## What runs
`.github/workflows/spike-platform.yml` builds the **real skeleton app** (root `lib/`, unchanged, pinned Flutter from `tool/ci/install_flutter.sh`) and:

| Job | Does |
|---|---|
| `android sizes + cold start (emulator)` | release APK universal + `--split-per-abi`; sizes; API 35 x86_64 emulator; `am start -W -S` × 5 → `tool/cold_start.py` |
| `windows build + zip` | `flutter build windows --release`; zip + `SHA256SUMS`; sizes; artifact `t009-windows` |
| `macos build + dmg` | `flutter build macos --release`; zip (`ditto`) + DMG (`hdiutil create -format UDZO`, with an `/Applications` link) + `SHA256SUMS`; sizes; artifact `t009-macos` |
| `windows clean install + launch` | fresh runner, no checkout, no Flutter: `gh run download`, `sha256sum -c`, extract, Authenticode status, launch, still running after 15 s |
| `macos clean install + launch` | fresh runner, no checkout, no Flutter: `gh run download`, `shasum -c`, mount DMG, copy app out, `codesign -dv`, `spctl -a`, quarantine attribute, launch, still running after 15 s |

`tool/sizes.py` and `tool/cold_start.py` are Python standard library only. No new dependency (only OS tools present on the runner images: `hdiutil`, `ditto`, `codesign`, `spctl`, PowerShell, `gh`).

**Layout deviation (D0, `spike/README.md` rule 1):** this folder is not a Dart package, because it measures the root app and has no Dart code of its own; a `pubspec.yaml` here would only add an empty lockfile.

## Findings
CI run 41171705259 on `f922c6a` (Flutter 3.47.8 pinned; runners ubuntu-24.04, windows-2025, macos-15). Sizes are decimal MB.

| # | Finding |
|---|---|
| P1 | **Android sizes:** universal release APK 42,681,799 B = 42.68 MB (below the 50 MB soft flag); split per ABI: arm64-v8a 14.93 MB, armeabi-v7a 12.17 MB, x86_64 16.37 MB. A phone download is about a third of the universal APK if per-ABI APKs (or an app bundle) are published: proposal for the release task, not decided. |
| P2 | **Windows sizes:** release folder 25.46 MB (the `.exe` is 0.09 MB; the engine is in `flutter_windows.dll`), zip 10.89 MB. |
| P3 | **macOS sizes:** `.app` 37.70 MB, zip 15.50 MB, DMG (UDZO) 17.10 MB. |
| P4 | **Android cold start** (`am start -W -S`, LaunchState COLD, emulator API 35 x86_64 with software GPU, not the reference device): TotalTime 2025, 2918, 2484, 2239, 2926 ms, median 2484 ms. Indicative only; the number for the SPIKE_REPORT must come from the reference phone (Q-09, with SP-08). |
| P5 | **Clean install:** on fresh runners without Flutter, `SHA256SUMS` verified, the DMG mounted read-only and the app copied out, the zip extracted, and both apps were still running after 15 s (Windows working set 83 MB, macOS RSS 74 MB). |
| P6 | **macOS unsigned warnings:** the app is ad-hoc signed (`Signature=adhoc`, `TeamIdentifier=not set`) and `spctl -a -t exec` says `rejected`: on a user's Mac a downloaded copy will be blocked by Gatekeeper until the user allows it in System Settings, unless it is signed and notarised (Q-07). The CI download sets no quarantine attribute, so the first-launch dialog itself is not reproduced. |
| P7 | **Windows unsigned warnings:** `Get-AuthenticodeSignature` = `NotSigned`; a browser download would carry Mark-of-the-Web and trigger SmartScreen; the CI download has none, so SmartScreen is not reproduced. |
| P8 | **Desktop cold start** not measured: it needs a first-frame marker inside the app (`lib/` change), left to the task that adds performance hooks. |
| P9 | **No new dependency:** only runner OS tools and the pinned Flutter; the clean-install jobs fetch artifacts with the preinstalled `gh` CLI instead of adding `actions/download-artifact` (no audit row, CB-9). |

## Open items for the owner (not decided here)
- Windows installer format (RV-2: MSIX or Inno Setup): either tool needs an audit row first (CB-9); this spike ships a zip only.
- Signing and notarisation (Q-07): every package here is unsigned (APK uses Flutter's debug key; never for release).
- Reference phone (Q-09): emulator cold start is indicative only; SP-08 (perf) needs the device.
