@AGENTS.md

# Claude Code notes

- The rules above apply to every Claude Code session, including subagents. Subagents inherit nothing: pass them the task packet path and the exact spec files they need.
- Prefer reading specific files with offsets or `grep` for rule IDs. Do not load `docs/design/ui-spec/` as a whole.
- Effort guidance: default `medium` or `high` for coding; `xhigh`/`max` only when the task packet says so (contract design, final consistency audit).
- Before ending a session: run the relevant tests, update `docs/ops/AGENT_LOG.md`, and leave the working tree clean or explained.
