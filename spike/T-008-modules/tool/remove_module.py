#!/usr/bin/env python3
"""MDC-T7 in CI: remove one module from this spike's checkout.

Deletes the lines tagged `// module:<id>` in lib/app/module_list.dart, the
folder lib/modules/<id>/ and every test file that names the module, then
prints what it removed. The core is not touched. Run from the package root:
    python3 -I tool/remove_module.py budget
Only for a CI job's throw-away checkout; never commit its result.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path


def main(argv: list[str]) -> int:
    if len(argv) != 1 or not argv[0].isidentifier():
        print("usage: remove_module.py <module id>", file=sys.stderr)
        return 2
    module = argv[0]
    tag = f"// module:{module}"
    listing = Path("lib/app/module_list.dart")
    lines = listing.read_text(encoding="utf-8").splitlines(keepends=True)
    kept = [line for line in lines if tag not in line]
    removed = len(lines) - len(kept)
    if removed == 0:
        print(f"no line tagged {tag!r} in {listing}", file=sys.stderr)
        return 1
    listing.write_text("".join(kept), encoding="utf-8")
    print(f"{listing}: removed {removed} line(s) tagged {tag!r}")

    folder = Path("lib/modules") / module
    shutil.rmtree(folder)
    print(f"deleted {folder}/")

    needle = f"modules/{module}/"
    for test in sorted(Path("test").glob("*.dart")):
        if needle in test.read_text(encoding="utf-8"):
            test.unlink()
            print(f"deleted {test} (names the module)")

    for path in sorted(Path("lib").rglob("*.dart")):
        if needle in path.read_text(encoding="utf-8"):
            print(f"{path} still names the module", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
