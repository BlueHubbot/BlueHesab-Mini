#!/usr/bin/env python3
"""Self-test of tool/ci/license_scan.py (SP-11, CB-9). Synthetic data only.

Each failing rule has a negative control, so a scanner that passes
everything is caught.
"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import license_scan as ls  # noqa: E402

MIT = ("Permission is hereby granted, free of charge, to any person obtaining "
       "a copy of this software")
BSD3 = ("Redistribution and use in source and binary forms, with or without "
        "modification, are permitted ... Neither the name of Google LLC nor")
APACHE = "Apache License\nVersion 2.0, January 2004"
APACHE_INLINE = "Licensed under the Apache License, Version 2.0 (the License)"
GPL = "GNU GENERAL PUBLIC LICENSE\nVersion 3, 29 June 2007"
AGPL = "GNU AFFERO GENERAL PUBLIC LICENSE Version 3"
LGPL = "GNU LESSER GENERAL PUBLIC LICENSE Version 2.1"
MPL = "Mozilla Public License Version 2.0"
OFL = "SIL OPEN FONT LICENSE Version 1.1"


class ClassifyTest(unittest.TestCase):
    def test_permissive(self):
        self.assertEqual(ls.classify(MIT), ("MIT", "OK"))
        self.assertEqual(ls.classify(BSD3), ("BSD-3-Clause", "OK"))
        self.assertEqual(ls.classify(APACHE_INLINE)[1], "OK")
        self.assertEqual(ls.classify(OFL), ("OFL-1.1", "OK"))

    def test_copyleft(self):
        self.assertEqual(ls.classify(GPL), ("GPL", "COPYLEFT"))
        self.assertEqual(ls.classify(AGPL), ("AGPL", "COPYLEFT"))
        self.assertEqual(ls.classify(LGPL), ("LGPL", "COPYLEFT"))
        self.assertEqual(ls.classify(MPL), ("MPL", "COPYLEFT"))

    def test_dual_and_unknown(self):
        self.assertEqual(ls.classify(MIT + "\n" + GPL)[1], "DUAL")
        self.assertEqual(ls.classify("All rights reserved."), ("unknown", "UNKNOWN"))


class ScanTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.base = Path(self.tmp.name)
        self.config = self.base / "app" / ".dart_tool" / "package_config.json"
        self.config.parent.mkdir(parents=True)
        self.packages: list[dict] = []
        self.deps: list[dict] = [{"name": "app", "kind": "root", "source": "root",
                                  "version": "0.0.1"}]

    def tearDown(self):
        self.tmp.cleanup()

    def add(self, name, license_text, kind="transitive", source="hosted",
            file_name="LICENSE"):
        root = self.base / "cache" / name
        root.mkdir(parents=True)
        if license_text is not None:
            (root / file_name).write_text(license_text, encoding="utf-8")
        self.packages.append({"name": name, "rootUri": root.as_uri()})
        self.deps.append({"name": name, "kind": kind, "source": source,
                          "version": "1.0.0"})

    def run_scan(self, audit="| drift | MIT |"):
        self.config.write_text(json.dumps({"packages": self.packages}))
        rows = ls.scan({"root": "app", "packages": self.deps},
                       ls.package_roots(self.config), audit)
        return {r.name: r for r in rows}

    def test_root_is_skipped_and_permissive_passes(self):
        self.add("collection", BSD3)
        self.add("meta", MIT, file_name="LICENSE.md")
        rows = self.run_scan()
        self.assertNotIn("app", rows)
        self.assertEqual(rows["collection"].state, "OK")
        self.assertEqual(rows["meta"].state, "OK")

    def test_copyleft_missing_unknown_fail(self):
        self.add("bad_gpl", GPL)
        self.add("no_file", None)
        self.add("odd", "Proprietary. All rights reserved.")
        rows = self.run_scan()
        self.assertEqual(rows["bad_gpl"].state, "COPYLEFT")
        self.assertEqual(rows["no_file"].state, "MISSING")
        self.assertEqual(rows["odd"].state, "UNKNOWN")
        for r in rows.values():
            self.assertNotIn(r.state, ls.PASS_STATES)

    def test_cb9_direct_dependency_needs_audit_row(self):
        self.add("drift", MIT, kind="direct")
        self.add("riverpod", MIT, kind="direct")
        self.add("lints", BSD3, kind="dev")
        rows = self.run_scan(audit="| drift (pub.dev) | SQLite layer | MIT |")
        self.assertEqual(rows["drift"].state, "OK")
        self.assertEqual(rows["riverpod"].state, "NO_AUDIT_ROW")
        self.assertEqual(rows["lints"].state, "NO_AUDIT_ROW")

    def test_cb9_ignores_transitive(self):
        self.add("path", BSD3, kind="transitive")
        self.assertEqual(self.run_scan(audit="")["path"].state, "OK")

    def test_sdk_packages(self):
        self.add("flutter", BSD3, kind="direct", source="sdk")
        # The engine notices may mention GPL (dual-licensed parts); never
        # classified by keyword, always listed.
        self.add("sky_engine", MIT + GPL, source="sdk")
        rows = self.run_scan(audit="")
        self.assertEqual(rows["flutter"].state, "SDK")
        self.assertEqual(rows["flutter"].license, "BSD-3-Clause")
        self.assertEqual(rows["sky_engine"].state, "SDK_NOTICES")

    def test_relative_root_uri(self):
        root = self.config.parent.parent  # the app itself, "../"
        (root / "LICENSE").write_text(APACHE, encoding="utf-8")
        self.packages.append({"name": "app", "rootUri": "../"})
        self.config.write_text(json.dumps({"packages": self.packages}))
        roots = ls.package_roots(self.config)
        self.assertEqual(roots["app"], root.resolve())

    def test_main_exit_codes_and_report(self):
        self.add("collection", BSD3)
        self.config.write_text(json.dumps({"packages": self.packages}))
        deps = self.base / "deps.json"
        audit = self.base / "audit.md"
        report = self.base / "out" / "report.md"
        audit.write_text("", encoding="utf-8")
        deps.write_text(json.dumps({"root": "app", "packages": self.deps}))
        args = ["--deps", str(deps), "--package-config", str(self.config),
                "--audit", str(audit), "--report", str(report)]
        self.assertEqual(ls.main(args), 0)
        self.assertIn("Result: PASS", report.read_text(encoding="utf-8"))
        self.add("bad", AGPL)
        self.config.write_text(json.dumps({"packages": self.packages}))
        deps.write_text(json.dumps({"root": "app", "packages": self.deps}))
        self.assertEqual(ls.main(args), 1)
        self.assertIn("Result: FAIL", report.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
