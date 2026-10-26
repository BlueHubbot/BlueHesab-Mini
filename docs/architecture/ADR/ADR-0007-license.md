# ADR-0007: Project license — Apache-2.0
- **Status:** ACCEPTED (product owner confirmed 2026-10-25; legal review still recommended before store submission)
- **Date:** 2026-10-25
- **Owner:** Lead architect
- **Approver:** Product owner

## Context and problem
The product is free and open source. The license decides which third-party code can be reused, whether the app can ship through app stores, and how forks may use the name. Candidate reference projects in `OPEN_SOURCE_AUDIT.md` are mostly GPL/AGPL (Android/Kotlin or server apps), which cannot be embedded in a Flutter app anyway.

## Decision drivers
Fast adoption and contributions; compatibility with app-store distribution (including a future iOS release); patent grant; no obligation for users or integrators to open their own code; simple dependency policy.

## Options considered
1. Apache-2.0 (permissive, explicit patent grant).
2. MIT (permissive, shorter, no patent grant).
3. GPL-3.0 / AGPL-3.0 (copyleft; allows reuse of copyleft code but conflicts with iOS App Store terms and discourages integrators).

## Decision
Apache-2.0 for all first-party code and documentation in this repository.

## Reasons
Patent grant and store compatibility outweigh the ability to copy copyleft code, which would not fit our stack anyway. Copyleft projects stay `REFERENCE_ONLY` (study behavior, re-implement with our own tests).

## Consequences and trade-offs
- Anyone may fork, including closed-source forks. Trademark is not granted: the name «BlueHesab / آبی‌حساب», logo and brand assets are excluded (Apache-2.0 §6, stated in `NOTICE`).
- Allowed dependencies: permissive licenses (Apache-2.0, MIT, BSD, ISC, OFL for fonts, etc.). Weak copyleft (LGPL/MPL) only after a recorded review of linking mode and platform constraints. GPL/AGPL: forbidden as dependency or copied code.
- Fonts, icons, models, datasets and map data have their own terms and are audited separately.
- Contributions are accepted under Apache-2.0 (`CONTRIBUTING.md`).

## Security, privacy, licensing and operational implications
Every dependency needs a recorded SPDX id, license file URL and check date. A generated third-party license inventory must ship with each release. This ADR is not legal advice.

## Evidence and links
`LICENSE`, `NOTICE`, `docs/research/OPEN_SOURCE_AUDIT.md`.

## Revisit triggers
A needed dependency is copyleft-only; a legal review rejects a dependency; the owner decides to change the distribution model.

## Related
Requirements: PRIV-002; ADR-0008.
