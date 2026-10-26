#!/usr/bin/env python3
"""License scan of the resolved Dart/Flutter dependency graph (SP-11, CB-9).

Inputs (produced by `flutter pub get` and `flutter pub deps --json`):
  --deps            JSON from `flutter pub deps --json`
  --package-config  .dart_tool/package_config.json (where each package lives)
  --audit           docs/research/OPEN_SOURCE_AUDIT.md
  --report          optional path for the Markdown report

Rules (docs/research/OPEN_SOURCE_AUDIT.md §C, ADR-0007):
  * Every package in the graph is listed with the license found in its files.
  * Copyleft (GPL, AGPL, LGPL, MPL, EPL, CDDL...), unknown or missing
    licenses fail the scan. LGPL/MPL need a review, so they fail too until an
    exception is recorded.
  * Packages from the Flutter SDK (source "sdk") are covered by the SDK row in
    the audit. `sky_engine` ships the engine's aggregated third-party notices;
    it is listed as SDK_NOTICES and never classified by keyword.
  * CB-9: every direct or dev dependency that is not from the SDK must be
    named in the audit file.

Standard library only, so it runs on any CI image. Exit code 0 = pass.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlparse

LICENSE_FILE_NAMES = (
    "LICENSE", "LICENSE.md", "LICENSE.txt", "LICENCE", "LICENCE.md",
    "COPYING", "COPYING.md", "OFL.txt", "LICENSE-MIT", "LICENSE-APACHE",
)

# (spdx, pattern) — copyleft first; a file that matches both a copyleft and a
# permissive pattern is reported as DUAL and fails until reviewed.
COPYLEFT = [
    ("AGPL", r"GNU\s+AFFERO\s+GENERAL\s+PUBLIC\s+LICENSE"),
    ("LGPL", r"GNU\s+(LESSER|LIBRARY)\s+GENERAL\s+PUBLIC\s+LICENSE"),
    ("GPL", r"GNU\s+GENERAL\s+PUBLIC\s+LICENSE"),
    ("MPL", r"Mozilla\s+Public\s+License"),
    ("EPL", r"Eclipse\s+Public\s+License"),
    ("CDDL", r"COMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+LICENSE"),
    ("EUPL", r"European\s+Union\s+Public\s+Licen[cs]e"),
    ("SSPL", r"Server\s+Side\s+Public\s+License"),
]
PERMISSIVE = [
    ("Apache-2.0", r"Apache\s+License,?\s+Version\s+2\.0"),
    ("MIT", r"Permission\s+is\s+hereby\s+granted,\s+free\s+of\s+charge"),
    ("BSD-3-Clause", r"Redistribution\s+and\s+use\s+in\s+source\s+and\s+binary"
                     r"[\s\S]*Neither\s+the\s+name"),
    ("BSD-2-Clause", r"Redistribution\s+and\s+use\s+in\s+source\s+and\s+binary"),
    ("ISC", r"Permission\s+to\s+use,\s+copy,\s+modify,\s+and(/or)?\s+distribute"
            r"\s+this\s+software\s+for\s+any\s+purpose"),
    ("OFL-1.1", r"SIL\s+OPEN\s+FONT\s+LICENSE"),
    ("Zlib", r"altered\s+source\s+versions\s+must\s+be\s+plainly\s+marked"),
    ("Unlicense", r"This\s+is\s+free\s+and\s+unencumbered\s+software"),
]

PASS_STATES = {"OK", "SDK", "SDK_NOTICES"}


@dataclass
class Row:
    name: str
    version: str
    kind: str
    source: str
    license: str
    state: str
    note: str = ""


def classify(text: str) -> tuple[str, str]:
    """Return (license, state) for the text of a license file."""
    copyleft = [spdx for spdx, pat in COPYLEFT if re.search(pat, text, re.I)]
    permissive = [spdx for spdx, pat in PERMISSIVE if re.search(pat, text, re.I)]
    if copyleft and permissive:
        return f"{permissive[0]} + {copyleft[0]}", "DUAL"
    if copyleft:
        return copyleft[0], "COPYLEFT"
    if permissive:
        return permissive[0], "OK"
    return "unknown", "UNKNOWN"


def package_roots(config_path: Path) -> dict[str, Path]:
    data = json.loads(config_path.read_text(encoding="utf-8"))
    roots: dict[str, Path] = {}
    for pkg in data.get("packages", []):
        uri = pkg["rootUri"]
        if uri.startswith("file:"):
            parsed = urlparse(uri)
            path = unquote(parsed.path)
            # file:///C:/x on Windows parses to "/C:/x".
            if re.match(r"^/[A-Za-z]:/", path):
                path = path[1:]
            root = Path(path)
        else:
            root = (config_path.parent / unquote(uri)).resolve()
        roots[pkg["name"]] = root
    return roots


def read_license(root: Path) -> str | None:
    for name in LICENSE_FILE_NAMES:
        candidate = root / name
        if candidate.is_file():
            return candidate.read_text(encoding="utf-8", errors="replace")
    return None


def audit_names(audit_text: str) -> set[str]:
    return {tok.lower() for tok in re.findall(r"[A-Za-z0-9_]+", audit_text)}


def scan(deps: dict, roots: dict[str, Path], audit_text: str) -> list[Row]:
    root_pkg = deps.get("root")
    named = audit_names(audit_text)
    rows: list[Row] = []
    for pkg in sorted(deps.get("packages", []), key=lambda p: p["name"]):
        name = pkg["name"]
        if name == root_pkg:
            continue
        kind = pkg.get("kind", "?")
        source = pkg.get("source", "?")
        version = str(pkg.get("version", "?"))
        if source == "sdk":
            if name == "sky_engine":
                rows.append(Row(name, version, kind, source,
                                "Flutter engine third-party notices",
                                "SDK_NOTICES",
                                "covered by the Flutter SDK audit row"))
            else:
                root = roots.get(name)
                text = read_license(root) if root else None
                lic = classify(text)[0] if text else "BSD-3-Clause (Flutter SDK)"
                rows.append(Row(name, version, kind, source, lic, "SDK"))
            continue
        root = roots.get(name)
        text = read_license(root) if root else None
        if text is None:
            rows.append(Row(name, version, kind, source, "missing", "MISSING",
                            f"no license file in {root}"))
            continue
        lic, state = classify(text)
        row = Row(name, version, kind, source, lic, state)
        if kind in ("direct", "dev") and name.lower() not in named:
            row.state = "NO_AUDIT_ROW"
            row.note = "CB-9: add a row to docs/research/OPEN_SOURCE_AUDIT.md"
        rows.append(row)
    return rows


def to_markdown(rows: list[Row]) -> str:
    failed = [r for r in rows if r.state not in PASS_STATES]
    lines = [
        "## License scan (SP-11, CB-9)",
        "",
        f"Packages: {len(rows)} · failing: {len(failed)}",
        "",
        "| Package | Version | Kind | Source | License | State | Note |",
        "|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        lines.append(f"| {r.name} | {r.version} | {r.kind} | {r.source} | "
                     f"{r.license} | {r.state} | {r.note} |")
    lines.append("")
    lines.append("Result: " + ("PASS" if not failed else "FAIL"))
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--deps", required=True, type=Path)
    ap.add_argument("--package-config", required=True, type=Path)
    ap.add_argument("--audit", required=True, type=Path)
    ap.add_argument("--report", type=Path)
    args = ap.parse_args(argv)

    deps = json.loads(args.deps.read_text(encoding="utf-8"))
    rows = scan(deps, package_roots(args.package_config),
                args.audit.read_text(encoding="utf-8"))
    report = to_markdown(rows)
    sys.stdout.write(report)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report, encoding="utf-8")
    failed = [r for r in rows if r.state not in PASS_STATES]
    if os.environ.get("GITHUB_ACTIONS") == "true":
        listed = "; ".join(f"{r.name} {r.version} {r.license} {r.state}"
                           for r in rows)
        print(f"::notice title=License scan ({len(rows)} packages, "
              f"{len(failed)} failing)::{listed}")
        for r in failed[:10]:
            print(f"::error title=License scan::{r.name} {r.version}: "
                  f"{r.license} ({r.state}) {r.note}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
