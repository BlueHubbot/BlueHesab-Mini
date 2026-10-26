# Platform Capability Matrix (v2)

**Status:** feasibility plan. `VERIFY` means this project has not demonstrated the capability yet; the spike (`SPIKE_PLAN.md`, items SP-01…SP-12) and the test matrix (`docs/TEST_STRATEGY.md` §6) produce the evidence. Platform scope and release order: ADR-0009. Columns are the four product targets plus the web demo (Style Guide / MotionLab only, no user data).

| Capability | v0.1 need | Android | Windows | macOS | iOS | Web demo | Proof required |
|---|---|---|---|---|---|---|---|
| UI build and start | yes | VERIFY | VERIFY | VERIFY | VERIFY (simulator) | VERIFY | CI artifacts + smoke test (SP-01) |
| Durable local storage (SQLite) | yes | VERIFY | VERIFY | VERIFY | VERIFY | not used | open, migrate, restart (SP-05) |
| 18-digit money round trip | yes | VERIFY | VERIFY | VERIFY | VERIFY | formatting only | I-01 tests (SP-02) |
| RTL, Persian digits, Jalali | yes | VERIFY | VERIFY | VERIFY | VERIFY | VERIFY | goldens + manual look (SP-03, SP-04) |
| Backup/export and restore | yes | SAF or share sheet | save dialog | save dialog | share sheet / Files (later) | n/a | round trip + permission tests (BACKUP_RESTORE) |
| Receive shared text (SMS paste/share) | yes | share intent text/plain | n/a | n/a | n/a (later) | n/a | SP-07 |
| Clipboard paste on tap | yes | VERIFY | VERIFY | VERIFY | VERIFY | n/a | paste test (CAPTURE_PIPELINE) |
| Installer / signing | yes | APK signed with our key | unsigned installer (SmartScreen warning) | unsigned DMG (Gatekeeper warning) | needs paid Apple account | GitHub Pages | SP-10, `DISTRIBUTION_PLAN.md` |
| Accessibility and RTL semantics | yes | TalkBack (AMT-01) | keyboard (AMT-03) | keyboard (AMT-03) | VoiceOver (AMT-02, later) | n/a | AMT rows, MVP subset in ADR-UI-009 |
| Local notifications / reminders | no (v0.2 with `tasks`) | OS-constrained | OS-dependent | OS-dependent | OS-constrained | n/a | per-platform prototype before v0.2 (NOTIF-001) |
| Background work | no | OS-constrained | VERIFY | VERIFY | OS-constrained | n/a | only when a module needs it |
| Secure secret storage | no secrets in v0.1 | OS keystore adapter | OS adapter | Keychain adapter | Keychain adapter | n/a | threat model when a token exists |
| Network | none in v0.1 | — | — | — | — | — | static check (PRIV-003) |
| Embedded local AI | no (v0.4) | Candidate (constrained) | Candidate | Candidate | Candidate (constrained) | not planned | named model benchmark |
| Connect to a local or LAN model server (OpenAI-compatible) | no (v0.4) | possible if reachable | possible | possible | possible | not planned | security and network test |
| Receipt OCR, speech-to-text | no (v0.4+) | VERIFY | VERIFY | VERIFY | VERIFY | n/a | Persian benchmark on synthetic samples |
| Wearable/health APIs, GPS | no (v0.5, if ever) | provider-dependent | adapter-dependent | adapter-dependent | provider-dependent | n/a | exact provider, consent, privacy review |

## AI capability policy
"Local AI" must say where inference runs: inside the app, in a local companion service, or on a LAN server. A desktop Ollama-style service is not the same as embedded mobile inference. No capability is supported until model, device class, memory budget, latency, packaging, fallback and evidence are recorded. Defaults and contract: `AI_TOOL_CONTRACT.md`, ADR-0004.

## Evidence record
Record OS/device, app commit, exact dependency/model version, test inputs, expected/actual result, latency/memory where relevant, offline behavior, failure path, evidence link and owner.
