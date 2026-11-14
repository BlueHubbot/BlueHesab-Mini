# spike/T-031-desktop-start — desktop start time to the first frame (SP-09)

**Task:** `docs/agents/tasks/T-031.md` · **Answers:** SP-09 (desktop part; SPIKE_REPORT §1 P8, §5 "Desktop cold start") · **Workflow:** `.github/workflows/spike-desktop-start.yml`

## Method
- `first_frame_main.dart` runs the unchanged root app (`BlueHesabApp` from `lib/main.dart`), waits for `WidgetsBinding.instance.waitUntilFirstFrameRasterized` and exits with code 37.
- The root package is built with the `ci.yml` command plus `-t spike/T-031-desktop-start/first_frame_main.dart` (release, macOS `macos-15`, Windows `windows-2025`).
- `tool/start_time.py measure` launches the executable 5 times and records spawn → exit (code 37 required) in ms; `control` launches the build without the marker and requires it to be still running after 20 s.
- Layout deviation (as T-009, T-021): not its own Dart package; the entry file is compiled as part of the root package. The root `analysis_options.yaml` excludes `spike/**`; the release build is the compile check.

## Findings
Pending the CI run on the PR.
