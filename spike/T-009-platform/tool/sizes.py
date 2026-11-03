#!/usr/bin/env python3
"""T-009 (SP-09): print the size of build outputs as CI evidence.

Usage: python3 sizes.py <os-label> <label>=<path> [<label>=<path> ...]
A path may be a file or a directory (summed recursively, symlinks not
followed). Prints one GitHub notice per item, one SPIKE_EVIDENCE line and a
Markdown table into $GITHUB_STEP_SUMMARY when it is set. Standard library
only. The APK soft limit (SP-09: flag if > 50 MB) is reported, never failed.
"""
import os
import sys

APK_SOFT_LIMIT = 50 * 1000 * 1000  # SP-09 "flag if APK > 50 MB (soft)"; decimal MB


def size_of(path: str) -> int:
    if os.path.isfile(path):
        return os.path.getsize(path)
    total = 0
    for root, _dirs, files in os.walk(path, followlinks=False):
        for name in files:
            full = os.path.join(root, name)
            if not os.path.islink(full):
                total += os.path.getsize(full)
    return total


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    os_label = argv[1]
    rows = []
    for item in argv[2:]:
        label, _, path = item.partition("=")
        if not os.path.exists(path):
            print(f"::error title=T-009 size::{label}: missing {path}")
            return 1
        n = size_of(path)
        flag = ""
        if path.endswith(".apk") and n > APK_SOFT_LIMIT:
            flag = " FLAG>50MB"
        rows.append((label, n, flag))
        print(f"::notice title=Size {os_label} {label}::{n} bytes = {n / 1e6:.2f} MB{flag}")
    print("SPIKE_EVIDENCE sizes os=" + os_label + " " +
          " ".join(f"{label}={n}{flag.strip() and ':' + flag.strip()}" for label, n, flag in rows))
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(f"\n### T-009 sizes ({os_label})\n\n| item | bytes | MB |\n|---|---:|---:|\n")
            for label, n, flag in rows:
                fh.write(f"| {label}{flag} | {n} | {n / 1e6:.2f} |\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
