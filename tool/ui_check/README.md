# tool/ui_check — machine checks of the UI constitution

**Owner:** Product/Contracts (Agent 1, AGR-01) · **Tasks:** T-003 (tokens), T-016 (rules) · **Rules:** VR-01, VR-03, VT-01…VT-06, MC-01…MC-17, MC-23, MC-24, TK-08, AX-02, ADR-UI-009.

## Commands (run from the repository root)
```
dart run tool/ui_check/ui_check.dart                        # all stages: tokens + rules (VR-01)
dart run tool/ui_check/ui_check.dart rules                  # MC rows over lib/ (T-016)
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

## What the `rules` stage checks (T-016)
Only `lib/**.dart` (MC-24). A small lexer (`src/dart_lexer.dart`) blanks comments and string bodies, so code patterns never match inside them; string rows look only inside literals; VR-03 looks only inside comments. One line per violation: `<ID> <path>:<line> <message>`.

| Rule | Pattern (table 11-2-a) | Allowed in (as matched) |
|---|---|---|
| MC-01 | `Color(0x`, `Colors.`/`CupertinoColors.`, `Color.fromRGBO/ARGB`, 6/8-digit `0x` numbers, `#RRGGBB(AA)` in strings | `lib/design/tokens/design_tokens.g.dart`; plus `lib/design/tokens/theme_derivation.dart` and `contrast_guard.dart` (SE-14), which still fail on `Color(`, `Colors.`, `Color.from…` and any `package:flutter/` import |
| MC-03 | `.colorScheme`, `Theme.of(…).…Color` | nothing yet: the ThemeData file is named by ADR-UI-007 |
| MC-05 | `BoxShadow(`, `Shadow(`, `elevation:`, `BackdropFilter(`, `ImageFilter.blur`, `Linear/Radial/SweepGradient(` | the generated token file |
| MC-07 | `TextStyle(` with a top-level `fontSize:` | the generated token file (type roles) |
| MC-08 | `Duration(milliseconds:`, `Curves.`, `AnimationController(`, `AnimatedContainer/Size/Positioned(`, `TweenAnimationBuilder(`, `Hero(`, `Lottie…`, `Rive…`, `package:lottie/` and `package:rive/` imports | any path with a segment `app_motion/` (D0: location not chosen yet); plus the generated token file (SE-14) |
| MC-09 | `Platform.is…`, `Platform.operatingSystem`, `defaultTargetPlatform` | `platform_adapter*.dart` or a `platform_adapter/` folder |
| MC-10 | `PulseDot(` | `pulse_dot.dart`, `brand_mark.dart`, `quick_add_button.dart`, `assistant_page.dart`, `ai_action_card.dart` |
| MC-11 | `AppBadge(` | forbidden only in `chip`, `list_row`, `page_header`, `bottom_nav`, `summary_card` (`.dart`, optional `app_` prefix) |
| MC-13 | `EdgeInsets.only(left/right:`, `EdgeInsets.fromLTRB(`, `Positioned(left/right:`, `BorderRadius.only(topLeft…:`, `BorderRadius.horizontal(left/right:` (top-level arguments) | `numeric_cell.dart` |
| MC-14 | U+2066, U+2068, U+2069, U+200E, U+200F in strings, raw or as `\u` escapes | `bidi_text.dart`, `numeric_cell.dart`, `*formatter.dart` |
| MC-15 | `TextAlign.left/right`, `Alignment.centerLeft/Right` | same as MC-14 |
| MC-16 | `Bidi.detectRtlDirectionality`, `estimateDirectionOfText`, `isRtlLanguage`, `TextDirection.values.byName(` | nowhere |
| MC-17 | U+0600–U+06FF, U+FB50–U+FDFF, U+FE70–U+FEFF in strings, raw or as `\u` escapes | `style_guide/` folders, `copy_catalog.g.dart` |
| VR-03 | a comment `ui_check: ignore/disable/off/skip/allow/exempt …`, or `ignore/disable/nolint/noqa/exempt … MC-nn/VT-nn` | nowhere |

File names for files that do not exist yet are the narrowest reading of the column; each list is one constant in `src/rules_stage.dart`, changed only with Agent 1 approval (VR-03).

Not covered (printed as `UNCOVERED`; `--profile=full` fails, MC-23): MC-04, MC-12 (component files and golden review), MC-06, MC-18, MC-19 (lint rows: need `package:analyzer`, no audit row yet), MC-20 (no chart library, ADR-UI-006), MC-21 (copy catalog), MC-22 (Style Guide). MC-02 is in the `tokens` stage.

Known result on `main`: after SE-14 (ESC-003 → ADVISOR_REPLY-003) amended the MC-01 and MC-08 "allowed in" cells, `rules` is clean on `lib/` (the tool test asserts it, exit 0), so the stage can become a blocking CI step (VR-02; Builder-Platform, ADVISOR_REPLY-003 Action 4).

Fixtures (MC-23): `fixtures/<id>.bad.dart.txt` and `<id>.good.dart.txt` per covered row; the first line `// fixture-path: lib/…` is the path the rule sees (`.txt`, so `flutter analyze` skips them).

## Files
- `ui_check.dart` — command line.
- `src/tokens_stage.dart` — the stage as a pure function over bytes (tests feed broken fixtures).
- `src/token_registry.dart` — table A-2-a and the contrast groups; `test/tool/ui_check_spec_sync_test.dart` keeps it equal to the spec.
- `src/generator.dart` — the generator of `design_tokens.g.dart`.
- `src/manifest.dart` — manifest and catalogues (table 7-0, table 5-1, QT-01).
- `src/contrast.dart`, `src/sha256.dart` — WCAG ratio and SHA-256 (no dependency, CB-9).
- `src/rules_stage.dart`, `src/dart_lexer.dart` — the `rules` stage and its lexer (T-016).
- `fixtures/` — broken and sound sample per covered MC row (MC-23).

## Tests (VR-07)
`flutter test test/tool/` — broken fixtures are made in the test from the real token file, one change each, and must fail with their rule ID; the sound file must pass. `test/tool/ui_check_rules_test.dart` does the same for every file in `fixtures/` and tests the lexer.

## Not yet here
The uncovered MC rows above, goldens, module matrix and the full VR-05 report arrive with later tasks.
