# Research Protocol

Prefer canonical upstream repos, official license files, releases and platform docs. Record access date and exact version/commit. Separate project claims, our test results and assumptions. Never infer license from a badge or another project's license. If unavailable, mark `UNVERIFIED`; do not silently substitute a similarly named project. Audit model weights, datasets, map data, fonts, icons and assets separately.

Minimum record:
```yaml
name:
canonical_url:
checked_at:
version_or_commit:
maintenance_evidence:
license_spdx:
license_file_url:
model_or_asset_licenses:
platforms_tested:
offline_test:
security_notes:
integration_type:
decision:
owner:
reviewer:
```

Every prototype records platform/OS, exact dependency/model, reproduction steps, expected/actual results, performance/memory where relevant, failure modes and cleanup instructions.

## Vocabulary used in `OPEN_SOURCE_AUDIT.md` (added 2026-10-26)
- **Verified** (تأییدشده): read from the canonical page or file during the audit, with the date and source named in the row.
- **From memory** (حافظه): not checked yet. It is `UNVERIFIED`: it may guide where to look, but nothing is adopted, copied or promised on its basis, and it must be checked before the spike's license scan (SP-11).
- A web fetch that is blocked or fails leaves the claim `UNVERIFIED`; do not replace it with a mirror or a similarly named project without saying so in the row.
- A candidate is never an approved dependency. Approval is the recorded check plus the Security & License hat's sign-off in the task packet.
