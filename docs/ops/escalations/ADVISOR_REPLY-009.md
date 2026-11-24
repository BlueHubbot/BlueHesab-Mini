# ADVISOR_REPLY-009 — MX-08 zero non-loop count vs. RM-02 «محو»/«همان»
- Replies to: ESC-009 (on `main`; the same file is also carried by PR #56 `agent/contracts-T-040-motion-live-reduced` and PR #54 `agent/contracts-T-038-vr05-report`) · Date: 2026-11-19 · By: Advisor
- Class: D2 (spec contradiction inside one chapter; no ADR, gate, money, licence or scope)

## Decision
**A** — RM-02 wins. MX-08's "non-loop count zero, end value from the first frame" applies to «آنی» and «ایستا» rows; for «محو» and «همان» rows the count is zero *after the change ends* (AC-06).

## Why
1. RM-02 is the specific rule (the four-behaviour table) and table 4-3 column «کاهش حرکت» assigns it per row; MX-08 is a general tool description. Specific beats general.
2. MX-02 itself says «محو» has "no displacement or scale" (not "no animation"), so MX-02 and RM-02 agree; only one MX-08 sentence disagrees.
3. AC-06 already words the check as "zero active animations after the change ends (MX-08)", which is option A.
4. Merged code and tests (T-037 `resolveMotion`, PR #53 `8230989`; T-039) already follow RM-02; A needs no code change, B would rewrite the table, RM-02, code and tests.
5. B removes the reduced-motion crossfade the spec designed on purpose; no accessibility gain found to justify it.

## Actions
1. **Product/Contracts hat** — register a new erratum (next free ID, `contradiction`, low, `04 · MX-08 ↔ 04 · RM-02, MX-02, table 4-3; 11 · AC-06`, needed by: the first widget slice of a «محو» or «همان» row) in `docs/design/SPEC_ERRATA.md`, citing ESC-009 / ADVISOR_REPLY-009.
2. **Product/Contracts hat** — amend `docs/design/ui-spec/04-motion.md` MX-08's last-but-one sentence to the ESC-009 option-A wording (zero non-loop count after the change ends; end value from the first frame for «آنی»/«ایستا»; «محو» = opacity-only crossfade of `exit`; «همان» = colour/opacity only, no `dx`/`dy`/`scale`). Leave RM-02, MX-02, table 4-3 and AC-06 unchanged. Close the erratum in the same PR.
3. **Builder-UI / Tester hat** — MotionProbe tests for reduced motion (T-040, PR #56, and later MX-02 tests) assert: «آنی»/«ایستا» → `activeCount == 0` at the first frame; «محو» → `dx`/`dy`/`scale` constant at end values, only `opacity` changes, `activeCount == 0` after `exit`; «همان» → no `dx`/`dy`/`scale` change, `activeCount == 0` after the row's duration. If PR #56 already asserts a first-frame zero for a «محو»/«همان» row, change that assertion before merge.

## Follow-ups
- Lead: mark ESC-009 `Status: CLOSED` once this reply and the Action 1–2 PR are merged.
- Until then the AG-16 default (option A, as merged in T-037) stays in force.

NEEDS_OWNER: no
