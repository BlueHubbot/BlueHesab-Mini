# BlueHesab Mini (آبی‌حساب)

Free, open-source (Apache-2.0), Persian-first, local-first personal finance app. Goal: record an expense in about three seconds; your data stays on your device.

**Status:** documentation phase, no app code yet. Planned first release (v0.1): Android, Windows, macOS. iOS later. See [`docs/product/MVP_SCOPE.md`](docs/product/MVP_SCOPE.md).

## Why (design commitments)
These are what the design contract requires and what the tests will check (`docs/product/MVP_SCOPE.md` §2). Nothing is built or measured yet; claims about speed are targets until the user timing test (UT-01…04) is done.

- Fast: QuickAdd designed for ≤3 taps / ≤3 seconds.
- Private: no account, no cloud, no telemetry, no SMS permission. Paste or share a bank SMS and get a **draft** you confirm.
- Truly Persian: RTL, Jalali calendar, Persian digits, toman/rial, exact big-number money (`BigInt`, no floating point).
- Modular: optional modules that leave no trace when off.
- Built by AI agents under a written contract, in the open.

## Where to start
| You are | Read |
|---|---|
| New contributor | [`CONTRIBUTING.md`](CONTRIBUTING.md), [`docs/CONTRIBUTOR_GUIDE.md`](docs/CONTRIBUTOR_GUIDE.md) |
| An AI agent | [`AGENTS.md`](AGENTS.md) then [`docs/ops/STATUS.md`](docs/ops/STATUS.md) |
| Curious about design | [`docs/design/ui-spec/README.md`](docs/design/ui-spec/README.md) |
| Curious about architecture | [`docs/architecture/`](docs/architecture/) (DATA_MODEL, MODULE_CONTRACT, CAPTURE_PIPELINE, AI_TOOL_CONTRACT, ADRs) |
| Privacy-minded | [`PRIVACY.md`](PRIVACY.md), [`docs/SECURITY_PRIVACY_MODEL.md`](docs/SECURITY_PRIVACY_MODEL.md) |

## Roadmap (short)
v0.1 finance core + budget + SMS paste · v0.2 tasks + better capture · v0.3 markets + English UI + debts/installments · v0.4 local AI assistant · v0.5 car/health · v1.0 full quality gates. Details: [`docs/product/MODULE_ROADMAP.md`](docs/product/MODULE_ROADMAP.md).

## Honest limits
Windows and macOS builds are unsigned at first and show OS warnings; iOS needs a paid Apple account and comes later. No sync between devices; use backup files. See [`docs/product/DISTRIBUTION_PLAN.md`](docs/product/DISTRIBUTION_PLAN.md).

## License
Apache-2.0 for code and docs. The name and logo are not licensed for reuse (see [`NOTICE`](NOTICE)). Third-party licenses: [`docs/research/OPEN_SOURCE_AUDIT.md`](docs/research/OPEN_SOURCE_AUDIT.md).
