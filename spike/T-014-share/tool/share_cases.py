#!/usr/bin/env python3
"""T-014 (SP-07): send synthetic shares to the spike app on a device and check
that each one reached Dart exactly.

Usage:
  share_cases.py vectors                         print the expected markers
  share_cases.py run --adb ADB --package PKG     run the cases and check

`run` clears logcat, then for each case starts MainActivity with
ACTION_SEND text/plain (cold: `am start -S`, warm: app left running), waits,
dumps logcat (tag `flutter`) and compares the `SPIKE_SHARE` markers with the
code-unit length and FNV-1a 32 of the UTF-8 bytes computed here. The app logs
only length and fingerprint, never the text (CAPTURE_PIPELINE §6). Texts are
synthetic (spike/README.md §4). Standard library only. Exit 0 = all texts
arrived exactly; the warm-path source is reported, not asserted.
"""
from __future__ import annotations

import argparse
import re
import shlex
import subprocess
import sys
import time

PERSIAN = ("برداشت "
           "۱۲۳٬۴۵۰ "
           "ریال، مانده 98,765")
LONG = ("Synthetic long share 0123456789 " * 125)[:4000]

# (name, mode, text); mode "cold" force-stops the app first.
CASES = [
    ("ascii-cold", "cold", "Synthetic share 1234567890 IRR"),
    ("persian-warm", "warm", PERSIAN),
    ("persian-cold", "cold", PERSIAN),
    ("long4000-cold", "cold", LONG),
]

MARKER = re.compile(r"SPIKE_SHARE source=(\w+) chars=(\d+) fnv=([0-9a-f]{8})")


def fnv1a32_hex(text: str) -> str:
    h = 0x811C9DC5
    for byte in text.encode("utf-8"):
        h ^= byte
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f"{h:08x}"


def code_units(text: str) -> int:
    return len(text.encode("utf-16-le")) // 2


def adb(adb_path: str, *args: str, check: bool = True) -> str:
    done = subprocess.run([adb_path, *args], capture_output=True, text=True,
                          encoding="utf-8", errors="replace", check=False)
    out = (done.stdout + done.stderr).replace("\r", "")
    if check and done.returncode != 0:
        raise SystemExit(f"adb {' '.join(args)[:120]} failed: {out[-400:]}")
    return out


def send(adb_path: str, package: str, mode: str, text: str) -> str:
    component = f"{package}/.MainActivity"
    flags = "-W -S " if mode == "cold" else "-W "
    # One remote shell command; the text is single-quoted for the device shell.
    command = (f"am start {flags}-a android.intent.action.SEND -t text/plain "
               f"-n {component} --es android.intent.extra.TEXT {shlex.quote(text)}")
    return adb(adb_path, "shell", command)


def markers(adb_path: str) -> list[tuple[str, int, str]]:
    log = adb(adb_path, "logcat", "-d", "-v", "brief", "-s", "flutter:I")
    return [(m.group(1), int(m.group(2)), m.group(3)) for m in MARKER.finditer(log)]


def run(adb_path: str, package: str, settle: float) -> int:
    adb(adb_path, "logcat", "-c")
    failures = 0
    for name, mode, text in CASES:
        before = len(markers(adb_path))
        out = send(adb_path, package, mode, text)
        delivered = "delivered to currently running top-most instance" in out
        got: list[tuple[str, int, str]] = []
        for _ in range(int(settle * 2)):
            time.sleep(0.5)
            got = markers(adb_path)[before:]
            if got:
                break
        want = (code_units(text), fnv1a32_hex(text))
        if not got:
            failures += 1
            print(f"::error title=SP-07 {name}::no SPIKE_SHARE marker; am said: {out.strip()[-300:]}")
            continue
        source, chars, fnv = got[-1]
        exact = (chars, fnv) == want
        expected_source = "cold" if mode == "cold" else "warm"
        note = "" if source == expected_source else f" (source {source}, expected {expected_source})"
        line = (f"{name}: source={source} chars={chars} fnv={fnv}; expected chars={want[0]} "
                f"fnv={want[1]}; exact={exact}; onNewIntent={delivered}{note}")
        print(line)
        print(f"::notice title=SP-07 {name}::{line}")
        if not exact:
            failures += 1
            print(f"::error title=SP-07 {name}::text did not arrive exactly")
        elif note:
            print(f"::warning title=SP-07 {name}::{note.strip()}")
        time.sleep(1.0)
    print(f"cases={len(CASES)} failing={failures}")
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("vectors")
    r = sub.add_parser("run")
    r.add_argument("--adb", required=True)
    r.add_argument("--package", required=True)
    r.add_argument("--settle", type=float, default=30.0, help="seconds to wait per case")
    args = parser.parse_args()
    if args.cmd == "vectors":
        for name, mode, text in CASES:
            print(f"{name} {mode} chars={code_units(text)} fnv={fnv1a32_hex(text)}")
        return 0
    return run(args.adb, args.package, args.settle)


if __name__ == "__main__":
    sys.exit(main())
