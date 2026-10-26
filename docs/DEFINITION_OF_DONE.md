# Definition of Done (v2)

A task is `DONE` only when all of these are true (status vocabulary: `AGENT_OPERATING_MODEL.md`). Under the MVP profile (ADR-UI-009) the lighter gate rows apply, but nothing marked "never reduced" there is skipped.

- [ ] Acceptance criteria of the task packet met, each with evidence (command and real output, screenshot, file).
- [ ] Scope and public contracts documented; rule IDs of the UI spec and contract IDs (DD-, MDC-, CAP-, AT-) are cited in code comments, tests and the PR.
- [ ] Tests run; actual results recorded. Relevant unit, contract, widget, golden, migration and integration tests pass. No test is reported as passed unless it ran.
- [ ] For UI changes: token-only styling, copy from the catalog, RTL and light/dark checked (LTR overflow tests), keyboard and screen-reader semantics, `ui_check` green once the tool exists.
- [ ] For data changes: migration test from the previous fixture and from empty; backup and restore round trip; offline and restart checked; invariants I-01…I-12 still green.
- [ ] Security, privacy, dependency and license impact reviewed (`docs/research/OPEN_SOURCE_AUDIT.md`); no new network use, permission or telemetry without an ADR.
- [ ] No secrets, private data, real SMS or receipts, model files or build output committed.
- [ ] If documents changed: `python3 tool/docs_check/docs_check.py --strict` is clean (and `python3 tool/docs_check/check_data_model_ddl.py` when `DATA_MODEL.md` changed); `docs/ops/STATUS.md`, the changelog and the affected indexes are updated.
- [ ] PR reviewed by a fresh session or person other than the author, and merged by the Integrator under the workflow.
- [ ] Handoff written from `docs/agents/HANDOFF_TEMPLATE.md`; one line added to `docs/ops/AGENT_LOG.md`; remaining risks recorded.
