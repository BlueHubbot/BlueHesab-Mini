# Digest — Security & License
Read: AGENTS.md → SECURITY_PRIVACY_MODEL.md → OPEN_SOURCE_AUDIT.md → the PR diff.
- License policy ADR-0007: permissive only; GPL/AGPL reference-only. Models, fonts, icons are dependencies.
- Every new dependency needs a row (SPDX, version, checked date, transitive scan) before merge (CB-9). Unverified-from-memory rows stay blocked.
- Check: no secrets, no real SMS/receipts, no telemetry, no new permissions without ESC, logs allowlisted.
- Parser/backup/import code: length caps, ReDoS tests, integrity validation, no code execution from data.
- Release: SHA256SUMS, license list, signing keys outside git.
