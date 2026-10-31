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
CI run 41228789660 on `b94ccd3` (Flutter 3.47.8 pinned; runner image `ubuntu24/20261026.354.1`; macOS 15 for information).

| # | Finding |
|---|---|
| G1 | **SP-06 passes:** three fresh Linux runners produced the same 8 goldens byte for byte (`SHA256SUMS` identical, digest of the sums file `8160c1fa17c0b522`); a fourth fresh runner compared run 1's files in compare mode: `00:00 +9: All tests passed!`. |
| G2 | **GM-01 exactness holds without a threshold:** moving the bar value by 0.002 (under one pixel) failed all 8 goldens with `Pixel test failed, 0.00%, 4px diff detected.` The default `LocalFileComparator` is exact, so no custom comparator is needed; a tolerance must never be added (GM-01). |
| G3 | **macOS is not interchangeable:** 0 of 8 macOS goldens are byte-identical to Linux. This confirms GM-01: goldens are made and compared only on the Linux CI image, and a local `--update-goldens` on a Mac would break CI. Proposal for the real suite: run golden tests only in a Linux CI job, tagged (for example `@Tags(['golden'])`) and excluded from the macOS/Windows test jobs. |
| G4 | **Harness shape that worked:** `tester.view.physicalSize` 360×640 with `devicePixelRatio` 1.0 reset in `addTearDown`; theme, direction and `TextScaler.linear` fixed in a `MaterialApp.builder` (nothing read from the host, DS-01/VR-04); an explicit `RepaintBoundary` as the golden target; one `pumpWidget` frame for the indeterminate spinner (GM-07, no `pumpAndSettle`). Text scale 2.0 at Compact width raised no overflow for this card. |
| G5 | **Limit:** text renders in the Flutter test font, so real glyph shaping (Persian, Vazirmatn) is not covered. VR-04 already requires every golden to be regenerated once ADR-UI-003 is accepted; SP-03 must repeat G1 with the bundled font. |
| G6 | **No new dependency:** Flutter SDK only (license scan: 24 packages, 0 failing); artifacts move with the preinstalled `gh` CLI; goldens are never committed. |
