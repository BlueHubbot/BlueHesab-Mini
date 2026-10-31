#!/usr/bin/env python3
"""T-009 (SP-09): Android cold start from `am start -W -S` output.

Usage: python3 cold_start.py <file with the concatenated am outputs>
Reads every `TotalTime: <ms>` line (one per run), prints the values, the
median, a GitHub notice and a SPIKE_EVIDENCE line. Fails if no run reported
TotalTime (the launch did not complete), never on the value itself: an
emulator on a shared runner is not the reference device (Q-09).
"""
import os
import re
import statistics
import sys


def main(argv: list[str]) -> int:
    text = open(argv[1], encoding="utf-8", errors="replace").read()
    values = [int(v) for v in re.findall(r"^TotalTime:\s*(\d+)", text, re.M)]
    statuses = re.findall(r"^Status:\s*(\S+)", text, re.M)
    if not values:
        print("::error title=T-009 cold start::no TotalTime in am output")
        print(text[-2000:])
        return 1
    med = statistics.median(values)
    line = (f"runs={len(values)} total_time_ms={','.join(map(str, values))} "
            f"median_ms={med:g} status={','.join(statuses)} (emulator API 35 x86_64, not the reference device)")
    print(f"::notice title=Cold start android::{line}")
    print(f"SPIKE_EVIDENCE cold_start {line}")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(f"\n### T-009 Android cold start\n\n{line}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
