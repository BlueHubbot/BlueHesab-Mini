# spike/ — rules for M0 spike code

**Owner:** Builder-Platform (T-001) · **Applies to:** T-002, T-003 and any task that cites `SPIKE_PLAN.md`.

Spike code answers the questions SP-01…SP-12 in `docs/architecture/SPIKE_PLAN.md`. It is evidence, not product.

1. **Layout.** One folder per task: `spike/<task-id>-<slug>/` (example: `spike/T-002-money/`). Each folder is its own Dart or Flutter package with its own `pubspec.yaml`, `pubspec.lock`, tests and a short `README.md` naming the SP IDs it answers.
2. **Isolation.** Nothing in `lib/` or `test/` imports spike code. CI fails on any `spike/` or `package:spike` import there (`.github/workflows/ci.yml`, job `analyze + test`). The root `analysis_options.yaml` excludes `spike/**`; each spike package is analysed and tested inside its own folder.
3. **Dependencies.** Same rule as the app (CB-9): a dependency enters a spike `pubspec.yaml` only after its row exists in `docs/research/OPEN_SOURCE_AUDIT.md`. Run `tool/ci/license_scan.py` on the spike lockfile before asking for review.
4. **Data.** Synthetic only. No real SMS, receipts, bank data, keys or model weights.
5. **End of life.** At the end of M0 every spike folder is either deleted or promoted by a task packet. Only code that `docs/architecture/SPIKE_REPORT.md` marks `KEEP` may be promoted, and it is moved (with tests) into `lib/` by that task, not copied.
6. **Time box.** As in `SPIKE_PLAN.md`: 5 working sessions in total; more than 50 % over means stop and escalate (CB-2).
