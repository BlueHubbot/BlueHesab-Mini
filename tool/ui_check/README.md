# tool/ui_check — machine checks of the UI constitution

**Owner:** Product/Contracts (Agent 1, AGR-01) · **Task:** T-003 · **Rules:** VR-01, VT-01…VT-06, MC-02, TK-08, AX-02, ADR-UI-009.

## Commands (run from the repository root)
```
dart run tool/ui_check/ui_check.dart tokens                 # MVP profile (default)
dart run tool/ui_check/ui_check.dart tokens --profile=full  # fails while the manifest exempts anything
dart run tool/ui_check/ui_check.dart gen                    # rewrite lib/design/tokens/design_tokens.g.dart
```
Exit codes: 0 pass, 1 findings, 64 usage error. Output is deterministic (VR-07 ث).

## What the `tokens` stage checks
| Rule | Check |
|---|---|
| AX-02 | UTF-8 without BOM, LF only, one final LF, keys in the order of block A-3 |
| VT-01 | every name of table A-2-a (AXT-01…AXT-13) present and nothing else; six-digit hex colours; alias targets exist; `meta.checksum` = sha256 of the file with `"checksum": ""` (prints the right value on mismatch) |
| MC-02 | `lib/design/tokens/design_tokens.g.dart` is byte-equal to a fresh generation |
| TK-08 | the dark `background` is not `#000000` |
| VT-02 | every pair of `contrast.groups` in both themes meets its group threshold; a failure carries the group ID (VTG-nn) |
| VT-03 | 210 pair checks for VTG-01…VTG-09, `count-per-theme` and the `min-*` values (two decimals) equal the computation; VTG-10 is reported apart |
| VT-04 | reported as the only exemption (`border` on surfaces) |
| VT-05 | not covered here: pixel contrast belongs to component widget tests |
| VT-06 | only groups VTG-01…VTG-10, only registered colour names |
| ADR-UI-009 | `design/mvp_manifest.json` is valid; `--profile=mvp` lists `NOT_IN_BUILD`; `--profile=full` fails on any exemption; ND-02 core destinations present |

Token checks are never reduced by the profile (ADR-UI-009 §2).

## Files
- `ui_check.dart` — command line.
- `src/tokens_stage.dart` — the stage as a pure function over bytes (tests feed broken fixtures).
- `src/token_registry.dart` — table A-2-a and the contrast groups; `test/tool/ui_check_spec_sync_test.dart` keeps it equal to the spec.
- `src/generator.dart` — the generator of `design_tokens.g.dart`.
- `src/manifest.dart` — manifest and catalogues (table 7-0, table 5-1, QT-01).
- `src/contrast.dart`, `src/sha256.dart` — WCAG ratio and SHA-256 (no dependency, CB-9).

## Tests (VR-07)
`flutter test test/tool/` — broken fixtures are made in the test from the real token file, one change each, and must fail with their rule ID; the sound file must pass.

## Not yet here
The MC rules stage (MC-01…MC-24), goldens, module matrix, the hidden-exemption comment scan (VR-03) and the full VR-05 report arrive with later tasks.
