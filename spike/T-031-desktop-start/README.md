# spike/T-031-desktop-start — desktop start time to the first frame (SP-09)

**Task:** `docs/agents/tasks/T-031.md` · **Answers:** SP-09 (desktop part; SPIKE_REPORT §1 P8, §5 "Desktop cold start") · **Workflow:** `.github/workflows/spike-desktop-start.yml`

## Method
- `first_frame_main.dart` runs the unchanged root app (`BlueHesabApp` from `lib/main.dart`), waits for `WidgetsBinding.instance.waitUntilFirstFrameRasterized` and exits with code 37.
- The root package is built with the `ci.yml` command plus `-t spike/T-031-desktop-start/first_frame_main.dart` (release, macOS `macos-15`, Windows `windows-2025`).
- `tool/start_time.py measure` launches the executable 5 times and records spawn → exit (code 37 required) in ms; `control` launches the build without the marker and requires it to be still running after 20 s.
- Layout deviation (as T-009, T-021): not its own Dart package; the entry file is compiled as part of the root package. The root `analysis_options.yaml` excludes `spike/**`; the release build is the compile check.

## Findings
Run [43560406478](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/43560406478) on commit `5c4143d` (Flutter 3.47.8 pinned). Spawn → first frame rasterized → exit, in ms; CI runner right after the build (files in the OS cache, no GPU), so indicative, not the reference device.

| # | Finding |
|---|---|
| D1 | macOS (`macos-15`): `SPIKE_EVIDENCE macos_first_frame_ms median=459 runs=2249,473,293,286,459 exit_code=37`. The first launch after the build is about 5× the later ones. |
| D2 | Windows (`windows-2025`): `SPIKE_EVIDENCE windows_first_frame_ms median=1364 runs=1630,1364,1352,1346,1366 exit_code=37`. The spread is small; every run is above 1.3 s. |
| D3 | Negative control on both: "app without marker still running after 20.0 s, as expected; stopped". A pass needs the marker. |
| D4 | `dart:io` `exit()` ends a Flutter desktop release app cleanly on both OSes (exit code 37 seen every run), so a first-frame marker needs no platform code. |
| D5 | No rule ID gives a desktop start budget, so these numbers are recorded, not judged. The product first-frame marker (inside `lib/`) stays a later task with its perf budget. |
