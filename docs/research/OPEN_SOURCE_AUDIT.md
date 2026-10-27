# Open-Source Audit — Candidate Register (v2, 2026-10-26)

**Status:** not a legal opinion. A candidate is not an approved dependency. «تأییدشده» = read from the official page in this audit (date and source given). «حافظه» = from memory, **must be verified** before adoption (H1 rule: unverified licenses never enter `pubspec.yaml`). Policy: ADR-0007 (Apache-2.0): permissive deps allowed (Apache-2.0, MIT, BSD, ISC, OFL fonts); LGPL/MPL only after review; GPL/AGPL never as dependency or copied code.

## Rubric (per adoption)
Canonical repo · checked date · version/commit · release activity · exact SPDX file · transitive, model and asset licenses · platforms/offline behavior · integration model · security/privacy · size/performance · decision · owner · reviewer. Record in the table below and in the PR that adds the dependency.

## A. Verified in this audit
| Candidate | Use | Finding | Source | Decision |
|---|---|---|---|---|
| drift (pub.dev) | SQLite layer | MIT; v2.35.3 published 2026-10-23; platforms Android, iOS, Linux, macOS, Web, Windows; verified publisher simonbinder.eu | pub.dev/packages/drift (read 2026-10-26) | PROTOTYPE → ADOPT after spike (ADR-0003) |
| shamsi_date (pub.dev) | Jalali conversion | BSD-3-Clause (detected by pub scorer); v1.0.2; all 6 platforms; 140/140 pub points | pub-web.flutter-io.cn mirror score page (read 2026-10-26) | PROTOTYPE: must pass DT-05 vectors (ADR-UI-004); wrap behind the central date layer |
| Vazirmatn font | Persian UI font | SIL OFL 1.1 (`OFL.txt`); built on DejaVu Sans (public domain); main build merges Roboto for Latin glyphs, a Non-Latin build exists | jsDelivr README v32.0.0 (read 2026-10-26) | PROTOTYPE: ship Non-Latin or Latin-merged build per size test; keep `OFL.txt` in assets/licenses; do not sell the font alone or rename rules per OFL (re-read OFL.txt) |
| Flutter SDK 3.47.8 (git tag, commit `737ba8f8…`) | UI framework, SDK packages (`flutter`, `flutter_test`, `sky_engine` and their Dart-team transitive packages) | BSD-3-Clause (`LICENSE` at the tag: "Copyright 2014 The Flutter Authors"); `sky_engine` carries the engine's aggregated third-party notices, listed by the CI scan as `SDK_NOTICES`; transitive packages are classified on every PR by `tool/ci/license_scan.py` | github.com/flutter/flutter `LICENSE` at refs/tags/3.47.8 (read 2026-10-26, T-001) | PROTOTYPE (spike, ADR-0009 §3); Security & License hat to review this row |
| Google Play SMS policy | Capture design | Apps on Play needing sensitive SMS/call-log data generally must be the user's **default handler** (e.g. default SMS app before requesting `READ_SMS`), unless an exception in the Play Console policy applies | developer.android.com default-handlers (read 2026-10-26) | Confirms MVP choice: **no SMS permission**, paste/share only (CAPTURE_PIPELINE §6) |

## B. From memory — verify before any use
| Candidate | Intended use | Stance | Believed license (verify) | Must verify |
|---|---|---|---|---|
| Flutter SDK | UI | PROTOTYPE (spike) | BSD-3-Clause (license verified, see §A) | platform builds, Windows/macOS accessibility, RTL, golden stability |
| Riverpod, go_router, flutter_localizations | state, routing, l10n | CANDIDATE | MIT/BSD (Flutter team for go_router) | maintenance, RTL, version pins |
| Lucide icons | icon set | CANDIDATE (ADR-UI-005) | ISC | exact package, glyph coverage |
| Actual Budget | finance behavior reference | REFERENCE_ONLY | MIT | read-only study; sync model not used |
| llama.cpp | local inference / OpenAI-compatible server | PROTOTYPE | MIT | model licenses separately; Windows/macOS/Android builds |
| whisper.cpp | speech to text | PROTOTYPE | MIT | model terms, Persian accuracy, latency |
| PaddleOCR | receipt OCR | PROTOTYPE | Apache-2.0 | model licenses, Persian accuracy, package size |
| Tesseract (fas) | OCR alternative | PROTOTYPE | Apache-2.0 | `fas` trained data quality |
| vLLM | H200 serving | PROTOTYPE | Apache-2.0 | version supports chosen model; tool calling parser |
| Ollama | companion service | PROTOTYPE (desktop/server) | MIT | not an embedded mobile runtime |
| SignPath Foundation | free Windows code signing for OSS | RESEARCH (Q-07) | service | eligibility terms (page could not be fetched in this audit) |
| Frappe Books | accounting reference | REFERENCE_ONLY | AGPL-3.0 (per pack note) | reverify; never copy |
| Firefly III | finance reference | REFERENCE_ONLY | AGPL-3.0 | reverify |
| Ghostfolio | investments reference | REFERENCE_ONLY | AGPL-3.0 | reverify |
| Loop Habit Tracker, Tasks.org, Fossify Calendar, OpenTracks, Gadgetbridge, wger, Khoj, Vikunja, Weblate | module references | REFERENCE_ONLY | GPL/AGPL family | reverify per module start; study behavior only |
| Organic Maps | maps reference | REFERENCE_ONLY | Apache-2.0 (pack note) | assets/data terms |
| Hazm | Persian NLP | NOT FOR MOBILE | — | Python; consider only offline tooling |
| OpenHands, Open WebUI | agent / UI reference | REFERENCE_ONLY | verify (Open WebUI has branding terms) | not used in the product |

## C. Rules for agents
1. A PR that adds a dependency must add its row here (checked date, SPDX, transitive scan result) — CB-9.
2. Run a license scan of the lockfile in CI (candidate: `dart pub deps` + a license-list script); unknown or copyleft ⇒ fail.
3. Models, fonts, icons, datasets are dependencies too.
4. «REFERENCE_ONLY» code is never pasted; behavior is re-implemented from our own spec and tests.
5. Re-verify the table at each minor release and when a candidate changes major version.

## D. Open items
H1-1: verify section B items one by one when each is first needed (owner: Security & License hat). H1-2: SignPath eligibility and macOS options (Q-07). H1-3: Organic Maps/others only at module start.
