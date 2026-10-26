# ADR-0002: Cross-platform UI framework
- **Status:** PROPOSED
- **Date:** 2026-10-23
- **Owner:** Lead architect
- **Approver:** Product owner

## Context
Targets: Windows, macOS, Android, iOS, Web/PWA. RTL, storage, notifications, files, accessibility and local AI matter.

## Options
Flutter; web technology wrapped for desktop/mobile; separate native clients; another cross-platform toolkit found during research.

## Proposed decision
Do not lock the framework until a time-boxed prototype tests app shell, RTL/LTR, themes, local persistence, one native capability and web build. Flutter is a leading candidate, not final approval.

## Acceptance evidence
Target builds, locale/theme checks, offline CRUD and restart, notification/file-access limits, package size, accessibility and maintainability review.

## Consequences
A small prototype delays feature coding but reduces framework reversal risk.

## Update 2026-10-26 (status stays PROPOSED until the spike report)
- **Platform scope changed by the owner (2026-10-25):** the targets are Windows, macOS, Android and iOS, built in CI from day 1; web is a Style Guide and MotionLab demo only, not a product target (ADR-0009). The "Web/PWA" target and the "web build" test in the context above therefore apply to the demo only.
- **Working choice:** Flutter, conditional on the spike. Pass criteria and time box: `docs/architecture/SPIKE_PLAN.md` (SP-01…12) and `docs/architecture/PLATFORM_MATRIX.md`. A failed criterion reopens this ADR (R-001).
- **Constraints the framework must meet** come from the UI constitution: `BigInt` money on every target (DD-05, RKX-01), Persian RTL with Jalali dates (R-006), 18-digit amounts (ADR-UI-007), tokens generated from `design/tokens/design_tokens.json`.
