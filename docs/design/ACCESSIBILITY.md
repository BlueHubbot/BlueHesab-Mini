# Accessibility Requirements (v2)

**Status:** v2 (2026-10-26). The normative rules are in the UI constitution (component rules CM-05 and the per-component Semantics rows, section 7; tests in section 11: contrast checks VT-*, overflow tests GMX-03, manual tests AMT-01…AMT-09). This page is the checklist an agent or reviewer reads first. Target: WCAG 2.2 AA where it applies to a native/Flutter UI, plus platform conventions.

## Requirements
- Every control has an accessible name and role; focus order is logical and visible (CM-05, AQ-02).
- Keyboard users can complete the core desktop flows: record, edit, delete with undo, backup (AMT-03).
- Text scaling to the largest system size never clips or overlaps essential content (AMT-05, TY-05, CM-07; overflow tests at scales 1.0 and 2.0 under the MVP profile).
- Contrast for text, controls, focus ring and semantic states is checked in both themes: 210 checks recomputed from the tokens (`docs_check` T2, spec appendix A-4).
- Color is never the only status cue (CM-11).
- Reduced motion has three settings (follow system, on, off) and every animation has a reduced variant (RM-01…RM-02, AMT-06).
- Form errors and help text are tied to their fields and announced (field rules, section 7).
- Charts always have a text alternative and an exact-value table (CH-01…CH-06).
- Money, dates and mixed-direction text are read correctly by screen readers (Semantics rows, BidiText).
- Screen-reader labels are tested in Persian with TalkBack on the reference Android phone (AMT-01); VoiceOver (AMT-02) joins when iOS is released. English labels are tested from v0.3.
- Manual review supplements automation; it does not replace it. Manual rows use the recording template in `docs/TEST_STRATEGY.md` §5.

## MVP profile (ADR-UI-009)
v0.1 runs AMT-01, AMT-03, AMT-05, AMT-06 and the direction form of AMT-07; AMT-02, AMT-04, AMT-08 are `NOT_IN_BUILD`; AMT-09 as applicable. Nothing above is weakened: the profile only decides which manual rows apply.
