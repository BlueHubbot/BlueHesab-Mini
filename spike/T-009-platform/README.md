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
_Filled from the CI run; see the PR handoff for the pasted output._

## Open items for the owner (not decided here)
- **RV-2** Windows installer format (MSIX or Inno Setup): either tool needs an audit row first (CB-9); this spike ships a zip only.
- **Q-07** signing / notarisation: every package here is unsigned (APK uses Flutter's debug key; never for release).
- **Q-09** reference phone: emulator cold start is indicative only; SP-08 (perf) needs the device.
