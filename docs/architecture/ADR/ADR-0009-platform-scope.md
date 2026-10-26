# ADR-0009: Platform scope, release order and technology baseline
- **Status:** PROPOSED (the product owner's decisions of 2026-10-25 are recorded here; acceptance by the owner turns it ACCEPTED; the framework part stays conditional on the spike)
- **Date:** 2026-10-26
- **Owner:** Lead architect
- **Approver:** Product owner

## Context and problem
The owner wants one free, open-source app on Windows, macOS, Android and iOS, with minimal human work and no paid accounts for now. ADR-0001…0006 (all PROPOSED) leave the framework, storage and sync open. The UI constitution already assumes Flutter-style cross-platform building (ADR-UI-007 spike) and four window classes. Without a recorded scope, agents will drift (web as a product, sync, store listings, iOS promises).

## Decision drivers
Fast first release; one codebase; real Persian RTL quality; local-first privacy; free distribution channels only; iOS needs a paid Apple account for any real distribution; test cost on four platforms; small team of agents.

## Options considered
1. **Build and release all four at once.** Rejected: iOS cannot be distributed without a paid account; effort multiplies.
2. **Build all four from day 1 in CI, release in two waves** — Android, Windows, macOS first; iOS when the owner buys the account; web only as a demo.
3. **Android only first, others later.** Rejected: delays desktop validation and risks Android-only assumptions in architecture.
4. **Web/PWA as the main product.** Rejected: local storage, SMS paste/share and backup behave differently and are weaker; it conflicts with the local-first privacy promise.

## Decision
1. **Targets:** Android, Windows, macOS, iOS compile and run in CI from M0. **First public release (v0.1):** Android (APK), Windows (installer), macOS (DMG). **iOS:** built and tested in CI/simulator where possible; released only after the owner buys an Apple Developer account (D3).
2. **Web:** Style Guide and MotionLab demo only (landing page on GitHub Pages). It is not a product, stores no user data and is not in the release gates (RKX-01 numeric precision still tested for the demo).
3. **Framework:** Flutter/Dart is the working choice **conditional on the spike** (ADR-UI-007 criteria: 18-digit `BigInt` money round trip, RTL, Jalali, golden stability on the fixed CI image, SQLite on all four, one native capability — Android share intent). If the spike fails, ADR-0002 is reopened before further feature work.
4. **Storage:** SQLite family through a single data layer (Drift is the candidate; SQLCipher optional, decided in ADR-0003) with forward-only migrations; schema in `DATA_MODEL.md`. No sync in v0.x (ADR-0005/0006 stay deferred); backup/restore file is the multi-device bridge.
5. **State/routing/l10n candidates (verify license, maintenance, RTL fit before adoption):** Riverpod, go_router, Flutter gen-l10n/ARB. They stay behind application-layer interfaces so replacing one does not touch domain code.
6. **Money and time:** `BigInt` minor units stored as decimal TEXT; instants UTC ISO-8601, dates `yyyy-MM-dd`, Jalali for display through one central layer (`DATA_MODEL.md`).
7. **Network:** none required for v0.1. Anything that touches the network (market data, model endpoint, update check) is optional, off by default, listed in `PRIVACY.md`, and goes through a core port with an allowlist.
8. **AI:** provider-neutral local-first layer (ADR-0004 direction, `AI_TOOL_CONTRACT.md`); the `assistant` module is not in v0.1.
9. **Distribution (free channels):** GitHub Releases + landing page for Android APK, Windows installer and macOS DMG; honest notes about SmartScreen/Gatekeeper warnings (`DISTRIBUTION_PLAN.md`); F-Droid, Iranian app markets, Google Play, Microsoft Store and App Store are later decisions.
10. **Minimum OS versions and the reference device** are decided in the spike report (Q-09); until then the UI constitution's reference-device rule (PV-01) applies.

## Reasons
Building all four in CI from day 1 exposes platform problems early at low cost, while releasing three keeps the first launch inside the free channels. Web-as-demo gives a shareable preview without compromising privacy. Treating Flutter as conditional avoids locking in before evidence, but gives agents a concrete baseline to work against.

## Consequences and trade-offs
- iOS users wait; the landing page says so plainly.
- Unsigned Windows/macOS builds show warnings until signing is solved (Q-07).
- CI needs Windows, macOS and Linux runners; cost depends on repo visibility (Q-04).
- Platform-specific code (share intent, file pickers) is isolated in `Builder-Platform` paths and behind ports.
- Dependency choices still require the license/maintenance check; candidates above are not approvals.

## Security, privacy, licensing and operational implications
No telemetry, no accounts, no cloud. Signing keys and secrets live only in repository secrets / owner's custody, never in git. Apache-2.0 (ADR-0007) constrains dependencies to permissive licenses.

## Acceptance evidence
Spike report (`docs/architecture/SPIKE_REPORT.md`, plan in `SPIKE_PLAN.md`, H5) showing: four-platform build in CI; money/RTL/Jalali/golden checks pass; SQLite open/migrate/backup on all four; Android share-intent text received; sizes and first-start times recorded on the reference device. Owner acceptance recorded in `docs/architecture/DECISIONS.md`.

## Revisit triggers
Spike failure; owner buys Apple account; a platform's store/OS policy changes; a required dependency has an incompatible license; first demand for sync or cloud features.

## Related
ADR-0001…0008, ADR-UI-007, ADR-UI-009, `MVP_SCOPE.md`, `DISTRIBUTION_PLAN.md`, OPEN_QUESTIONS Q-04, Q-07, Q-09.
