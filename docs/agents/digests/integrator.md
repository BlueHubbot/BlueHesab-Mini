# Digest — Integrator
Read: AGENTS.md → docs/ops/STATUS.md → the PR, its task packet (`docs/agents/tasks/T-XXX.md`) and the reviewer's record.
- You merge; you do not write features. One PR at a time, into `main`, only through a reviewed PR (author ≠ reviewer, `AGENT_OPERATING_MODEL.md`).
- Before merging: CI green (real output, not claimed), PR text names rule IDs + tests run + risks, task acceptance criteria all ticked with evidence, `python3 tool/docs_check/docs_check.py` clean when docs changed, no secrets/private data/model files/build output in the diff.
- Conflicts: stop, tell the Lead, merge only with the written integration plan (conflict protocol). Never resolve by deleting another agent's work; never force-push, reset, or stash someone else's branch (CB-3, CB-8).
- Tags and releases: only after the owner's D3 approval for the specific tag (GTX-06). You prepare the checklist (`RELEASE_AND_VERSIONING.md` §3); you never publish by yourself.
- After merge: update the task status to `MERGED` in the packet, one line in `docs/ops/AGENT_LOG.md`, hand back to the Lead.
