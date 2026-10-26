# Implementation Roadmap — Gated Delivery (v2)

**Status:** v2 (2026-10-26). Maps the pack's phases onto the milestones of `docs/product/MVP_SCOPE.md` §6 (M0–M3) and the releases of `docs/product/MODULE_ROADMAP.md`. Order matters, calendar dates do not: a phase ends when its gate passes, not when time runs out. One builder is active at a time (ADR-0008).

| Phase | Milestone | Content | Exit gate | Main hats |
|---|---|---|---|---|
| 0 Governance | (done in documents) | `AGENTS.md`, ADRs, workflow, templates, `docs_check`, CI docs workflow, repository merge | owner accepts ADR-0009 and ADR-UI-009 (Q-15); documents merged into the repository; Q-04 answered | Lead, Docs & Bridge |
| 1 Research | M0 | license and maintenance evidence for the candidate dependencies (`docs/research/OPEN_SOURCE_AUDIT.md`) | every dependency in the spike lockfile has a recorded check; 0 copyleft (SP-11) | Security & License |
| 2 Architecture + foundation | M0 | spike (`SPIKE_PLAN.md`), `design_tokens.g.dart`, `app_motion`, `tool/ui_check`, `app_fixtures`, four-platform CI | GTX-01 (owner); spike report accepted; ADR-0002 and ADR-0003 accepted or reopened | Architect, Product/Contracts, Builder-Platform, Tester |
| 3 Domain + shared components | M1 | money, dates, accounts, categories, transactions, idempotency, migrations; MVP components | GTX-02 per component group; invariants I-01…I-12 green | Builder-Domain, Builder-UI |
| 4 Core experience | M2 | shell and navigation, QuickAdd, Home, accounting pages, budget module, SMS paste/share (after ADR-UI-010) | GTX-03 (QuickAdd), GTX-04 per page; Advisor review at the milestone | Builder-UI, Builder-Domain |
| 5 Complete and release v0.1 | M3 | reports, settings, backup/restore, first run, module matrix, device tests, user timing test, installers | GTX-05, GTX-06 (owner); release checklist (`RELEASE_AND_VERSIONING.md` §3) | Tester, Builder-Platform, Integrator |
| 6 v0.2 | after v0.1 | `tasks` module, multi-message capture queue, recurring transactions, CSV export, global search, security extras | per-module card, MMX rows, ADRs it needs | as needed |
| 7 v0.3 | | `markets`, finance depth (debts, installments, goals), English UI | Q-05 decided; network port and allowlist reviewed | as needed |
| 8 v0.4 | | local AI assistant (needs the H200 model choice and ADR-0004 accepted) | AI contract tests; propose-never-execute verified | Architect, Builder-Domain, Tester |
| 9 v0.5 | | `car` and `health` with their own privacy design | privacy review | as needed |
| 10 v1.0 | | full quality profile, iOS (after the Apple account), all module combinations | `--profile=full` green (ADR-UI-009 §5) | all |
| Optional | | cloud account, sync, end-to-end encryption | separate design and security review (ADR-0005/0006) | Architect, Security & License |

Rules that never change: nothing starts without a task packet; every phase ends with evidence, not claims; findings of a lighter profile are not forgiven at the next full run; D3 decisions (accept an ADR, GTX-01, GTX-06, accounts, public release) always wait for the owner.
