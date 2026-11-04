# ADVISOR_REPLY-004 — T-014 on-device test: CB-1 on the emulator/tooling step
- Replies to: ESC-004 (lives on `main`; raised on PR #23, branch `agent/platform-T-014-share-intent`, now merged as `c07bcf9`) · Date: 2026-11-04 · By: Advisor (scheduled run)
- Rules read: AUTONOMY_AND_ESCALATION §7 CB-1; SPIKE_PLAN "Failure handling"; T-014 acceptance criteria (clipboard-on-tap item); AG-16, AG-08. Evidence checked: `.github/workflows/spike-share.yml` step "Clipboard read only on tap" (retry only on the DDS message), `spike/T-014-share/README.md` S8, check runs on `68c7924` (head of PR #23: "android share + clipboard (emulator)" success after re-run), PR #23 merged 2026-11-04 05:08 UTC, SPIKE_REPORT on PR #27 (§items 9 and risk table cite ESC-004 as open).

## Decision
**A (device recovery + diagnostics), kept blocking, done as a small follow-up, not on PR #23.**
- PR #23 already landed under the ESC's conservative default (one manual re-run green on its head), so T-014 is closed; no change is pushed to its branch.
- B rejected: `continue-on-error` hides the real cause (emulator leaving `adb`, seen in `ff28a4f`) and would carry into M2 device jobs. C rejected: red runs and noise on every touch of these paths.

## Why
1. The last failure is not the test and not DDS: `emulator-5554` left `adb devices`; only a device-level recovery addresses that.
2. The current retry matches only the DDS string, so the second failure mode is never retried; A covers both with one bounded loop.
3. CB-1 forbids a 4th variant *inside the stuck task*; this reply releases it as one new, reviewed change (SPIKE_PLAN: "one documented mitigation").
4. M2 integration jobs will reuse this step; fixing it once in a shared script is cheaper than per-job workarounds.

## Actions
| # | File(s) | Owner hat |
|---|---|---|
| 1 | New task packet (next free T number) for the CI fix; scope `.github/workflows/spike-share.yml` and a new `tool/ci/android_device_ready.sh` only | Lead |
| 2 | `tool/ci/android_device_ready.sh`: `adb kill-server`/`start-server`, `timeout 180 adb wait-for-device`, poll `getprop sys.boot_completed` = 1 (time-limited), re-resolve the serial; on failure print `adb devices -l` and the last 200 lines of the emulator log, exit non-zero | Builder-Platform |
| 3 | `spike-share.yml`: call the script before each attempt; at most 2 attempts total; retry on the DDS message **or** "No supported devices found"; any other failure stops at once; emit `::warning` naming the cause on every retry | Builder-Platform |
| 4 | Evidence: 3 consecutive green runs of the job via `workflow_dispatch`, pasted in the PR; README S8 updated to name both failure modes and the recovery | Builder-Platform |
| 5 | SPIKE_REPORT (PR #27): change "ESC-004 open" to "answered (ADVISOR_REPLY-004), fix in follow-up task" in item 9 and the risk table | Architect (T-017) |

## Follow-ups
- If the job still fails twice in the 3-run evidence with the recovery in place, that is CB-1 again: write a new ESC with the emulator log; do not try a third variant (consider a different emulator action/API level only through that ESC).
- Lead sets `Status: CLOSED` on ESC-004 once action 4 is merged.

NEEDS_OWNER: no
