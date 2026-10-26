# Design System — BlueHesab Mini (v2: summary and pointers)

**Status:** v2 (2026-10-26). **Non-normative summary.** The design system is defined by the UI constitution (`docs/design/ui-spec/`) and the token file `design/tokens/design_tokens.json` (integrity: AX-02, checked by `tool/docs_check/docs_check.py` T1/T2). This page keeps the intent in one screen and lists the review checklist. Values are not repeated here.

## Brand attributes
Calm, reliable, precise, approachable. Personal-product simplicity with professional data clarity. No visual noise, no gamified finance imagery (spec section 1, VI rules). Blue is the primary color; semantic colors are used consistently; module accents are separate tokens.

## Token rules
Components consume semantic tokens only (VT checks; TK-13). Light and dark share token names. Spacing, radius, type scale, elevation, motion and contrast pairs are in the token file and spec section 2. A new token or color pair needs an ADR (AD-05). Contrast: 210 checks over the pairs of appendix A-4, recomputed from the tokens by `docs_check` (T2).

## Component states
Default, hover (desktop), focus-visible, pressed, disabled, loading, error, selected, unavailable — as each component's table in `docs/design/ui-spec/07-components/` defines them (CM rules). No component invents a state.

## Responsive behavior
Four window classes (Compact, Medium, Expanded, Large). Compact and Medium use the bottom bar, Expanded and Large the sidebar and top bar; dense tables reflow to lists (spec section 5, `ResponsiveList`).

## Data visualization
Direct labels, no color-only cues, a text alternative for every chart, exact values in a data table, time direction follows the reading direction (CH-01 … CH-06; chart library undecided: ADR-UI-006).

## Persian and English
Real strings (the copy catalog, section 9), mixed-direction isolation (`BidiText`), Persian digits by default with a Latin option, numeric columns aligned by `NumericCell`. Locale changes never mutate stored data (I-02). Icons that carry direction mirror; others do not (spec 2-7).

## Motion and icons
Motion is brief, purposeful and token-driven (section 4; reduced motion has three settings, RM-01). One icon family chosen by ADR-UI-005; until then only logical icon names exist. No emoji as navigation icons.

## Review checklist
- [ ] Token-only colors, spacing and durations
- [ ] Light and dark
- [ ] RTL (and LTR overflow tests)
- [ ] Compact and Expanded at least (all four before v1.0)
- [ ] Focus and keyboard
- [ ] Contrast and non-color cues
- [ ] Loading, empty and error states
- [ ] No second design system or icon family
