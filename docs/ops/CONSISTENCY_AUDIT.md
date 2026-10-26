# CONSISTENCY_AUDIT — final consistency audit of the documentation set (Max, X1)

**Status:** DONE · **Date:** 2026-10-26 · **Auditor:** Advisor · **Scope:** every document in the repository at this date (project docs, the UI constitution split into 42 files, `design_tokens.json`, the docs CI workflow, the checker itself and the SQL of the data contract). Next audit: see §9.

## خلاصه‌ی فارسی
- ابزار خودکار `docs_check` (بدون هزینه‌ی token) پانزده نوع بررسی انجام می‌دهد و روی کل مخزن **صفر خطا و صفر هشدار** می‌دهد؛ آزمون خودکار خودِ ابزار هر بررسی را عمداً خراب می‌کند تا ثابت شود ابزار واقعاً می‌گیرد.
- اعداد مهم مشخصات (۲۱۰ بررسی کنتراست، کمینه‌های جدول A-4، چک‌سام توکن‌ها) از روی خود فایل توکن‌ها **دوباره محاسبه** شد و درست بود.
- SQL قرارداد داده (`DATA_MODEL.md`) روی SQLite واقعی اجرا شد و قیدهای آن آزموده شد (سقف ۱۸ رقم، علامت فقط برای مانده‌ی اولیه، شکل انتقال، دامنه‌ی بودجه). یک ضعف واقعی در قید مانده‌ی اولیه رفع شد و این آزمون حالا بخشی از CI است (`tool/docs_check/check_data_model_ddl.py`).
- در خواندن تطبیقی اسناد، تناقض‌های واقعی پیدا و **در همین مرحله رفع شد** (شماره‌ی نسخه‌ها، تعداد شرکت‌کنندگان آزمون کاربر، فهرست digestها، مکان PAGE_INVENTORY، AMT-07، ادعاهای README، پایه‌ی مقایسه‌ی ماه). فایل‌های قدیمی بسته با تصمیم‌های ۲۵ اکتبر هم‌خوان شدند.
- در **خودِ مشخصات UI** دوازده مورد پیدا شد (۱۰ مورد برای اصلاح، ۲ اطلاعاتی). هیچ فایل مشخصات تغییر نکرده است؛ فهرست و متن پیشنهادی در [`docs/design/SPEC_ERRATA.md`](../design/SPEC_ERRATA.md) است.
- این بازبینی **درستی فنی** کتابخانه‌ها یا اجرای کد را ثابت نمی‌کند (کدی هنوز نیست)؛ محدودیت‌ها در §6 است.

## 1. Method
Four layers, cheapest first:
1. **Automated checks** (`tool/docs_check/docs_check.py`): deterministic, standard library only, read-only, about one second. Runs on every pull request (`.github/workflows/docs-check.yml`).
2. **Independent recomputation** of numbers that the documents state (contrast ratios, counts, checksum).
3. **Cross-document reading**: each pack document and each new document was read against the owner's locked decisions (STATUS), the contracts (`DATA_MODEL`, `MODULE_CONTRACT`, `CAPTURE_PIPELINE`, `AI_TOOL_CONTRACT`), the ADRs and the UI spec rule it cites.
4. **Reproducibility**: the commands in §8 give the same result on any machine; the self-test proves the checker can fail.

## 2. Automated checks
| Code | What it proves | Result |
|---|---|---|
| L1 | every relative Markdown link resolves | 0 |
| L2 | every backticked repo path under `docs/` or `design/` (and top-level docs) exists; future code paths are skipped | 0 |
| L3 | every project document is listed in `docs/README.md` | 0 |
| L4 | `docs/PROJECT_FILE_MAP.md` lists every project document and lists none that does not exist | 0 |
| R1 | every `ADR-NNNN` and `ADR-UI-NNN` cited exists in the ADR index | 0 |
| R2 | every `Q-NN` cited exists in `OPEN_QUESTIONS.md` | 0 |
| R3 | every two-digit UI-spec rule ID cited outside the spec exists in the spec | 0 |
| R4 | every requirement ID (`CORE-001` …) and risk ID (`R-001` …) cited is defined | 0 |
| R5 | every project contract ID (`DD-`, `MG-`, `I-`, `MDC-`, `CPX-`, `AT-`, `AE-`, `CB-`, `SE-`) cited is defined | 0 |
| R6 | no hidden bidi or BOM characters (Trojan-source) in documents, code or config; raw direction marks only in the one spec file that documents them | 0 |
| R7 | no Arabic yeh, kaf or tatweel in Persian text (WR-02), except on lines that discuss them | 0 |
| D1 | IDs defined in project documents are unique and do not collide with spec IDs | 0 |
| T1 | `design_tokens.json` checksum equals AX-02 and the file is LF only | 0 |
| T2 | the contrast numbers of spec appendix A-4, the AX-06 totals and the 210 count are recomputed from the tokens | 0 |
| S1 | (`--spec-report`) spec IDs that are referenced inside the spec but never defined | 0 |

**Self-test:** `tool/docs_check/test_docs_check.py` copies the repository to a temporary folder, breaks exactly one thing per test (a dead link, an unknown ADR, a duplicated ID, a hidden character, a wrong contrast number, a changed color without a new checksum, …) and requires the matching code to appear; it also requires a clean run on the real tree, a read-only checker and no hidden characters in the tool files, and it runs the data-contract guard below on the real contract and on three deliberately weakened copies. The self-test found one real defect while it was being written: the checker's own source and the test's source contained literal bidi characters because the editing tool had turned `\u` escapes into the characters themselves. Both files now build those characters from code points.

**Data-contract guard:** `tool/docs_check/check_data_model_ddl.py` extracts the `sql` blocks of `DATA_MODEL.md`, runs them on a real SQLite (in memory) and checks the constraints: the money pattern and the 18-digit cap (DD-02), the opening-balance sign rule, the shape of transfers, budget scope, capture hints, unique active names and foreign keys. It cannot check rules that need application code (a transaction's currency equals its account's, I-04; balances, I-07). The self-test weakens the amount cap, the opening-balance pattern and the transfer rule in a copy of the repository and requires the guard to fail each time. The numbers of the last run are in section 10.

## 3. Independent recomputation
- **210 contrast checks:** rows 2–8 of table A-4-a give 96 pairs per theme; add 8 (VTG-04, `text-primary` on the subtle fills) and 1 (VTG-05) for 105 per theme, 210 in both. Counts and the 12 group minima for both themes are recomputed from the tokens on every run (T2) and equal the table after rounding half-up to two decimals.
- **Token checksum:** SHA-256 over the file with the `checksum` field blanked equals AX-02 (`e6064535e236c5fcb322e0f454173e30d5c2dcdbac603a0a97d18dfebca33e3e`).
- **Spec counts:** 42 files (README plus 41 sections); 24 machine-check rules MC-01…MC-24; every two-digit rule ID that is referenced inside the spec has a definition (S1 = 0).
- **One wording mismatch** was found in the numbers: `border-strong` is described as «کمینه ۳٫۳:۱», the measured dark minimum is 3.2982 and the requirement is 3:1 (SE-06). The tokens themselves pass.
- **Data-contract SQL:** executed on SQLite 3.53.1 (the version in this workspace's Python). The weak opening-balance constraint (finding 15) was found while comparing DD-02 with the SQL; the guard now keeps it from coming back.

## 4. Findings in the project documents, and what was done
| # | Finding | Fix |
|---|---|---|
| 1 | `MVP_SCOPE` S-02 said the user tests use the participants of the full spec, while ADR-UI-009 reduces them | S-02 now states 5 participants per spec and 3 in the MVP profile (ADR-UI-009) |
| 2 | Release numbers disagreed between `MVP_SCOPE`, `MODULE_ROADMAP`, `README`, `GROWTH_PLAN` and Q-05 | `MODULE_ROADMAP` is canonical: v0.2 tasks, capture queue, recurring, CSV, search, security extras; v0.3 markets, debts/installments/goals, English UI; v0.4 assistant; v0.5 car/health; v1.0 full profile and iOS. All others point to it |
| 3 | `AGENTS.md` listed nine digests; the integrator digest did not exist and Product/Contracts had no digest | `digests/integrator.md` written; `architect` also covers Product/Contracts |
| 4 | `PAGE_INVENTORY` lived under `docs/product/` but describes design | moved to `docs/design/` |
| 5 | The Home «compare with last month» line had no basis rule, and the spec fixture implies a same-period comparison | `DATA_MODEL` **DD-11** (same elapsed period, integer percent, hidden rules, test vector); FIN-005; spec side recorded as SE-04 and SE-09 |
| 6 | ADR-UI-009 kept AMT-07 (English text) although v0.1 is Persian only | AMT-07 runs as a direction test with Persian strings; the English-text part is `NOT_IN_BUILD` until v0.3 |
| 7 | `README` and `POSITIONING` presented «three seconds» as a fact before any measurement | worded as a goal until UT-03 is done; README says nothing is built or measured yet |
| 8 | `RISKS_AND_ASSUMPTIONS` assumed a reference Android phone exists | reworded as unconfirmed (Q-09); no release candidate is tagged until a device is recorded |
| 9 | Pack files written before the owner's decisions of 2026-10-25 contradicted them (platforms, license, MVP, sync, roles) | replaced by v2 versions (list in §5) |
| 10 | `SECURITY.md` promised a private channel without saying how | GitHub private vulnerability reporting, no response-time promise; enabling it is now an item of the v0.1 release checklist |
| 11 | Role briefs, task and handoff templates used the five-agent model | updated to hats, task-packet fields (AG-06, CB-2) and VR-05 evidence; mapping to the spec agents kept |
| 12 | ADR-0001…0006 did not say where their consequences are now specified | dated update notes appended; statuses stay PROPOSED (the owner accepts them in one batch, Q-15) |
| 13 | `.gitignore` did not cover signing keys, backup files or Flutter output | extended; test fixtures `*.bluehesab` explicitly allowed |
| 14 | `PROJECT_FILE_MAP` promised an L4 check that did not exist | L4 implemented in both directions and self-tested |
| 15 | `DATA_MODEL` `accounts.opening_balance_minor` CHECK compared only the first character (it accepted `05`, `5abc` and more than 18 digits), weaker than DD-02 | rewritten (digits only, no padding, at most 18 digits, a sign only on a non-zero value); run on a real SQLite and guarded by `check_data_model_ddl.py` |
| 16 | `MODULE_CONTRACT` §6 promised a budget report section («هزینه در برابر بودجه») in v0.1; no `MVP_SCOPE` row (F07, F08) lists it | moved to "not in v0.1"; the Disabled row follows |
| 17 | `MVP_SCOPE` §10 and `DISTRIBUTION_PLAN` demanded an upgrade test between releases, but v0.1 has no earlier release (`RELEASE_AND_VERSIONING` already said clean install only) | clean install and restore; upgrades matter from v0.2 and the migration test from the fixture covers v0.1 (MG-04) |
| 18 | The default category names (`DATA_MODEL` §7) had no copy source although CM-10 forbids Persian strings in code | UI delta U-8: catalog rows, seeded once, user data afterwards |
| 19 | `DATA_MODEL` I-12 allowed raw text in backups «unless the user chose it», while CAP-P3, `SECURITY_PRIVACY_MODEL` §1, CAPT-002 and `BACKUP_RESTORE` say it is never stored or exported | I-12 reworded; user attachments stay a later, separate decision (BR-3) |
| 20 | `AI_TOOL_CONTRACT` AT-P4 («never a remote provider») and §5 («LAN allowed») stated one rule two ways; the endpoint validator (localhost, loopback, RFC1918) may not cover the VPN access that `LOCAL_MODEL_SETUP` LM-5 mentions | both now say: on-device model or the user's own LAN/localhost endpoint, never a hosted provider; AQ-6 records the VPN question (default: SSH tunnel to localhost) |
| 21 | `AUTONOMY_AND_ESCALATION`: the Lead had to log decisions in `DECISIONS.md` without write access; `tool/docs_check` had no owner; Builder-Platform's paths excluded what T-001 asks for; §2 lacked «enabling sync or cloud AI», which §4 lists as a D3 gate | hat table, a rule that a task packet may add scope-specific paths, the D3 list, `.gitignore` in T-001 and the lead and docs-bridge digests aligned |
| 22 | `PROJECT_FILE_MAP` said code folders appear «after the spike», but T-001 (the first spike step) creates the Flutter skeleton | wording fixed; the `lib/` layout is decided by ADR after the spike |
| 23 | `BACKUP_RESTORE` kept the last three recovery points but offered rollback «for 7 days» | the offer lasts up to 7 days, while the point is still among the last three |
| 24 | `ADR-UI-009` quoted «~931 rules», a figure that appears nowhere else and does not match the checker's count of 943 IDs; `LOCAL_MODEL_SETUP` said the owner «has experience» with OpenCode, which no document in the repository records | «about 940 identified rules and table rows»; OpenCode is a «candidate agent tool; confirm with the owner» |
| 25 | `AGENTS.md` did not point agents at the errata register, so an agent could escalate a gap that already has an interim rule; `MODULE_CONTRACT` named the spec's day-ring empty state without the SE-12 caveat | `AGENTS.md` says to check `docs/design/SPEC_ERRATA.md` first; `MODULE_CONTRACT` points to SE-12 |

## 5. Stale pack files
The original project pack (`BlueHesab-Mini-Project-Pack`) is superseded as follows.
- **Replaced by v2 (48 files):** `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `PRIVACY.md`, `SECURITY.md`, `SUPPORT.md`, `.gitignore`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/workflows/docs-check.yml`; in `docs/`: `BACKUP_RESTORE`, `CONTRIBUTOR_GUIDE`, `DATA_GOVERNANCE`, `DEFINITION_OF_DONE`, `GLOSSARY`, `IMPLEMENTATION_ROADMAP`, `PROJECT_CHARTER`, `PROJECT_FILE_MAP`, `README`, `RELEASE_AND_VERSIONING`, `REQUIREMENTS`, `RISKS_AND_ASSUMPTIONS`, `SECURITY_PRIVACY_MODEL`, `TEST_STRATEGY`; the role briefs, templates and operating model in `docs/agents/`; ADR-0001…0006 (update notes) and the ADR `README`; `AGENT_UI_RULES`, `DECISIONS`, `PLATFORM_MATRIX`, `UI_UX_CONTRACT`; `ACCESSIBILITY`, `DESIGN_SYSTEM`, `UX_FLOWS`; `OPEN_SOURCE_AUDIT` and `RESEARCH_PROTOCOL`.
- **Kept as they are:** `.editorconfig`, `.gitattributes`, the three issue templates, `ADR_TEMPLATE.md`.
- **Obsolete, do not copy:** `PACK_MANIFEST.json` (lists the old file set).

## 6. What this audit does not prove
- **Nothing was built or run besides the checker and the SQL of the data contract.** No Flutter project exists; no claim about a framework, plugin or platform behavior was tested. Only four technical claims were verified from official pages (drift is MIT, `shamsi_date` is BSD-3-Clause, Vazirmatn is OFL 1.1 as a candidate, the Google Play SMS rule behind «no SMS permission»); everything else in `OPEN_SOURCE_AUDIT.md` is marked from memory and must be checked before the spike's license scan (SP-11).
- **The UI constitution is still PROPOSED** (ADR-UI-001…008) and is not implemented; the audit shows it is internally consistent and numerically correct, not that it is the right design. Twelve errata remain open (SPEC_ERRATA).
- **Cross-document consistency was checked by reading,** not by a formal proof; the automated checks cover identifiers, links, numbers and hidden characters, not meaning. A reviewer may still find contradictions of meaning; the escalation rule (AG-08) applies.
- **Persian wording quality** was checked mechanically (R6, R7) and by reading, not by a native editor.
- **Where it ran:** Linux only, with Python 3.11, 3.12 (the version the CI workflow pins) and 3.13. The workflow itself has not run (there is no repository yet), its actions are unverified (SP-6), and nothing was run on macOS or Windows.
- **Auto wake-up of the Advisor is unverified** (Q-03); the verification plan is `AUTONOMY_AND_ESCALATION.md` §8.

## 7. Open items after this audit
| Item | Owner | Blocks |
|---|---|---|
| Accept ADR-0009 and ADR-UI-009 (and the batch ADR-0001/0005/0006) — Q-15 | owner (D3) | GTX-01, start of M0 |
| Repository public or private — Q-04 | owner (D3) | README, landing, security channel |
| Spend cap — Q-12 | owner (D3) | start of coding (CB-7) |
| H200 server details — Q-01 | owner | `LOCAL_MODEL_SETUP.md` |
| Spec errata SE-04, SE-08 and SE-12 before M2; SE-05 and SE-09 before the first fixtures task; the rest in a housekeeping pass | Product/Contracts | see SPEC_ERRATA |
| Merge these documents into the repository (read-only `git status` first; branch `docs/s0-medium-a-extra`) | Lead + owner | everything after |
| Verify the Advisor wake-up (ESC-000 dry run) | Advisor + Lead | automation (Q-03) |
| Verify and pin the GitHub Actions used by the docs workflow (SP-6 in `SECURITY_PRIVACY_MODEL.md`) | Security & License hat | making the repository public |

## 8. Reproduce
```bash
python3 tool/docs_check/test_docs_check.py          # self-test: the checker can fail
python3 tool/docs_check/docs_check.py --strict      # expected: 0 error(s), 0 warning(s)
python3 tool/docs_check/docs_check.py --spec-report # S1: spec IDs referenced but not defined
python3 tool/docs_check/check_data_model_ddl.py     # the SQL of DATA_MODEL runs; its constraints hold
```

## 9. Next audit
Re-run the commands in §8 on every pull request that touches documents (CI does). A full audit like this one is repeated at each milestone gate (M0, M1, M2, M3), after any change to the UI spec, and before the repository becomes public.

## 10. Last run
Recorded when this document was finalized:

```text
Tree: the complete package (142 files besides `_INSTALL.txt`), run from a clean copy on Linux.

$ python3 tool/docs_check/test_docs_check.py          # Python 3.13.17
Ran 27 tests in 4.167s
OK

$ python3 tool/docs_check/docs_check.py --strict
docs_check: 0 error(s), 0 warning(s); 86 non-spec md files, 943 spec ids

$ python3 tool/docs_check/docs_check.py --spec-report
S1 spec ids referenced but not defined as a row/bullet (0):
docs_check: 0 error(s), 0 warning(s); 86 non-spec md files, 943 spec ids

$ python3 tool/docs_check/check_data_model_ddl.py
check_data_model_ddl: SQLite 3.53.1; 74 expectation(s) checked, 0 failure(s)

Same four commands with Python 3.11.17 and 3.12.3 (SQLite 3.45.1): 0 errors, 0 warnings, 27 tests OK, 74 expectations, 0 failures.
```
