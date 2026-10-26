# AUTONOMY_AND_ESCALATION — Who decides what, and how questions travel

**Status:** PROPOSED (core accepted via ADR-0008; scheduling parts PENDING Q-03) · **Owner:** Lead · **Date:** 2026-10-26
**Depends on:** ADR-0008, `AGENTS.md`, `AGENT_OPERATING_MODEL.md`, `RUNBOOK.md`, UI spec §13 (AG-01…AG-16, AGR, AGX, TCF) and §14 (gates).

## خلاصه‌ی فارسی
- فقط **Lead** با شما حرف می‌زند. بقیه‌ی نقش‌ها «کلاه» هستند و نوبتی (یکی‌یکی) کار می‌کنند.
- **مشاور (من)** فقط در دروازه‌ها و ابهام‌ها وارد می‌شود؛ سؤال و پاسخ فایل‌های کوتاه در git هستند (`ESC-NNN.md` ← `ADVISOR_REPLY-NNN.md`).
- هر تصمیم یکی از چهار رده است: D0 (خود ایجنت)، D1 (Lead)، D2 (مشاور)، D3 (شما). فهرست D3 کوتاه و ثابت است: پذیرش ADR، دروازه‌های GTX-01 و GTX-06، حساب/پرداخت فروشگاه، حقوقی و مجوز، رفتار پول واقعی، انتشار عمومی.
- اعتماد پله‌پله زیاد می‌شود (L0→L3) و با معیار اندازه‌گیری‌شده؛ نه با حس.
- قطع‌کننده‌ها (circuit breaker) جلوی حلقه، خرج بی‌حساب و کار خارج از مخزن را می‌گیرند.
- بیدارشدن خودکار مشاور هنوز **راستی‌آزمایی نشده** (Q-03)؛ روش آزمایش در §8 است.

## 1. Roles as hats
One session wears one hat at a time with its own prompt and path boundaries. Spec "Agent N" names (AGR-01…05) remain valid inside code and reports; this table maps them.

| Hat | Responsibility | Spec Agent | Writes (paths) | Never |
|---|---|---|---|---|
| **Lead / Orchestrator** | Only contact with the owner. Plans, writes task packets, keeps `STATUS.md`, routes ESC files, merges only through Integrator rules. | — | `docs/ops/**`, `docs/agents/tasks/**`, the owner-decision log in `docs/architecture/DECISIONS.md` (append rows only) | write feature code; talk to the owner about anything outside escalation triggers |
| **Architect** | ADR drafts, contracts (`DATA_MODEL`, `MODULE_CONTRACT`, …), spikes design. | 1 (ADR part) | `docs/architecture/**` | accept own ADR (owner does) |
| **Product / Contracts** | Owns the UI constitution and tooling; answers AGX requests with accepted / rejected / alternative (AG-16); keeps `tool/ui_check`. | 1 | `docs/design/**`, `design/**`, `tool/ui_check/**` | approve own work without a VR-05 record (AGR-01) |
| **Builder-UI** | Shell, home, settings, module pages. | 2 (4 later) | `lib/app/**`, `lib/features/<owned>/**` | change tokens/shared components (AG-05) |
| **Builder-Domain** | Money, accounts, transactions, budget, reports, QuickAdd finance forms, capture parser, persistence. | 3 | `lib/core/**`, `lib/features/accounting|budget|reports/**`, `assets/capture/**` | use `double` for money; read UI internals |
| **Builder-Platform** | Android/Windows/macOS/iOS glue: share intent, file pickers, signing, CI, packaging. | 2/5 | `android/`, `windows/`, `macos/`, `ios/`, `web/`, `.github/**`, `tool/ci/**`, `tool/release/**`, root build files (`pubspec.yaml`, `analysis_options.yaml`) | touch secrets; publish releases (D3) |
| **Tester / Debugger** | Integration tests, module matrix, fixtures, performance profile, reproduces bugs, writes failing tests first. | 5 | `test/**`, `integration_test/**`, `lib/fixtures/**` | change production code to make tests pass (AGR-05) |
| **Security & License** | Dependency/license audit, privacy review, secret scan, threat notes. | — | `docs/research/**`, `docs/security/**` | approve a dependency without recorded license + maintenance check |
| **Docs & Bridge** | Digests, README, landing, changelog; relays between Lead, Advisor and owner through files. | — | `docs/**` (non-contract), `site/**`, `tool/docs_check/**` | edit contracts or spec; loosen a check so that a document passes (the checker changes only with its self-test green and a fresh-session review) |
| **Integrator** | Merges approved PRs, resolves conflicts per plan, tags only after D3 approval. | — | git operations on `main` via PR merge | force-push; rewrite others' work |

Rules: **author ≠ reviewer** (a fresh session with the Reviewer prompt, never the author's session); one builder active at a time; one branch/worktree per task (`agent/<role>-<task-id>-<slug>`). A task packet may narrow a hat's paths or add scope-specific ones (for example `spike/**` and `lib/main.dart` in M0), but it never grants paths that another hat owns exclusively (`docs/design/**`, `design/**`, contracts) or secrets.

## 2. Decision classes
| Class | Who decides | Examples | Recorded in |
|---|---|---|---|
| **D0** | The working agent | naming inside its files, test structure, refactor within its task, choosing among tools listed in its task packet | commit message / handoff |
| **D1** | Lead | task order, splitting packets, merging reviewed PRs, which fixture set to use, scope tweaks inside MVP_SCOPE | `STATUS.md`, `AGENT_LOG.md` |
| **D2** | Advisor (via ESC) | ADR content correctness, contract changes (data model, money, module boundary, AI tools), spec contradictions or missing IDs, security/privacy design, dependency with doubtful license, second opinion after 2 failed attempts | `ADVISOR_REPLY-NNN.md` |
| **D3** | Product owner | accept an ADR; pass GTX-01 and GTX-06; store/developer accounts and any payment; legal/licensing; behavior touching real money; any public release or repo visibility change; enabling network sync or cloud AI; MVP scope changes; spending beyond the budget cap | `docs/architecture/DECISIONS.md` + `STATUS.md` |

Any D3 item arrives as a one-screen message from the Lead (§5), never as a long document.

## 3. Escalation protocol (git as the bus)
1. **Trigger (any):** spec contradiction or missing rule ID (AG-08); needs a new token/component/rule (AGX-01…05) that Product/Contracts cannot decide alone; ADR needed; security/license doubt; real-money behavior; store accounts/payments; a gate is reached; the same task failed twice with different approaches; a circuit breaker fired (§7).
2. **File:** `docs/ops/escalations/ESC-NNN.md` (next number; never reuse). One page.
```markdown
# ESC-NNN — <short title>
- Opened: YYYY-MM-DD · By: <hat>/<task id> · Class: D2|D3 · Blocking: yes|no (what is blocked)
## Question
<one or two sentences>
## Context (links only; no pasted spec)
<rule IDs, file paths, commit/PR>
## Options
A) … (cost, risk)  B) … (cost, risk)
## Recommendation
<option and one reason>
## What happens if no answer
<conservative default per AG-16 and for how long it is safe>
```
3. **Reply:** `docs/ops/escalations/ADVISOR_REPLY-NNN.md`: `Decision` (A/B/other), `Why` (≤ 5 lines), `Actions` (files to change, owner hat), `Follow-ups`. D3 items get the Advisor's recommendation plus `NEEDS_OWNER: yes`.
4. **Close:** Lead sets `Status: CLOSED` at the top of the ESC file, applies actions as new tasks, logs one line in `AGENT_LOG.md`. Open escalations are listed in `STATUS.md`.
5. **While waiting:** work continues on tasks that do not depend on the answer; dependent work uses the conservative default (AG-16). Maximum open blocking ESC files: 2 (otherwise Lead re-plans).

## 4. Human gates (never automated)
Accept any ADR · GTX-01 (token/design baseline) and GTX-06 (release gate) · create or pay for store/developer accounts, signing identities · legal text, licenses, trademarks · anything that moves real money or handles real bank data · making the repo public, tagging a release, publishing builds · enabling any network sync or cloud AI · changing MVP scope · raising the spending cap.
All other gates (GTX-02…05, per-page DN-04, module DN-05) are decided by Lead with a recorded independent review; the Advisor reviews them at the milestone level (M2, M3), not per page.

## 5. Bridge: Lead ↔ owner
- **Channel (MVP):** the Lead session's chat in the Claude desktop app or the project chat; mobile GitHub app for PR comments is an alternative. A chat bot channel is optional later (Q-11).
- **Message size:** ≤ 10 lines, Persian. Fixed shape:
```
وضعیت: <یک خط>
انجام شد: <≤3 مورد>
بعدی: <≤3 مورد>
از شما می‌خواهم: <حداکثر یک تصمیم، با گزینه‌ها و پیشنهاد من، یا «چیزی نیست»>
```
- The owner answers with ✅, ❌, a choice letter or one sentence. The Lead records it in `docs/architecture/DECISIONS.md` (date, decision, source) before acting.
- Cadence: after each milestone slice (M0…M3 parts) or when a D3 item exists. No daily noise.
- The owner can say "بخوان" to any session to make it read `STATUS.md` and continue.

## 6. Autonomy ladder (trust earned by numbers)
| Level | Rule | Promotion criteria (all) |
|---|---|---|
| **L0** (start) | Every PR reviewed by a fresh frontier session; Advisor sees every ADR and contract diff. | — |
| **L1** | Advisor only at ADRs, contract changes, gates and ESC. Routine PRs reviewed by a fresh session (any model). | 10 consecutive merged PRs with 0 reverts; 0 escaped money/RTL defects; CI green on `main` |
| **L2** | Local-model builders allowed on routine tasks (UI wiring, tests, fixtures) after benchmark pass (H3); frontier review kept for domain/money code. | local model passes the agreed task benchmark (≥ 80 % first-pass acceptance, 0 spec violations in sample) |
| **L3** | Lead may self-merge docs-only and test-only PRs; everything else as L2. | 30 days at L2 with revert rate < 5 % and no breaker trips |
Demotion: one escaped money-correctness defect, a secret/private-data leak, or a breaker trip caused by process failure ⇒ back one level and an ESC post-mortem.

## 7. Circuit breakers (stop, don't loop)
| ID | Trigger | Action |
|---|---|---|
| CB-1 | Same test/task fails after 3 attempts | Stop; write ESC with logs; do not try a 4th variant (a second opinion may be requested after the 2nd failure, §3) |
| CB-2 | Task exceeds its packet's time/token budget by 50 % | Stop; Lead re-splits or escalates |
| CB-3 | Unexpected root, branch, dirty tree, or files outside allowed paths changed | Stop; report; do not clean automatically |
| CB-4 | Secret, token, private key or real SMS/bank data seen in diff or logs | Stop; remove from working tree; report to Lead; if pushed ⇒ D3 incident (rotate secrets, history rewrite decision) |
| CB-5 | A command would delete, force-push, reset or touch paths outside the worktree | Do not run it; ask Lead |
| CB-6 | Contradiction between sources (AG-08) | Do not guess; ESC |
| CB-7 | Weekly/monthly spend cap reached (value set by the owner in `docs/architecture/DECISIONS.md`) | Stop non-critical work; Lead reports |
| CB-8 | Two sessions editing the same file/branch | Newer session stops; Lead assigns one owner (conflict protocol) |
| CB-9 | Generated code adds a dependency without audit entry | CI fails; Security hat reviews |

## 8. Scheduled automation of the Advisor (verification plan for Q-03)
Goal: the Advisor wakes up without the owner typing anything, answers open ESC files, and the Lead picks the reply up.
1. **Capability checks (owner or Lead, once):** a scheduled task can (a) read the GitHub repo, (b) create/switch branch, (c) write files, (d) push a branch or open a PR, (e) notify the owner's phone. Confirm each with a dry run.
2. **Dry run (ESC-000):** Lead commits `ESC-000.md` ("test: reply with the current date and the ID list in the open-questions file"). Scheduled task fires, creates branch `claude/advisor-reply-000`, writes `ADVISOR_REPLY-000.md`, pushes, notifies. Success = file exists with correct content and no change outside `docs/ops/escalations/`.
3. **Task prompt (fresh session each time, so it must be self-contained):** read `AGENTS.md` and `docs/ops/STATUS.md`; list ESC files without a reply; for each, read only the cited IDs; write `ADVISOR_REPLY-NNN.md` in the format of §3; touch no other path; push to `claude/advisor-reply-NNN` (cloud scheduled runs push `claude/`-prefixed branches); if there is nothing to answer, stop silently.
4. **Schedule:** start with twice a day (e.g. 09:07 and 17:43 Asia/Dubai) while the project is active; after M1 move to "on demand" if the Lead can trigger it; avoid minute 0 to spread load.
5. **Safety:** the scheduled task has repo-only access, no secrets, replies never auto-merged; Lead reads and applies. D3 replies still wait for the owner. Approval mode of scheduled runs: if runs stop for approvals, the owner enables automatic approval for this task only, with the path restriction in the prompt.
6. **Fallback:** if any check fails, the owner sends one word ("بخوان") to the Advisor chat when STATUS shows an open blocking ESC; STATUS prints that need explicitly.
7. **Result recorded in** `OPEN_QUESTIONS.md` Q-03 and ADR-0008 (PENDING → verified).

## 9. Quality and reporting hooks
- Handoff template at the end of every task (`HANDOFF_TEMPLATE.md`): done, files changed, tests run with pasted results, risks, open questions (rule IDs), next suggestion.
- `STATUS.md` (Lead only): current milestone, task states (vocabulary in `AGENT_OPERATING_MODEL.md`), open ESC files, last gate, autonomy level, next action, spend vs cap.
- `AGENT_LOG.md`: one line per finished task or decision.
- Weekly Docs & Bridge hat posts a short `docs/ops/weekly/YYYY-WW.md` only if the owner asks (avoid noise).
- Metrics (collected from git/CI by the Lead): PR lead time, revert rate, CI pass rate on first push, escalations per week, escaped defects.

## 10. Open questions
Q-03 (automatic wake-up), Q-11 (owner notification channel beyond chat), Q-12 (spending cap value and period), Q-13 (who reviews when the Advisor is unavailable — default: pause D2 items, continue others). Local model details wait for `LOCAL_MODEL_SETUP.md` (H3, Q-01/Q-02).
