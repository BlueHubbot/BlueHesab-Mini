# Security and Privacy Model (v2)

**Status:** PROPOSED · **Owner:** Security & License hat · **Date:** 2026-10-26 · Related: `PRIVACY.md`, `DATA_MODEL.md`, `CAPTURE_PIPELINE.md` §6, `AI_TOOL_CONTRACT.md`, `BACKUP_RESTORE.md`, AGENTS.md hard rules. Not a legal opinion.

## خلاصه‌ی فارسی
v0.1 هیچ حساب، ابر، تله‌متری یا مجوز پیامک ندارد. داده روی دستگاه و در پایگاه‌داده‌ی محلی است (رمزگذاری دیتابیس در ADR-0003 تصمیم می‌شود). مهم‌ترین خطرها: گم‌شدن/سرقت دستگاه، فایل پشتیبان رمزنشده، وابستگی آلوده، راز در git/CI، ورودی مخرب (پیامک/پشتیبان)، و بعدها prompt injection.

## 1. Assets and data classes
| Class | Examples | Where | Rule |
|---|---|---|---|
| Financial | accounts, transactions, budgets, balances | local DB, backup file | never leaves device unless user exports |
| Captured raw | SMS text, receipt image, voice | memory only | never stored/logged/exported |
| Sensitive personal (later) | health, location | module tables | own design before module |
| Secrets | model endpoint token, signing keys | OS secure storage / repo secrets | never in git, logs, backups |
| Diagnostics | crash type, timings | none sent | none by default |

## 2. Trust boundaries
User ↔ UI ↔ application/use cases ↔ domain ↔ data. Inputs crossing into the app: user text, clipboard/share text, backup files, files for import, model replies (later), network (markets only, later). Every crossing is validated (length, type, schema) before use.

## 3. Threats and controls (v0.1)
| ID | Threat | Controls |
|---|---|---|
| T-01 | Device theft/lock bypass | OS device lock is the baseline; optional app lock (PIN/biometric via OS) planned v0.2; DB encryption decision ADR-0003; backup warning |
| T-02 | Malicious or corrupt backup | full validation before change; recovery point; size cap; no code execution from data |
| T-03 | Malicious pasted SMS/text | length cap; linear-time parser, ReDoS tests; never executed or rendered as markup; draft needs user confirm |
| T-04 | Compromised dependency | audit table, pinned versions, lockfile review, license scan, minimal dependency set, CI without secrets for PR builds from forks |
| T-05 | Secrets in git/CI/logs | secret-scan in CI; pre-commit hook; signing keys only in repo secrets/owner custody; CB-4 incident process |
| T-06 | Data leakage via logs/crash reports | allowlisted log fields; scrubber test; no analytics SDKs |
| T-07 | Unintended network use | no network permission use in v0.1 beyond what the platform needs; static check that network packages are absent; markets later via NetworkPort allowlist |
| T-08 | Supply-chain in releases | reproducible-enough CI builds, SHA256SUMS, signed Android APK, release only via CI from tagged commit |
| T-09 | Prompt injection / over-powerful AI (later) | propose-never-execute, untrusted-input wrapping, tool allowlist, schema validation (AT-P1…P8) |
| T-10 | Exposed local AI service (later/dev) | localhost + tunnel/VPN + token (`LOCAL_MODEL_SETUP`) |
| T-11 | Clipboard exposure | read only on explicit tap; clear paste field on close |
| T-12 | Screenshots/app switcher exposure | optional secure-screen setting (Android FLAG_SECURE-type) planned v0.2 |
| T-13 | Money precision/logic errors as integrity threat | BigInt + invariants + property tests |

## 4. Principles
Local-first; no hidden transfer; least privilege and just-in-time permissions; no sensitive logs; user can export and delete everything (delete-all-data action in Settings); secure defaults; no «encrypted/secure» claim without evidence; explain every outbound request in `PRIVACY.md` before it exists.

## 5. Permissions (v0.1)
Android: no SMS, contacts, location, microphone, camera, notifications. Storage via system pickers (SAF). Share intent receiver for text/plain only. Desktop: file dialogs only. Any new permission needs ADR/ESC and a line in PRIVACY.md.

## 6. Process
Security review of each PR touching data, parsing, backup, network or permissions (Security hat). Pre-release review (RELEASE checklist). Vulnerability reports: `SECURITY.md` (private advisory on GitHub). Incident: stop, rotate secrets, assess, disclose in release notes.

## 7. Open questions
SP-1 DB encryption and key handling per platform (ADR-0003). SP-2 app lock design. SP-3 secure-screen default. SP-4 dependency pinning policy for transitive packages. SP-5 SBOM generation in CI (candidate: CycloneDX tool, verify). SP-6 GitHub Actions in `.github/workflows/docs-check.yml` are pinned to full commit SHAs (`actions/checkout` v4.4.0, `actions/setup-python` v5.6.0; SHAs read from the upstream tags with `git ls-remote` on 2026-10-26). Any new action is pinned the same way.
