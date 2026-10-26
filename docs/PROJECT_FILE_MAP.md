# Project File Map (v2)

**Status:** v2 (2026-10-26). Target structure of the repository. Documents listed here exist now; the code folders (`lib/`, `test/`, …) are created by task packets only: T-001 creates the minimal Flutter skeleton as the first step of the spike (`SPIKE_PLAN.md`), and the layout of `lib/` beyond it is decided by ADR after the spike (ADR-0002/0009). `tool/docs_check/docs_check.py` warns (L4) when a project document is missing from this map, errors (L4) when the map lists a document that does not exist, and warns (L3) when a document is missing from `docs/README.md`.

```text
.
├── README.md  README.fa.md             # public face (English, Persian)
├── AGENTS.md  CLAUDE.md                # rules every agent reads first
├── LICENSE  NOTICE                     # Apache-2.0 and trademark/attribution note
├── CONTRIBUTING.md  CODE_OF_CONDUCT.md  SECURITY.md  SUPPORT.md  PRIVACY.md  CHANGELOG.md
├── .editorconfig  .gitattributes  .gitignore
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/ bug_report.yml  feature_request.yml  architecture_decision.yml
│   └── workflows/docs-check.yml
├── design/
│   ├── tokens/design_tokens.json       # single source of visual values (checksum AX-02)
│   └── mvp_manifest.json               # (planned, ADR-UI-009) what exists in the build
├── docs/
│   ├── README.md                       # documentation index
│   ├── PROJECT_CHARTER.md  REQUIREMENTS.md  GLOSSARY.md  RISKS_AND_ASSUMPTIONS.md
│   ├── IMPLEMENTATION_ROADMAP.md  PROJECT_FILE_MAP.md  DEFINITION_OF_DONE.md
│   ├── TEST_STRATEGY.md  SECURITY_PRIVACY_MODEL.md  DATA_GOVERNANCE.md
│   ├── BACKUP_RESTORE.md  RELEASE_AND_VERSIONING.md  CONTRIBUTOR_GUIDE.md
│   ├── ops/                            # STATUS.md  AGENT_LOG.md  OPEN_QUESTIONS.md  CONSISTENCY_AUDIT.md
│   │   └── escalations/  weekly/       # ESC-NNN.md, ADVISOR_REPLY-NNN.md, weekly notes (created on demand)
│   ├── product/                        # MVP_SCOPE  MODULE_ROADMAP  DISTRIBUTION_PLAN  POSITIONING  GROWTH_PLAN
│   ├── architecture/
│   │   ├── DATA_MODEL.md  MODULE_CONTRACT.md  CAPTURE_PIPELINE.md  AI_TOOL_CONTRACT.md
│   │   ├── DECISIONS.md  PLATFORM_MATRIX.md  SPIKE_PLAN.md  UI_UX_CONTRACT.md  AGENT_UI_RULES.md
│   │   └── ADR/                        # ADR-0001…0009, ADR-UI-009 (+ ADR-UI-010 planned), ADR_TEMPLATE, README
│   ├── design/
│   │   ├── ui-spec/                    # the UI constitution (README.md + 41 files)
│   │   ├── DESIGN_SYSTEM.md  PAGE_INVENTORY.md  ACCESSIBILITY.md  UX_FLOWS.md  SPEC_ERRATA.md
│   ├── research/                       # OPEN_SOURCE_AUDIT.md  RESEARCH_PROTOCOL.md
│   └── agents/
│       ├── AGENT_OPERATING_MODEL.md  AUTONOMY_AND_ESCALATION.md  RUNBOOK.md  LOCAL_MODEL_SETUP.md
│       ├── LEAD_ARCHITECT.md  AGENT_1_DESIGN_SYSTEM.md  AGENT_2_APP_SHELL.md      # detailed briefs per hat
│       ├── AGENT_3_FINANCE.md  AGENT_4_PERSONAL_MODULES.md  AGENT_5_AI_AND_QA.md
│       ├── TASK_TEMPLATE.md  HANDOFF_TEMPLATE.md
│       ├── digests/                    # short per-hat reading lists
│       └── tasks/                      # T-XXX.md task packets
├── tool/
│   ├── docs_check/                     # docs_check.py, check_data_model_ddl.py, test_docs_check.py (exist)
│   └── ui_check/  release/  model_bench/     # (planned, task packets)
├── spike/                              # throw-away spike code (branch only)
├── lib/  test/  integration_test/  assets/  # (T-001 skeleton; `lib/` layout decided by ADR after the spike)
├── android/  windows/  macos/  ios/  web/    # Flutter platform folders (created by T-001)
└── site/                               # landing page (GitHub Pages), later
```

Rules: do not create placeholder source just to fill the tree; do not commit build output, model files, backups or keys (`.gitignore`); new top-level folders need an ADR or a Lead decision recorded in `docs/architecture/DECISIONS.md`.
