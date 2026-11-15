#!/usr/bin/env python3
"""T-031 (SP-09): time desktop app start to the first rasterized frame.

measure EXE [--runs N] [--timeout S] [--label L]
    Launch EXE N times (default 5). Each run must end with exit code 37
    (the marker of first_frame_main.dart) within S seconds (default 60).
    Prints every value in ms, the median and one SPIKE_EVIDENCE line.

control EXE [--wait S] [--label L]
    Negative control: launch EXE (the unchanged root app, no marker) and
    require that it is still running after S seconds (default 20); then
    stop it. Proves that a pass needs the marker.

Standard library only (CB-9). Synthetic: the app shows an empty page.
"""
import argparse
import statistics
import subprocess
import sys
import time

MARKER_EXIT = 37


def _notice(title, text):
    print(f"::notice title={title}::{text}", flush=True)


def _error(title, text):
    print(f"::error title={title}::{text}", flush=True)


def measure(exe, runs, timeout, label):
    values = []
    for i in range(1, runs + 1):
        start = time.perf_counter()
        proc = subprocess.Popen([exe], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            code = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
            _error(f"{label} start time", f"run {i}: no exit within {timeout} s (first frame never rasterized?)")
            return 1
        ms = (time.perf_counter() - start) * 1000.0
        if code != MARKER_EXIT:
            _error(f"{label} start time", f"run {i}: exit code {code}, expected {MARKER_EXIT}")
            return 1
        values.append(round(ms))
        print(f"run {i}: {round(ms)} ms (exit {code})", flush=True)
        time.sleep(2)
    med = round(statistics.median(values))
    _notice(f"{label} start time", f"median {med} ms; runs {values}")
    print(f"SPIKE_EVIDENCE {label}_first_frame_ms median={med} runs={','.join(map(str, values))} exit_code={MARKER_EXIT}", flush=True)
    return 0


def control(exe, wait, label):
    proc = subprocess.Popen([exe], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(wait)
    code = proc.poll()
    if code is not None:
        _error(f"{label} negative control", f"the app without marker exited with code {code} within {wait} s")
        return 1
    proc.kill()
    proc.wait()
    _notice(f"{label} negative control", f"app without marker still running after {wait} s, as expected; stopped")
    return 0


def main(argv):
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("measure")
    m.add_argument("exe")
    m.add_argument("--runs", type=int, default=5)
    m.add_argument("--timeout", type=float, default=60.0)
    m.add_argument("--label", default="desktop")
    c = sub.add_parser("control")
    c.add_argument("exe")
    c.add_argument("--wait", type=float, default=20.0)
    c.add_argument("--label", default="desktop")
    a = p.parse_args(argv)
    if a.cmd == "measure":
        return measure(a.exe, a.runs, a.timeout, a.label)
    return control(a.exe, a.wait, a.label)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
