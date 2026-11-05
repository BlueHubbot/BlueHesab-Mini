# ADVISOR_REPLY-005 — T-018 on-device step: hang after the debug APK install
- Replies to: ESC-005 (lives on PR #29, branch `agent/platform-T-018-android-device-ready`) · Date: 2026-11-05 · By: Advisor (scheduled run)
- Rules read: AUTONOMY_AND_ESCALATION §7 CB-1 and CB-9, §3; SPIKE_PLAN "Failure handling"; ADVISOR_REPLY-004 Actions and Follow-ups; AG-16 (as cited in AUTONOMY_AND_ESCALATION §3.5). Evidence checked: PR #29 head `62e0d06`, check "test android (emulator)" success (2026-11-05 05:17 UTC) and spike-share run 41972293389 success; run 41897031492 (`64b3e9c`) success; run 41894184380 (`e8ba72b`) = the hang, re-run cancelled. Tally with recovery: 2 hangs in 8 runs, 1 of them before `35aba7b`.

## Decision
**A (retry once on the hang + diagnostics), done as a small follow-up after PR #29 merges, not as a third variant on PR #29.**
- PR #29 meets the ESC's own conservative default (android job green on its head `62e0d06`), so the reviewer may merge it now; ESC-004 can then be closed by the Lead.
- B rejected: leaves known red runs on every PR touching these paths while evidence is collected. C rejected for now: new unknowns and a CB-9 audit for an emulator action, without the logs to justify it.

## Why
1. The hang is a different mode (device stays `device`, install succeeds, no VM-service connection); the ADVISOR_REPLY-004 recovery cannot address it, a fresh attempt can.
2. One bounded retry (still ≤ 2 attempts, still time-limited) is the "one documented mitigation" SPIKE_PLAN allows; a second hang still fails loudly.
3. Logs from the hang are the only input that can justify C later; collect them on every hang, including attempt 1.
4. Doing it on a separate small change keeps PR #29's evidence valid and avoids a CB-1 4th variant inside T-018.

## Actions
| # | File(s) | Owner hat |
|---|---|---|
| 1 | Merge PR #29 as is (head green); set `Status: CLOSED` on ESC-004 | Reviewer / Lead |
| 2 | New task packet (next free T number); scope `.github/workflows/spike-share.yml` and `tool/ci/android_device_ready.sh` only | Lead |
| 3 | `spike-share.yml`: add the per-attempt timeout (exit 124) with `No tests ran` after a successful install to the retry causes; keep ≤ 2 attempts total; `::warning` naming "hang after install" on the retry | Builder-Platform |
| 4 | On every hang (attempt 1 and 2): print `adb devices -l`, the last 300 lines of `adb logcat -d`, and run the second attempt with `flutter test -v`; no secrets or real data in logs (CB-4) | Builder-Platform |
| 5 | Evidence: 3 consecutive green `workflow_dispatch` runs pasted in the PR; README S8 names the third mode and its retry | Builder-Platform |

## Follow-ups
- If one run hangs on both attempts, or 2 of the next 10 runs need the hang retry, that is CB-1: new ESC with the logcat output, proposing C (API level / image / maintained emulator action with an audit row, CB-9).
- Lead closes ESC-005 when Action 5 is merged; SPIKE_REPORT (PR #27) may list this hang as a known CI risk for M2 device jobs until then.

NEEDS_OWNER: no
