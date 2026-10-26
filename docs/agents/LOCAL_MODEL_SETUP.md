# LOCAL_MODEL_SETUP — مدل محلی روی سرور H200

**Status:** PLAN, blocked on Q-01 (GPU count, OS, access) · **Owner:** Lead + Builder-Platform · **Date:** 2026-10-26
No model is chosen (Q-02). Model names, versions and throughput below are **not** claims; the choice comes from the benchmark in §4. Facts about vLLM/llama.cpp/OpenCode must be re-checked on their official pages when this plan is executed.

## خلاصه‌ی فارسی
هدف: یک API سازگار با OpenAI روی H200 که ایجنت‌های روتین (کد معمولی، آزمون، fixture) از آن استفاده کنند و Claude فقط برای کار سنگین بماند. مراحل: ۱) اطلاعات سرور از شما ۲) نصب سرویس‌دهنده ۳) امنیت شبکه ۴) آزمون مقایسه‌ی مدل‌ها روی کارهای واقعی خودمان ۵) اتصال ابزار ایجنت ۶) مرز اعتماد: مدل محلی هرگز Lead یا بازبین کد پول نیست مگر آزمون پاس شود (سطح L2).

## 1. Information needed from the owner (Q-01)
GPU count and exact model (H200 ×?), total VRAM, OS and version, NVIDIA driver/CUDA, CPU/RAM (known: 64 cores, 356 GB), disk free for weights, how reachable (SSH user, VPN, LAN IP, port rules), whether other jobs share the GPUs, and who administers the box. Until then no command is run on it.

## 2. Architecture
```
Mac / Windows (agent tool: Claude Code or OpenCode, sandboxed worktree)
   │  HTTPS or SSH tunnel, token
   ▼
H200 server: serving process (candidate: vLLM, OpenAI-compatible) → model weights on local disk
```
- Protocol: OpenAI-compatible `/v1/chat/completions` with tool calling (same one the app's assistant layer uses, `AI_TOOL_CONTRACT.md` §2).
- Serving stack candidates: vLLM (Apache-2.0, verify) for throughput on H200; llama.cpp server (MIT, verify) as simpler fallback; Ollama only for convenience. Choose by the benchmark.
- Weights: only open-weight models whose license allows our use (check each model card; record in `OPEN_SOURCE_AUDIT.md` §B). Weights never enter git.

## 3. Security baseline (before exposing anything)
1. Dedicated unprivileged Linux user and a container (Docker/Podman) with GPU access; no root in the container; read-only model dir.
2. Listen on localhost; reach it by SSH tunnel or a VPN (WireGuard/Tailscale-type, verify). No public port. If LAN exposure is needed: firewall allowlist of the owner's machines + bearer token.
3. Token in a secrets file outside git; rotate on any suspicion; never in prompts or repo (AGENTS.md).
4. Resource limits: max concurrent requests, max context, request timeout; logs without prompt bodies.
5. Agents run in a sandbox on the dev machine with only the repo worktree mounted; the model endpoint is the only network egress they need.
6. Updates: pin versions; test after every upgrade with the §4 mini-suite.

## 4. Model selection benchmark (Q-02)
Bench set `tool/model_bench/` (synthetic, in repo, ≈ 30 tasks): (a) implement a small Dart function from a spec + make given tests pass, (b) write a widget test for a given component rule, (c) fix a seeded bug from a failing test, (d) refactor with an import-lint constraint, (e) write a Persian copy-catalog entry respecting tone rules, (f) tool-calling JSON validity (AE-01 style), (g) follow AGENTS.md hard rules (no `double` money, no raw colors) — judged by `ui_check` and tests, not by opinion.
Metrics: first-pass acceptance (tests green + 0 rule violations), tokens/s, latency to first token, long-context behavior at the size AGENTS.md reading needs, tool-call validity, cost of operation (GPU hours).
Run each candidate model (2–4 open-weight coding models current at the time) with the same prompts and temperature; report in `docs/agents/MODEL_BENCH_REPORT.md`. Acceptance for L2 use: ≥ 80 % first-pass on routine tasks, 0 spec violations in the sample (AUTONOMY §6).

## 5. Connecting the agent tool
- OpenCode (candidate agent tool; confirm with the owner): configure an OpenAI-compatible provider with the tunnel URL, the model name and token; project rules come from `AGENTS.md` (it reads it natively — verify). Claude Code remains for Lead/contract/gate work.
- Each session starts with the RUNBOOK prompt (task packet path, no re-planning). Effort/size of context kept small via digests (H8).
- A local-model session may not: merge, tag, change contracts/ADRs, touch secrets, or review its own output.

## 6. Verification checklist (done = all ticked, with pasted outputs)
- [ ] `nvidia-smi` shows all GPUs; driver/CUDA recorded.
- [ ] Server starts from a clean reboot via a service unit; health endpoint answers.
- [ ] Tunnel works from the Mac; unauthenticated request is rejected.
- [ ] Tool-calling sample returns valid JSON.
- [ ] Bench run recorded; model chosen and license noted.
- [ ] OpenCode completes one real packet (T-001) on a branch; reviewed by a fresh Claude session.
- [ ] Rollback: stop service, agents fall back to Claude Code.

## 7. Open questions
LM-1 Q-01 answers. LM-2 shared-GPU policy. LM-3 power/cost limits. LM-4 backup of the server config (not weights). LM-5 whether the app's assistant (later) points to the same server (AT-P6: yes, only LAN/VPN).
