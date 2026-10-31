# spike/T-011-goldens — golden stability on the Linux CI image

Answers **SP-06** (`docs/architecture/SPIKE_PLAN.md`) for GM-01, task `docs/agents/tasks/T-011.md`. Evidence, not product.

## What runs
`lib/toy_card.dart` is a toy card built only from Material widgets with their default theme values (text, an LTR number, a determinate bar, an indeterminate spinner, a button, the card shadow). `test/golden_toy_test.dart` renders it in the 8 GMX-01 combinations (light/dark × RTL/LTR × scale 1.0/2.0) at Compact 360×640, device pixel ratio 1.0, names per GM-02 (`goldens/ToyCard/default__<theme>_<dir>_s<scale>.png`), one frame only (GM-07).

`.github/workflows/spike-goldens.yml`:

| Job | Does |
|---|---|
| `generate goldens run1/run2/run3` | three fresh `ubuntu-24.04` runners, pinned Flutter, `flutter test --update-goldens`; uploads the PNGs and `SHA256SUMS` |
| `generate goldens macos` | same on `macos-15`, information only (never blocks) |
| `compare` | fresh runner: the three Linux `SHA256SUMS` must be identical; run 1's goldens pass in compare mode; with `--dart-define=TOY_MUTATE=true` (bar value +0.002, under one pixel) the comparison must fail with `Pixel test failed`; macOS hashes are compared with Linux and only reported |

No dependency outside the Flutter SDK. Goldens are never committed (`.gitignore`); they exist only as artifacts of the CI run (GM-01, GM-06).

## Findings
Filled from the CI run once it is green (see the PR handoff).
