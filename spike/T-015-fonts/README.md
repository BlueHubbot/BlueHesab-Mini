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

## Findings
Filled from CI evidence (see the PR).
