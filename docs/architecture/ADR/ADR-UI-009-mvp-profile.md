# ADR-UI-009: MVP profile for the UI constitution (lighter gates, same guarantees)
- **Status:** ACCEPTED (product owner accepted the concrete parameters below on 2026-10-26, Q-15, AD-02)
- **Date:** 2026-10-26
- **Owner:** Product/Contracts (Agent 1 role) — drafted by Lead architect
- **Approver:** Product owner

## Context (زمینه)
The UI spec (about 940 identified rules and table rows, 24 machine-check rules, 210 contrast checks, golden matrices GMX-01…04, gates GTX-01…06, user tests UT-01…04, manual accessibility tests AMT-01…09) is written for the finished product with ten destinations. v0.1 builds a small subset (`MVP_SCOPE.md`). Running the full matrix on every component and page would multiply cost and time with little added safety for components that are not even built. At the same time, money, RTL, accessibility and "no trace of disabled modules" must never be weakened. A silent skip would violate VR-03 ("no hidden exemption").

## Options (گزینه‌ها)
1. Apply the full constitution to the MVP. Safe, but slow and expensive for a free project with token limits.
2. Ignore parts informally. Rejected: violates VR-03 and AG-08.
3. **A declared, machine-readable MVP profile** with a build manifest; every reduction is explicit, versioned, reported at each gate and reversed by a defined trigger.

## Decision criteria (معیار تصمیم)
No weakening of safety-critical guarantees; every exemption visible in the gate report; mechanical enforcement (no comments or ad-hoc ignore lists); simple switch back to the full profile.

## Decision (تصمیم)
### 1. Mechanism
- `design/mvp_manifest.json` lists what exists in the build: `components[]` (7-0 ids), `destinations[]` (`home, accounting, reports, settings, budget`), `pages[]`, `quickAddTypes[]` (`expense, income, transfer`), `profile: "mvp"`.
- `dart run tool/ui_check/ui_check.dart --profile=mvp` (default until superseded) reads the manifest. Rows for items not in the manifest are reported as `NOT_IN_BUILD` (neither pass nor fail) and listed in the VR-05 report. Items in the manifest get **full** checks except where §3 reduces them explicitly. `--profile=full` ignores the manifest exemptions.
- Every VR-05 gate report states the profile, the manifest hash and the list of `NOT_IN_BUILD` and reduced rows. Changing `profile` or the manifest's exemptions requires an ADR change (this one), not a comment (VR-03).

### 2. Never reduced (non-negotiable at any profile)
Token-only styling and all VT checks (VT-01…VT-06, 210 contrast checks, `checksum` AX-02); all 24 machine-check rules (MC) for files in the build; money rules (MN-01…06, AM-01, no `double`, 18-digit round trip); RTL layout and Persian digits/copy catalog rules (CM-10, DT, NM); accessibility semantics and focus rules of built components (CM-05, AC-*); QuickAdd defaults, idempotency and undo (SD, IDP, UN); draft-confirmation rule for any automated source (AI-01 spirit); DM-01 "no trace" for modules; privacy rules (no telemetry, no raw SMS); QE-01…03 (3 taps / 3 seconds) as an automated test; GTX-01 and GTX-06 owner approval.

### 3. Reductions (what changes)
| Area | Full profile | MVP profile |
|---|---|---|
| Components (7-0) | all rows green at GTX-02 | only components in the manifest; others `NOT_IN_BUILD` (e.g. AIActionCard, Badge unless used, OfflineBanner, SyncStatus) |
| GMX-01 (component goldens) | light/dark × RTL/LTR × scale 1.0/2.0 = 8 images | light/dark × RTL × scale 1.0 = 2 images per state; LTR and scale 2.0 covered by non-image layout/overflow tests (GMX-03 style) |
| GMX-02 (assembly goldens) | 4 reference views × 2 themes + LTR = 9 images | Compact and Expanded × 2 themes (RTL) = 4 images; Medium and Large through overflow tests only |
| GMX-03 (overflow, no image) | scales 1.0/1.3/2.0 × 4 views × RTL/LTR = 24 tests | scales 1.0 and 2.0 × 4 views × RTL/LTR = 16 tests (scale 2.0 is the accessibility extreme) |
| GMX-04 + MMX (module matrix) | 14 combinations | combinations that exist in the build (`budget` off/on) plus the "absent modules leave no trace" scan (`MODULE_CONTRACT` MDC-T2); full 14 from the day a second optional module ships |
| GM-08 coverage | every table row ↔ golden | only manifest components |
| PV (performance on reference device) | all MO rows, MotionLab panels | MO rows used by built components and the QuickAdd/Home/list scenarios; p99 ≤ 16 ms rule unchanged; reference phone must be real (PV-01). If none exists yet, the gate records "reference device pending" and the first release candidate cannot be tagged until it is measured |
| UT-01…04 (user timing test) | 5 participants × 3 measurements | 3 participants × 3 measurements (owner + two volunteers); criterion unchanged (median ≤ 3 s); the automated QE-03 test is mandatory |
| AMT (manual accessibility) | AMT-01…09 | AMT-01 (TalkBack), AMT-03 (keyboard, desktop), AMT-05 (largest text), AMT-06 (reduced motion) on built screens; AMT-07 (language switch) runs as a **direction** test (RTL ↔ LTR mirror through the debug/Style Guide direction switch SGX-03, Persian strings, rules RT-01…RT-07) because English texts and the language row arrive in v0.3, and its English-text part is `NOT_IN_BUILD`; AMT-02 (iOS), AMT-04 (offline banner), AMT-08 (assistant card) `NOT_IN_BUILD`; AMT-09 as applicable |
| Gates | GTX-01…06, Advisor on contracts | GTX-01 and GTX-06 = owner + Product/Contracts; GTX-02…04 signed by Product/Contracts with a fresh-session review; GTX-05 reduced as above; GTX-06 for v0.1 is the "MVP acceptance" |
| Reviews by Advisor | per autonomy level | milestones M2 and M3 and any contract/ADR change (`AUTONOMY_AND_ESCALATION.md`) |

### 4. Interpretations bundled here (from `MVP_SCOPE.md`)
- **IN-8 (proposed new row):** a module that is not built has no descriptor, route, copy key, QuickAdd type or catalog entry; "coming soon" tiles are not shown (DM-01). The destination catalog (5-1) and `ND-02` stay authoritative for the final product.
- **TopBar without SyncStatus** in v0.1 (no sync; ADR-0005/0006). The OfflineBanner is not built because the app needs no network.
- **Budget module default ON** so the DayRing budget arc and the Home budget card exist (DM-02/04 behavior unchanged).

### 5. Return to the full profile
Switch to `--profile=full` (and re-open affected gates per GT-07) at the first of: public v1.0 release; the second optional module starts; the first non-owner beta cohort larger than 20 users; owner request. Findings accumulated under the MVP profile are not forgiven: the next full run must be green.

## Consequences (پیامدها)
Lower cost and faster M2/M3 with the dangerous areas intact. Risk: defects hiding in unexercised combinations (LTR at scale 2.0 images, Medium/Large goldens). Mitigations: overflow tests keep running in those combinations; visual drift checked by humans at milestone demos; the full run before 1.0.

## Acceptance test (آزمون پذیرش)
1. `ui_check --profile=mvp` on a fixture manifest reports the exact `NOT_IN_BUILD` set and fails if a manifest component lacks a required check.
2. Removing a component from the manifest while its code exists in `lib/` fails (no hiding built code).
3. Adding an unlisted destination/route/copy key for an unbuilt module fails the "no trace" scan.
4. `--profile=full` fails when any exemption exists.
5. VR-05 report contains profile, manifest hash and reduced rows; a gate report without them is rejected (GT-02).
6. Tool tests (VR-07) cover the manifest logic.

## Impact on the spec (اثر بر سند) — applied only after acceptance (AD-04)
5-1 / ND note and new IN-8; 5-2 TopBar note; 11-1 VR-01 (`--profile`), VR-05; 11-4 GMX-01…04 and GM-08; 11-6 PV note; 11-7 MM/MMX scope; 11-8 UT-02; 14-2 GTX rows and DN-02…06 wording; 12-1 table row ADR-UI-009. Until acceptance, the spec text governs and `AGENTS.md` says "MVP profile pending".

## Status of related decisions
ADR-UI-010 (SMS entry, provenance row, uncertainty marker in QuickAdd) is a separate ADR to be drafted by Product/Contracts before the M2 SMS task starts; see `CAPTURE_PIPELINE.md` §5 and OPEN_QUESTIONS.

## Related
`MVP_SCOPE.md`, `MODULE_CONTRACT.md` §9, `AUTONOMY_AND_ESCALATION.md`, UI spec AD-01…AD-07, VR-03, GT-02, GT-07.
