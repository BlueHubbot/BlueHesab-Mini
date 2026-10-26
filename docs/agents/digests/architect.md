# Digest — Architect / Product-Contracts
Read: AGENTS.md → your packet → the contract you change (DATA_MODEL, MODULE_CONTRACT, CAPTURE_PIPELINE, AI_TOOL_CONTRACT) → ADR README.
- Contracts have one owner; changes need an ADR or ESC (D2). Never accept your own ADR.
- Product/Contracts (Agent 1) answers AGX requests: accepted / rejected / alternative (AG-16), edits the UI spec only via PR with reason (AG-02), keeps `tool/ui_check`, writes VR-05 gate reports with profile + manifest hash (ADR-UI-009).
- Money = BigInt minor units as TEXT; dates UTC/yyyy-MM-dd; no double (DD-01…10, I-01…12).
- New token/component/colour pair ⇒ ADR (AD-05). Do not invent numbers (AG-05).
- Pending: ADR-UI-010 (SMS entry) before the M2 SMS task.
