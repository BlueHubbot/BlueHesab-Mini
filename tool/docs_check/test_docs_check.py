#!/usr/bin/env python3
"""Self-test for docs_check.py and check_data_model_ddl.py (standard library only, no network, a few seconds).

Every test copies the repository to a temporary folder, breaks exactly one thing and checks that
docs_check reports the expected code. The first test checks that the real repository is clean,
so this file is also the guard that the checks keep working: a check that can no longer fail
is a check that proves nothing.

Usage:  python3 tool/docs_check/test_docs_check.py
"""
import hashlib
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHECK = "tool/docs_check/docs_check.py"
IGNORE = shutil.ignore_patterns(".git", "__pycache__", "*.pyc", ".dart_tool", "build", "node_modules")

RLO = chr(0x202E)  # right-to-left override (Trojan-source character)
LRM = chr(0x200E)  # left-to-right mark
ARABIC_KAF = chr(0x0643)  # Arabic kaf, wrong in Persian text (WR-02)


class Sandbox:
    """A throw-away copy of the repository."""

    def __init__(self):
        self._tmp = tempfile.TemporaryDirectory(prefix="docs_check_test_")
        self.root = Path(self._tmp.name) / "repo"
        shutil.copytree(REPO, self.root, ignore=IGNORE)

    def close(self):
        self._tmp.cleanup()

    def path(self, rel):
        return self.root / rel

    def read(self, rel):
        return self.path(rel).read_text(encoding="utf-8")

    def write(self, rel, text):
        p = self.path(rel)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8", newline="")

    def append(self, rel, text):
        self.write(rel, self.read(rel) + text)

    def replace_once(self, rel, old, new):
        text = self.read(rel)
        assert text.count(old) == 1, f"{rel}: expected exactly one {old!r}"
        self.write(rel, text.replace(old, new))

    def run(self, *args):
        p = subprocess.run([sys.executable, "-I", str(self.root / CHECK), *args],
                           cwd=self.root, capture_output=True, text=True, timeout=180)
        return p.returncode, p.stdout + p.stderr

    def snapshot(self):
        h = hashlib.sha256()
        for p in sorted(self.root.rglob("*")):
            if p.is_file():
                h.update(str(p.relative_to(self.root)).encode("utf-8"))
                h.update(p.read_bytes())
        return h.hexdigest()


class CheckCase(unittest.TestCase):
    def setUp(self):
        self.sb = Sandbox()
        self.addCleanup(self.sb.close)

    def expect(self, pattern, *args, code=1):
        """Run docs_check with args; require exit code and an output line matching pattern."""
        rc, out = self.sb.run(*args)
        self.assertEqual(rc, code, out)
        self.assertRegex(out, pattern, out)
        return out


class Baseline(CheckCase):
    def test_real_repository_is_clean(self):
        rc, out = self.sb.run("--strict")
        self.assertEqual(rc, 0, out)
        self.assertIn("0 error(s), 0 warning(s)", out)

    def test_checker_is_read_only(self):
        before = self.sb.snapshot()
        self.sb.run("--strict", "--spec-report")
        self.assertEqual(before, self.sb.snapshot(), "docs_check must never modify files")

    def test_spec_report_prints_s1(self):
        rc, out = self.sb.run("--spec-report")
        self.assertEqual(rc, 0, out)
        self.assertRegex(out, r"S1 spec ids referenced but not defined as a row/bullet \(\d+\)")

    def test_tool_files_have_no_hidden_characters(self):
        forbidden = (set(range(0x202A, 0x202F)) | set(range(0x2066, 0x206A))
                     | {0x200E, 0x200F, 0x061C, 0xFEFF, 0x0643, 0x064A, 0x0640, 0x0649})
        for name in ("docs_check.py", "test_docs_check.py", "check_data_model_ddl.py"):
            text = (REPO / "tool/docs_check" / name).read_text(encoding="utf-8")
            found = sorted({hex(ord(c)) for c in text if ord(c) in forbidden})
            self.assertEqual(found, [], f"{name} contains hidden or Arabic-letter characters; build them with chr()")


class Links(CheckCase):
    def test_l1_broken_markdown_link(self):
        self.sb.append("docs/GLOSSARY.md", "\n[broken](no_such_file.md)\n")
        self.expect(r"ERROR L1 docs/GLOSSARY\.md: broken link -> no_such_file\.md")

    def test_l2_missing_backticked_path(self):
        self.sb.append("docs/GLOSSARY.md", "\nSee `docs/no_such_doc.md`.\n")
        self.expect(r"ERROR L2 docs/GLOSSARY\.md: referenced path not found: docs/no_such_doc\.md")

    def test_l3_and_l4_new_document_not_indexed(self):
        self.sb.write("docs/NEW_TOPIC.md", "# New topic\n")
        out = self.expect(r"WARN\s+L3 docs/NEW_TOPIC\.md", "--strict")
        self.assertRegex(out, r"WARN\s+L4 docs/NEW_TOPIC\.md")

    def test_warnings_fail_only_with_strict(self):
        self.sb.write("docs/NEW_TOPIC.md", "# New topic\n")
        rc, out = self.sb.run()
        self.assertEqual(rc, 0, out)
        self.assertIn("WARN", out)
        rc, out = self.sb.run("--strict")
        self.assertEqual(rc, 1, out)

    def test_l4_map_lists_a_document_that_does_not_exist(self):
        self.sb.append("docs/PROJECT_FILE_MAP.md", "\nGHOST_DOC.md\n")
        self.expect(r"ERROR L4 docs/PROJECT_FILE_MAP\.md: lists a document that does not exist: GHOST_DOC\.md")


class References(CheckCase):
    def test_r1_unknown_adr(self):
        self.sb.append("docs/GLOSSARY.md", "\nSee ADR-9999 and ADR-UI-999.\n")
        out = self.expect(r"ERROR R1 docs/GLOSSARY\.md: unknown ADR-9999")
        self.assertRegex(out, r"ERROR R1 docs/GLOSSARY\.md: unknown ADR-UI-999")

    def test_r2_unknown_question(self):
        self.sb.append("docs/GLOSSARY.md", "\nSee Q-99.\n")
        self.expect(r"ERROR R2 docs/GLOSSARY\.md: unknown question id Q-99")

    def test_r3_unknown_spec_rule(self):
        self.sb.append("docs/GLOSSARY.md", "\nSee QD-99.\n")
        self.expect(r"ERROR R3 docs/GLOSSARY\.md: rule id not found in UI spec: QD-99")

    def test_r4_unknown_requirement_and_risk(self):
        self.sb.append("docs/GLOSSARY.md", "\nSee CORE-999 and R-999.\n")
        out = self.expect(r"ERROR R4 docs/GLOSSARY\.md: requirement id not in REQUIREMENTS\.md: CORE-999")
        self.assertRegex(out, r"ERROR R4 docs/GLOSSARY\.md: risk id not in RISKS_AND_ASSUMPTIONS\.md: R-999")

    def test_r5_undefined_contract_ids(self):
        self.sb.append("docs/GLOSSARY.md", "\nSee DD-99, CB-99 and SE-99.\n")
        out = self.expect(r"ERROR R5 docs/GLOSSARY\.md: contract id never defined: DD-99")
        self.assertRegex(out, r"contract id never defined: CB-99")
        self.assertRegex(out, r"contract id never defined: SE-99")

    def test_d1_duplicate_definition(self):
        self.sb.append("docs/GLOSSARY.md", "\n- **DD-01:** a second definition.\n")
        self.expect(r"ERROR D1 docs/[^:]+: DD-01 also defined in docs/")


class HiddenText(CheckCase):
    def test_r6_bidi_override_in_markdown(self):
        self.sb.append("docs/GLOSSARY.md", f"\nlook {RLO}here\n")
        self.expect(r"ERROR R6 docs/GLOSSARY\.md: hidden bidi/BOM character U\+202E")

    def test_r6_direction_mark_outside_allow_list(self):
        self.sb.append("docs/GLOSSARY.md", f"\nmark{LRM}\n")
        self.expect(r"ERROR R6 docs/GLOSSARY\.md: raw direction mark U\+200E")

    def test_r6_hidden_character_in_code_file(self):
        self.sb.write("tool/sample.py", f"x = 1  # {RLO}\n")
        self.expect(r"ERROR R6 tool/sample\.py: hidden character U\+202E")

    def test_r7_arabic_letter_in_persian_text(self):
        self.sb.append("docs/GLOSSARY.md", f"\nنوشته {ARABIC_KAF}تاب\n")
        self.expect(r"WARN\s+R7 docs/GLOSSARY\.md", "--strict")

    def test_r7_line_that_talks_about_arabic_letters_is_exempt(self):
        self.sb.append("docs/GLOSSARY.md", f"\nArabic kaf looks like {ARABIC_KAF}\n")
        rc, out = self.sb.run("--strict")
        self.assertEqual(rc, 0, out)


class Tokens(CheckCase):
    TOKENS = "design/tokens/design_tokens.json"
    APPENDIX = "docs/design/ui-spec/A-appendix-tokens.md"

    def test_t1_changed_color_without_new_checksum(self):
        text = self.sb.read(self.TOKENS)
        m = re.search(r"#[0-9A-Fa-f]{6}", text)
        flipped = m.group(0)[:-1] + ("1" if m.group(0)[-1] == "0" else "0")
        self.sb.write(self.TOKENS, text.replace(m.group(0), flipped, 1))
        self.expect(r"ERROR T1 design/tokens/design_tokens\.json: checksum mismatch")

    def test_t1_crlf_line_endings(self):
        text = self.sb.read(self.TOKENS)
        self.sb.path(self.TOKENS).write_bytes(text.replace("\n", "\r\n").encode("utf-8"))
        self.expect(r"ERROR T1 design/tokens/design_tokens\.json: CRLF line endings")

    def test_t2_wrong_contrast_number_in_appendix(self):
        lines = self.sb.read(self.APPENDIX).split("\n")
        i = next(k for k, line in enumerate(lines) if line.startswith("| VTG-01"))
        cells = lines[i].split("|")
        cells[4] = " " + "".join(chr(c) for c in (0x6F9, 0x6F9, 0x66B, 0x6F9, 0x6F9)) + " "  # 99.99 in Persian digits
        lines[i] = "|".join(cells)
        self.sb.write(self.APPENDIX, "\n".join(lines))
        self.expect(r"ERROR T2 docs/design/ui-spec/A-appendix-tokens\.md: VTG-01 row 1 light: table 99\.99")


class DataModelDdl(CheckCase):
    """check_data_model_ddl.py must pass on the real contract and must fail when a constraint is weakened."""
    SCRIPT = "tool/docs_check/check_data_model_ddl.py"
    MODEL = "docs/architecture/DATA_MODEL.md"

    def run_ddl(self):
        p = subprocess.run([sys.executable, "-I", str(self.sb.root / self.SCRIPT)],
                           cwd=self.sb.root, capture_output=True, text=True, timeout=120)
        return p.returncode, p.stdout + p.stderr

    def test_real_data_model_holds(self):
        rc, out = self.run_ddl()
        self.assertEqual(rc, 0, out)
        self.assertRegex(out, r"\d+ expectation\(s\) checked, 0 failure\(s\)")

    def test_amount_cap_raised_to_19_digits_is_detected(self):
        self.sb.replace_once(self.MODEL, "length(amount_minor) <= 18", "length(amount_minor) <= 19")
        rc, out = self.run_ddl()
        self.assertEqual(rc, 1, out)
        self.assertRegex(out, r"FAIL amount_minor '9{19}' must be rejected")

    def test_opening_balance_leading_zero_hole_is_detected(self):
        self.sb.replace_once(self.MODEL, "opening_balance_minor GLOB '[1-9]*' AND", "opening_balance_minor GLOB '[0-9]*' AND")
        rc, out = self.run_ddl()
        self.assertEqual(rc, 1, out)
        self.assertRegex(out, r"FAIL opening_balance_minor '05' must be rejected")

    def test_dropped_transfer_rule_is_detected(self):
        self.sb.replace_once(self.MODEL, "CHECK (to_account_id IS NULL OR to_account_id <> account_id)", "CHECK (1)")
        rc, out = self.run_ddl()
        self.assertEqual(rc, 1, out)
        self.assertRegex(out, r"FAIL transfer to the same account must be rejected")


if __name__ == "__main__":
    unittest.main(verbosity=2)
