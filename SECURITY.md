# Security Policy

BlueHesab Mini keeps personal finance data on the user's own device. A weakness can expose or corrupt that data, so please report problems **privately**.

## Reporting a vulnerability
- Do **not** open a public issue with exploit details, private data, real bank SMS texts, backups or keys.
- Use GitHub private vulnerability reporting: the repository's **Security → Report a vulnerability**. The owner turns this on before the repository becomes public (release checklist, `docs/RELEASE_AND_VERSIONING.md` §3). While the repository is private, tell the owner directly instead.
- Please include: app version or commit, platform and OS version, steps to reproduce, the impact you see, and a **synthetic** example. Remove personal data and secrets from everything you send.

## What to expect
This is a free project maintained in spare time. There is **no response-time promise**. Reports are acknowledged when seen; confirmed issues are fixed in the next release, and severe ones in a hotfix (`docs/RELEASE_AND_VERSIONING.md` §6). Reporters are credited in the release notes if they wish.

## Scope
In scope:
- confidentiality and integrity of the local database and backup files;
- parsing of imported or untrusted input: backup files, pasted or shared SMS text, and later OCR/AI output;
- permissions the app asks for (v0.1 asks for no SMS permission), network use, and anything that could send data off the device;
- dependencies, build and release pipeline, signing keys, and secrets in the repository;
- from v0.4: personal data reaching the AI assistant or its tools.

Out of scope: an attacker who already has an unlocked device, rooted or jailbroken devices, data the user chooses to share, and third-party apps or services.

## Supported versions
Before 1.0 only the latest release receives security fixes.

## For contributors and agents
Never commit a secret, private data or a real SMS. If you see one in a diff, log or history: stop, remove it from the working tree and report it to the Lead (circuit breaker CB-4 in `docs/agents/AUTONOMY_AND_ESCALATION.md`). Threat notes and controls: `docs/SECURITY_PRIVACY_MODEL.md`; data rules: `docs/DATA_GOVERNANCE.md`.
