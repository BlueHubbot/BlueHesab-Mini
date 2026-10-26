# Changelog

All notable changes are listed here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow `docs/RELEASE_AND_VERSIONING.md`. Until v0.1 the repository contains documentation only.

## Unreleased
### Added
- Documentation pack: charter, requirements, ADR-0001…0009 and ADR-UI-009, data model, module, capture and AI contracts, MVP scope, page inventory, test strategy, release plan, security/privacy model, backup design, agent workflow (autonomy and escalation, runbook, digests, task packets).
- The UI constitution split into `docs/design/ui-spec/` and the token file `design/tokens/design_tokens.json`.
- `tool/docs_check/docs_check.py` and its self-test `test_docs_check.py`: zero-token consistency checks (links, file map and index, IDs, ADR/question references, hidden characters, token checksum, contrast numbers) and mutation tests that prove each check can fail; `tool/docs_check/check_data_model_ddl.py` runs the SQL of the data contract on a real SQLite and checks its constraints.
- `docs/design/SPEC_ERRATA.md` (12 known gaps in the UI constitution with proposed fixes and interim rules) and `docs/ops/CONSISTENCY_AUDIT.md` (final audit of the documentation set).
- Apache-2.0 license, contribution rules, code of conduct, privacy statement.
### Changed
- Pack files superseded by v2 versions (charter, requirements, platform matrix, UI/UX contract, agent UI rules, design system, UX flows, accessibility, glossary, data governance, risks, roadmap, file map, definition of done).
### Not yet
- No application code; no release.
