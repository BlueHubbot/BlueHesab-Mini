# Documentation Index

Everything about BlueHesab Mini that is not code. Keep this list in sync: `python3 tool/docs_check/docs_check.py` warns (L3) when a document is missing here.

## Start here
| You are | Read, in this order |
|---|---|
| The product owner | [ops/STATUS.md](ops/STATUS.md) → [ops/OPEN_QUESTIONS.md](ops/OPEN_QUESTIONS.md) → [product/MVP_SCOPE.md](product/MVP_SCOPE.md) → [architecture/DECISIONS.md](architecture/DECISIONS.md) |
| An AI agent | [../AGENTS.md](../AGENTS.md) → [ops/STATUS.md](ops/STATUS.md) → your task packet in `agents/tasks/` → your digest in `agents/digests/` |
| A contributor | [../CONTRIBUTING.md](../CONTRIBUTING.md) → [CONTRIBUTOR_GUIDE.md](CONTRIBUTOR_GUIDE.md) |
| A reviewer | [DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md) → [TEST_STRATEGY.md](TEST_STRATEGY.md) |

## Product and planning
| File | What it is |
|---|---|
| [PROJECT_CHARTER.md](PROJECT_CHARTER.md) | vision, platforms, principles, non-goals |
| [REQUIREMENTS.md](REQUIREMENTS.md) | requirement IDs with release and evidence |
| [product/MVP_SCOPE.md](product/MVP_SCOPE.md) | what v0.1 builds, success criteria, milestones M0–M3 |
| [product/MODULE_ROADMAP.md](product/MODULE_ROADMAP.md) | versions and modules after v0.1 |
| [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md) | phases and gates |
| [product/DISTRIBUTION_PLAN.md](product/DISTRIBUTION_PLAN.md) | free release channels and the landing page |
| [product/POSITIONING.md](product/POSITIONING.md) | message, audience, claims discipline |
| [product/GROWTH_PLAN.md](product/GROWTH_PLAN.md) | growth without telemetry |
| [RISKS_AND_ASSUMPTIONS.md](RISKS_AND_ASSUMPTIONS.md) | risk register |
| [GLOSSARY.md](GLOSSARY.md) | terms (English/Persian) |

## Architecture and data
| File | What it is |
|---|---|
| [architecture/DECISIONS.md](architecture/DECISIONS.md) | register of decisions and owner decision log |
| [architecture/ADR/README.md](architecture/ADR/README.md) | ADR lifecycle and index: [0001](architecture/ADR/ADR-0001-local-first-product.md), [0002](architecture/ADR/ADR-0002-cross-platform-framework.md), [0003](architecture/ADR/ADR-0003-storage-and-migrations.md), [0004](architecture/ADR/ADR-0004-ai-provider-abstraction.md), [0005](architecture/ADR/ADR-0005-sync-and-conflicts.md), [0006](architecture/ADR/ADR-0006-sync-deferred-until-data-contract.md), [0007](architecture/ADR/ADR-0007-license.md), [0008](architecture/ADR/ADR-0008-agent-workflow.md), [0009](architecture/ADR/ADR-0009-platform-scope.md), [UI-009](architecture/ADR/ADR-UI-009-mvp-profile.md), [template](architecture/ADR/ADR_TEMPLATE.md) |
| [architecture/DATA_MODEL.md](architecture/DATA_MODEL.md) | tables, money, invariants, migrations, backup contract |
| [architecture/MODULE_CONTRACT.md](architecture/MODULE_CONTRACT.md) | module registry and boundaries |
| [architecture/CAPTURE_PIPELINE.md](architecture/CAPTURE_PIPELINE.md) | SMS/OCR/voice capture into drafts |
| [architecture/AI_TOOL_CONTRACT.md](architecture/AI_TOOL_CONTRACT.md) | AI provider and tool rules (v0.4) |
| [architecture/PLATFORM_MATRIX.md](architecture/PLATFORM_MATRIX.md) | what each platform has to prove |
| [architecture/SPIKE_PLAN.md](architecture/SPIKE_PLAN.md) | the M0 technical spike |
| [architecture/UI_UX_CONTRACT.md](architecture/UI_UX_CONTRACT.md), [architecture/AGENT_UI_RULES.md](architecture/AGENT_UI_RULES.md) | UI summary and agent rules (the spec is normative) |
| [DATA_GOVERNANCE.md](DATA_GOVERNANCE.md), [BACKUP_RESTORE.md](BACKUP_RESTORE.md), [SECURITY_PRIVACY_MODEL.md](SECURITY_PRIVACY_MODEL.md) | data policy, backup, security and privacy |
| [research/OPEN_SOURCE_AUDIT.md](research/OPEN_SOURCE_AUDIT.md), [research/RESEARCH_PROTOCOL.md](research/RESEARCH_PROTOCOL.md) | dependency and license evidence, how research is recorded |

## Design
| File | What it is |
|---|---|
| [design/ui-spec/README.md](design/ui-spec/README.md) | the UI constitution (about 930 rules), split by section |
| [design/DESIGN_SYSTEM.md](design/DESIGN_SYSTEM.md), [design/UX_FLOWS.md](design/UX_FLOWS.md), [design/ACCESSIBILITY.md](design/ACCESSIBILITY.md) | summaries and flows |
| [design/PAGE_INVENTORY.md](design/PAGE_INVENTORY.md) | pages of v0.1 and what is not built |
| [design/SPEC_ERRATA.md](design/SPEC_ERRATA.md) | known gaps in the spec with proposed fixes (spec edits go through Product/Contracts) |

## Agents and operations
| File | What it is |
|---|---|
| [agents/AGENT_OPERATING_MODEL.md](agents/AGENT_OPERATING_MODEL.md) | roles, isolation, review, status vocabulary |
| [agents/AUTONOMY_AND_ESCALATION.md](agents/AUTONOMY_AND_ESCALATION.md) | who decides what, how questions travel |
| [agents/RUNBOOK.md](agents/RUNBOOK.md) | how a session starts, works and ends |
| [agents/LOCAL_MODEL_SETUP.md](agents/LOCAL_MODEL_SETUP.md) | local coding model on the H200 server |
| [agents/LEAD_ARCHITECT.md](agents/LEAD_ARCHITECT.md), [agents/AGENT_1_DESIGN_SYSTEM.md](agents/AGENT_1_DESIGN_SYSTEM.md), [agents/AGENT_2_APP_SHELL.md](agents/AGENT_2_APP_SHELL.md), [agents/AGENT_3_FINANCE.md](agents/AGENT_3_FINANCE.md), [agents/AGENT_4_PERSONAL_MODULES.md](agents/AGENT_4_PERSONAL_MODULES.md), [agents/AGENT_5_AI_AND_QA.md](agents/AGENT_5_AI_AND_QA.md) | detailed role briefs |
| [agents/TASK_TEMPLATE.md](agents/TASK_TEMPLATE.md), [agents/HANDOFF_TEMPLATE.md](agents/HANDOFF_TEMPLATE.md) | task packet and handoff templates |
| [ops/STATUS.md](ops/STATUS.md), [ops/AGENT_LOG.md](ops/AGENT_LOG.md), [ops/OPEN_QUESTIONS.md](ops/OPEN_QUESTIONS.md), [ops/CONSISTENCY_AUDIT.md](ops/CONSISTENCY_AUDIT.md) | state, log, open questions, last consistency audit |
| [TEST_STRATEGY.md](TEST_STRATEGY.md), [DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md), [RELEASE_AND_VERSIONING.md](RELEASE_AND_VERSIONING.md), [PROJECT_FILE_MAP.md](PROJECT_FILE_MAP.md), [CONTRIBUTOR_GUIDE.md](CONTRIBUTOR_GUIDE.md) | quality, release and repository rules |
