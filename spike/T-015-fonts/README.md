# spike/T-015-fonts — SP-03 font evaluation (Vazirmatn)

Answers SP-03 and the UI spec §3-1 evaluation table for Vazirmatn (ESC-001 decision A, ADVISOR_REPLY-001; ADR-UI-011 §6). Evidence, not product (spike/README.md).

- **No font file in git.** `tool/fetch_font.py` downloads the pinned upstream release (`tool/font_pin.json`: tag, asset, SHA-256) into `build/fonts/` (git-ignored) at test time. CI job `no font file in git` fails on any tracked `*.ttf|*.otf|*.woff*`.
- **Table facts** (`tool/font_report.py`, stdlib): coverage from `cmap`, weights from `fvar`, tabular digits from `hmtx` + GSUB `tnum`, Latin/Persian digit ink height from `glyf`, `hhea`/`OS/2` metrics against every `typography.scale` token, file sizes.
- **Rendering facts** (`flutter test`, Linux/macOS/Windows): natural ascent + descent vs token line height, digit widths, LTR number inside RTL text, Persian digits typed into a number field → exact `BigInt`, toy amount card at text scale 1.0/1.3/2.0 (TY-05), specimen PNG artifact per OS.

Run locally (needs network to GitHub):

```
python3 -I tool/fetch_font.py --pin tool/font_pin.json --out build/fonts
python3 -I tool/font_report.py --fonts build/fonts --tokens ../../design/tokens/design_tokens.json
flutter test
```

## Findings (CI, 2026-11-02, Vazirmatn v33.003, Flutter 3.47.8)
Source: release `v33.003` (`vazirmatn-v33.003.zip`, 13 047 191 bytes, SHA-256 `0a9afd41…54fdb`, published 2022-06-22, still the latest). Files: `fonts/variable/Vazirmatn[wght].ttf`, `misc/Non-Latin/fonts/variable/Vazirmatn-NL[wght].ttf`, `fonts/ttf/Vazirmatn-{Regular,Medium,SemiBold,Bold}.ttf`.

| §3-1 row | Result | Evidence |
|---|---|---|
| Licence | PASS (already verified) | OFL-1.1, audit §A; `OFL.txt` goes to `third_party/licenses/` only after ADR-UI-003 |
| Coverage | **PASS** in every build | cmap: پ چ ژ گ، ی/ک فارسی، ZWNJ، U+06F0–U+06F9، `، ؛ ؟ « » ٪ ٫ ٬ −` all mapped (variable, Non-Latin, 4 statics) |
| Weights | **PASS** | variable `wght` 100–900 (default 400); statics 400/500/600/700 present |
| Tabular digits | **PASS with a condition** | Persian digits are **proportional by default** (hmtx advances 591…1349 units; Flutter widths 4.62…10.54 px at `body`; two amounts of equal length do not align). With the `tnum` feature (GSUB has it) all ten are 10.54 px and the unit column aligns, on Linux, macOS and Windows. Latin digits are tabular by design (1151 units). ⇒ every amount style must set `FontFeature.tabularFigures()` |
| Vertical metrics | **PASS on ink, with a caution** | Font line box (hhea = typo, `USE_TYPO_METRICS`): ascent 2100 + descent 1100 per 2048 em = **1.5625 × size**. That exceeds the token line for `title-sm` (31.25/30), `title` (37.5/34), `heading` (50/44), `display` (68.75/58); it fits the other four. The ink of the §3-1 sample (glyf bbox of nominal forms, +1629/−691 units Regular, +1671 Bold) is at most 1.13 × size (`display` 49.8–50.8 px ≤ 58) and fits **every** token. Flutter applies the token line exactly (`box` = token line on all three OSes) with the default `TextHeightBehavior` (TY-04), so nothing is cut in an unclipped box. Risk (RKX-04): any widget that clips to the line box, or a change to `leadingDistribution`, can cut dots on the four large tokens |
| Latin pairing | **REVIEW** (number given, judgement for the ADR) | ink height Persian digits 1–9 median / Latin digits median = 0.905 (Regular) … 0.926 (Bold): Persian digits ≈ 9 % shorter. Non-Latin build has no Latin digits (pairing then depends on the Latin font, ADR-UI-011 §6) |
| Size | recorded | variable (Latin-merged) 241 328 B; Non-Latin variable 114 500 B; 4 statics 491 364 B in total. One variable file is the smallest way to get 400–700 |

SP-03 behaviours (all PASS on Linux, macOS, Windows; `flutter test` 11/11):
- Persian digits typed into a number field (`TextInputType.number`) arrive unchanged and parse to the exact `BigInt`, 18 digits included.
- An LTR number inside RTL text keeps left-to-right order, both ASCII `98,765` and Persian `۹۸٬۷۶۵` (one LTR box per character, increasing x).
- Toy amount card at text scale 1.0 / 1.3 / 2.0: no overflow, no ellipsis, no `maxLines`; height 56 / 117 / 180 px in 360 px width (TY-05).
- Specimen PNG per OS: CI artifacts `t015-specimen-<os>` (for a human look; not a golden).

For ADR-UI-003 (Architect, then owner):
1. Build: variable Latin-merged (241 KB, one file, Latin digits included) vs Non-Latin variable (115 KB) + a separate Latin font per ADR-UI-011 §6.
2. Amount styles must enable `tnum`; add a check (ui_check or a widget test) once fonts land.
3. Decide whether the four large tokens keep their line heights (ink fits) or follow the font box; forbid clipping to the line box for amounts.
4. Still open: Android/iOS rendering and a look on 2 real devices (Q-09); contextual forms with diacritics (nominal forms were measured); Alexandria and the Latin fonts need audit rows first.
