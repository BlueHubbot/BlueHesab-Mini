#!/usr/bin/env python3
"""docs_check - repeatable consistency checks for BlueHesab Mini documentation (v2).

Usage:  python3 tool/docs_check/docs_check.py [--strict] [--spec-report]
Exit code 1 if any ERROR is found (WARN fails only with --strict).
Standard library only. Read-only: never modifies files. Zero tokens, runs in about a second.

Checks (what each one proves is explained in docs/ops/CONSISTENCY_AUDIT.md):
  L1  relative Markdown links resolve
  L2  backticked repo paths under docs/, design/ and top-level docs resolve (future code paths are skipped)
  L3  every doc under docs/ is listed in docs/README.md (the index cannot rot silently)
  L4  docs/PROJECT_FILE_MAP.md lists every project doc, and lists no document that does not exist
  R1  ADR-NNNN / ADR-UI-NNN references exist in the ADR index
  R2  Q-NN / Q-CN references exist in docs/ops/OPEN_QUESTIONS.md
  R3  two-digit UI-spec rule IDs cited outside the spec exist in the spec
  R4  requirement IDs (CORE-001 ...) and risk IDs (R-001 ...) cited anywhere are defined
  R5  contract IDs (DD-, MG-, I-, MDC-, CPX-, AT-, AE-, CB-, SE-) cited anywhere are defined
  R6  hidden bidi/BOM characters (Trojan-source style) in docs, code and config; raw LRM/RLM only in the allow-listed spec file
  R7  Arabic yeh/kaf/tatweel in Persian text (WR-02), except lines that talk about them
  D1  IDs *defined* in project docs are unique and do not collide with spec definitions
  T1  design_tokens.json checksum (AX-02) is intact and the file is LF only
  T2  contrast numbers of spec appendix A-4 (VTG groups, AX-06 totals, the 210 count) recomputed from the tokens
  S1  (--spec-report) rule IDs referenced inside the spec but never defined there
"""
import hashlib, json, re, sys
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / "docs/design/ui-spec"
errors, warns = [], []

def err(code, f, msg): errors.append(f"ERROR {code} {f}: {msg}")
def warn(code, f, msg): warns.append(f"WARN  {code} {f}: {msg}")

def md_files(base):
    return sorted(p for p in base.rglob("*.md") if ".git" not in p.parts)

ALL_MD = md_files(ROOT)
NON_SPEC_MD = [p for p in ALL_MD if SPEC not in p.parents]
rel = lambda p: str(p.relative_to(ROOT))
read = lambda p: p.read_text(encoding="utf-8")

# ---------- spec ID sets ----------
spec_text = "\n".join(read(p) for p in md_files(SPEC))
ID2 = re.compile(r"\b([A-Z]{1,5}X?-\d{2})\b")
spec_ids = set(ID2.findall(spec_text))
def_re = re.compile(r"^(?:[-*] )?(?:\*\*|\| ?`?)([A-Z]{1,5}X?-\d{2})\b", re.M)
spec_defs = set(def_re.findall(spec_text))

# ---------- ADR index ----------
adr_index = read(ROOT / "docs/architecture/ADR/README.md")
adr_nums = set()
for m in re.finditer(r"ADR-(\d{4})(?:\s*…\s*(?:ADR-)?(\d{4}))?", adr_index):
    a = int(m.group(1)); b = int(m.group(2) or a); adr_nums.update(range(a, b + 1))
adr_ui = set()
for m in re.finditer(r"ADR-UI-(\d{3})(?:\s*…\s*(\d{3}))?", adr_index):
    a = int(m.group(1)); b = int(m.group(2) or a); adr_ui.update(range(a, b + 1))

# ---------- Q ids ----------
oq = read(ROOT / "docs/ops/OPEN_QUESTIONS.md")
q_ids = set(re.findall(r"\b(Q-(?:C?\d{1,2}))\b", oq))

# ---------- requirement and risk ids ----------
REQ_PREFIXES = ("CORE", "UI", "FIN", "AI", "PRIV", "MOD", "SYNC", "NOTIF", "PLAT", "CAPT")
req_text = read(ROOT / "docs/REQUIREMENTS.md") if (ROOT / "docs/REQUIREMENTS.md").exists() else ""
req_ids = set(re.findall(r"\b([A-Z]{2,5}-\d{3})\b", req_text))
risk_text = read(ROOT / "docs/RISKS_AND_ASSUMPTIONS.md") if (ROOT / "docs/RISKS_AND_ASSUMPTIONS.md").exists() else ""
risk_ids = set(re.findall(r"\b(R-\d{3})\b", risk_text))

OWN_PREFIXES = {  # namespaces defined by project docs outside the UI spec
    "DD", "MG", "I", "MDC", "CAP", "CPX", "AT", "AE", "CB", "SE", "S", "Q", "R", "ESC", "T", "SP", "LM", "D",
    "P", "F", "U", "M", "H", "E", "X", "PI", "RV", "G", "BR", "AQ", "MQ", "DQ", "CP", "L",
}
FUTURE_DOC_PATHS = {  # documented but intentionally not created yet
    "docs/architecture/SPIKE_REPORT.md", "docs/agents/MODEL_BENCH_REPORT.md",
}
FUTURE_PREFIXES = ("lib/", "test/", "tool/", "spike/", "assets/", "android/", "windows/", "macos/", "ios/",
                   "web/", "integration_test/", "site/", "docs/ops/weekly/", "docs/ops/escalations/",
                   "docs/agents/tasks/", "docs/agents/digests/", "design/mvp_manifest.json", "docs/research/")
PATH_RE = re.compile(r"`((?:docs|design)/[A-Za-z0-9_./\-]+|[A-Z][A-Z_]+\.md)`")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
PLACEHOLDER = re.compile(r"NNN|XXX|YYYY|<|>|\*|\{|T-X")

# ---------- own-contract IDs (R5) ----------
STRICT_FAMS = "DD|MG|I|MDC|CPX|AT|AE|CB|SE"
own_tok = re.compile(r"(?<![A-Za-z0-9_\-])(" + STRICT_FAMS + r")-([A-Z]?\d{1,2})(?![A-Za-z0-9])")
own_def = re.compile(r"^(?:[-*] )?(?:\*\*|\| ?`?)(" + STRICT_FAMS + r")-([A-Z]?\d{1,2})(?![A-Za-z0-9])", re.M)
own_defined = set()
for p in NON_SPEC_MD:
    for m in own_def.finditer(read(p)):
        own_defined.add(f"{m.group(1)}-{m.group(2)}")

# ---------- hidden characters (R6) and Arabic letters (R7) ----------
BIDI_FORBIDDEN = re.compile("[\u202a-\u202e\u2066-\u2069\ufeff]")
BIDI_MARKS = re.compile("[\u200e\u200f\u061c]")
MARKS_ALLOWED = {"docs/design/ui-spec/03-typography-rtl.md"}  # documents the formatting marks on purpose
ARABIC_LETTERS = re.compile("[\u064a\u0643\u0640\u0649]")  # Arabic yeh, kaf, tatweel, alef maksura

# ---------- docs index (L3) ----------
index_path = ROOT / "docs/README.md"
index_text = read(index_path) if index_path.exists() else ""
INDEX_EXEMPT = ("docs/design/ui-spec/", "docs/agents/tasks/", "docs/agents/digests/",
                "docs/ops/escalations/", "docs/ops/weekly/")

# ---------- file map (L4) ----------
map_path = ROOT / "docs/PROJECT_FILE_MAP.md"
map_text = read(map_path) if map_path.exists() else ""
MAP_EXEMPT = INDEX_EXEMPT + ("docs/architecture/ADR/ADR-", "docs/PROJECT_FILE_MAP.md")

for p in ALL_MD:
    text = read(p); r = rel(p)
    in_spec = SPEC in p.parents
    # R6 (spec and non-spec)
    for m in BIDI_FORBIDDEN.finditer(text):
        err("R6", r, f"hidden bidi/BOM character U+{ord(m.group(0)):04X} at line {text.count(chr(10), 0, m.start()) + 1}")
    if r not in MARKS_ALLOWED:
        for m in BIDI_MARKS.finditer(text):
            err("R6", r, f"raw direction mark U+{ord(m.group(0)):04X} at line {text.count(chr(10), 0, m.start()) + 1} (write the code point instead)")
    if in_spec:
        continue
    # L3
    if r.startswith("docs/") and r != "docs/README.md" and not r.startswith(INDEX_EXEMPT):
        if r[len("docs/"):] not in index_text and p.name not in index_text:
            warn("L3", r, "not listed in docs/README.md")
    # L4
    if not r.startswith(MAP_EXEMPT):
        if not re.search(r"(?<![A-Za-z0-9_])" + re.escape(p.stem) + r"(?![A-Za-z0-9_])", map_text):
            warn("L4", r, "not listed in docs/PROJECT_FILE_MAP.md")
    # R7
    for i, line in enumerate(text.splitlines(), 1):
        if ARABIC_LETTERS.search(line) and "Arabic" not in line and "عربی" not in line:
            warn("R7", r, f"Arabic yeh/kaf/tatweel on line {i} (WR-02: use Persian ی and ک)")
    # L1
    for m in LINK_RE.finditer(text):
        tgt = m.group(1).split("#")[0]
        if not tgt or re.match(r"^[a-z]+:", tgt): continue
        if not (p.parent / tgt).resolve().exists() and not (ROOT / tgt).exists():
            err("L1", r, f"broken link -> {tgt}")
    # L2
    for m in PATH_RE.finditer(text):
        tgt = m.group(1).rstrip(".,;:")
        if PLACEHOLDER.search(tgt) or tgt.endswith("/"):
            continue
        if tgt in FUTURE_DOC_PATHS or tgt.startswith(FUTURE_PREFIXES): continue
        if "." not in tgt.split("/")[-1]: continue
        if not (ROOT / tgt).exists() and not (p.parent / tgt).exists():
            # bare file names like AGENTS.md can live at root or be mentioned relative to the same folder
            if "/" not in tgt and ((p.parent / tgt).exists() or any(ROOT.rglob(tgt))): continue
            err("L2", r, f"referenced path not found: {tgt}")
    # R1
    for m in re.finditer(r"ADR-UI-(\d{3})", text):
        if int(m.group(1)) not in adr_ui: err("R1", r, f"unknown ADR-UI-{m.group(1)}")
    for m in re.finditer(r"ADR-(\d{4})", text):
        if int(m.group(1)) not in adr_nums: err("R1", r, f"unknown ADR-{m.group(1)}")
    # R2
    for m in re.finditer(r"\bQ-(C?\d{1,2})\b", text):
        if f"Q-{m.group(1)}" not in q_ids and r != "docs/ops/OPEN_QUESTIONS.md":
            err("R2", r, f"unknown question id Q-{m.group(1)}")
    # R3 (only well-formed 2-digit IDs whose prefix is not one of our own namespaces)
    for m in ID2.finditer(text):
        i = m.group(1); pre = i.split("-")[0]
        if pre in OWN_PREFIXES or i in spec_ids: continue
        if pre in {"ADR"} | set(REQ_PREFIXES): continue
        if re.search(r"UTF-8|SHA-|ISO-|RFC-|TCP-", i): continue
        err("R3", r, f"rule id not found in UI spec: {i}")
    # R4
    for m in re.finditer(r"(?<![A-Za-z]-)\b(" + "|".join(REQ_PREFIXES) + r")-(\d{3})\b", text):
        i = m.group(0)
        if i not in req_ids and r != "docs/REQUIREMENTS.md": err("R4", r, f"requirement id not in REQUIREMENTS.md: {i}")
    for m in re.finditer(r"\bR-(\d{3})\b", text):
        if f"R-{m.group(1)}" not in risk_ids and r != "docs/RISKS_AND_ASSUMPTIONS.md":
            err("R4", r, f"risk id not in RISKS_AND_ASSUMPTIONS.md: R-{m.group(1)}")
    # R5
    for m in own_tok.finditer(text):
        i = f"{m.group(1)}-{m.group(2)}"
        if i not in own_defined: err("R5", r, f"contract id never defined: {i}")

# ---------- L4 reverse: the map must not list documents that do not exist ----------
if map_text:
    existing_names = {q.name for q in ALL_MD}
    for m in re.finditer(r"[A-Za-z0-9_.\-]+\.md\b", map_text):
        name = m.group(0)
        if PLACEHOLDER.search(name) or name in existing_names: continue
        err("L4", "docs/PROJECT_FILE_MAP.md", f"lists a document that does not exist: {name}")

# ---------- R6 for code and config files (no hidden characters at all) ----------
CODE_SUFFIXES = {".py", ".yml", ".yaml", ".json", ".dart", ".sh", ".toml", ".txt"}
CODE_NAMES = {".gitignore", ".gitattributes", ".editorconfig"}
for p in sorted(ROOT.rglob("*")):
    if not p.is_file() or ".git" in p.parts or "__pycache__" in p.parts: continue
    if p.suffix.lower() in CODE_SUFFIXES or p.name in CODE_NAMES:
        ctext = p.read_text(encoding="utf-8", errors="replace")
        for m in list(BIDI_FORBIDDEN.finditer(ctext)) + list(BIDI_MARKS.finditer(ctext)):
            err("R6", rel(p), f"hidden character U+{ord(m.group(0)):04X} at line {ctext.count(chr(10), 0, m.start()) + 1} in a code or config file")

# ---------- D1 definitions ----------
seen = {}
for p in NON_SPEC_MD:
    r = rel(p)
    for i in def_re.findall(read(p)):
        pre = i.split("-")[0]
        if pre not in OWN_PREFIXES: continue
        if i in spec_defs: err("D1", r, f"{i} also defined in UI spec")
        if i in seen and seen[i] != r: err("D1", r, f"{i} also defined in {seen[i]}")
        seen.setdefault(i, r)

# ---------- T1 token checksum ----------
tok = ROOT / "design/tokens/design_tokens.json"
tokens = None
if tok.exists():
    t = tok.read_bytes().decode("utf-8")
    m = re.search(r'("checksum"\s*:\s*)"([0-9a-f]{64})"', t)
    if not m: err("T1", rel(tok), "checksum field missing")
    else:
        h = hashlib.sha256(re.sub(r'("checksum"\s*:\s*)"[0-9a-f]{64}"', r'\1""', t, count=1).encode("utf-8")).hexdigest()
        if h != m.group(2): err("T1", rel(tok), f"checksum mismatch (computed {h[:12]}...)")
        if b"\r\n" in tok.read_bytes(): err("T1", rel(tok), "CRLF line endings (must be LF)")
    tokens = json.loads(t)
else:
    err("T1", "design/tokens/design_tokens.json", "missing")

# ---------- T2 contrast numbers recomputed (spec A-4, AX-06, VT-03) ----------
def _lin(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def _lum(h):
    h = h.lstrip("#"); r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)

def _cr(a, b):
    la, lb = _lum(a), _lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)

def _vtg_sets(c):
    fills = ["primary", "success", "warning", "danger", "info", "accent-health", "accent-tasks", "accent-car"]
    surfs = ["background", "surface", "surface-raised"]
    return [  # same order as the rows of table A-4-a
        [_cr(c["text-primary"], c[s]) for s in surfs],
        [_cr(c["text-secondary"], c[s]) for s in surfs],
        [_cr(c[f], c[s]) for f in fills for s in surfs],
        [_cr(c["on-fill"], c[f + x]) for f in fills for x in ("", "-hover", "-pressed")],
        [_cr(c[f], c[f + "-subtle"]) for f in fills],
        [_cr(c["text-primary"], c[f + "-subtle"]) for f in fills],
        [_cr(c["inverse-text"], c["inverse-surface"])],
        [_cr(c["border-strong"], c[s]) for s in surfs],
        [_cr(c[f], c["ring-track"]) for f in ("primary", "accent-health", "accent-tasks", "accent-car")],
        [_cr(c[f], c[s]) for f in fills for s in surfs],
        [_cr(c["focus-ring"], c[s]) for s in surfs],
        [_cr(c[k], c["surface"]) for k in ("primary", "text-secondary", "border-strong")],
    ]

appendix = SPEC / "A-appendix-tokens.md"
if tokens and appendix.exists():
    fa = str.maketrans("۰۱۲۳۴۵۶۷۸۹٫", "0123456789.")
    rows = []
    for line in read(appendix).splitlines():
        if line.startswith("| VTG-"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if len(cells) == 6:
                rows.append((cells[0], int(cells[2].translate(fa)), Decimal(cells[3].translate(fa)),
                             Decimal(cells[4].translate(fa)), cells[5]))
    if len(rows) != 12:
        err("T2", rel(appendix), f"expected 12 VTG rows in table A-4-a, found {len(rows)}")
    else:
        light, dark = _vtg_sets(tokens["color"]["light"]), _vtg_sets(tokens["color"]["dark"])
        q = Decimal("0.01")
        for k, (gid, n, mn_l, mn_d, in28) in enumerate(rows):
            if len(light[k]) != n:
                err("T2", rel(appendix), f"{gid} row {k + 1}: table says {n} pairs, tokens give {len(light[k])}")
            for theme, vals, claimed in (("light", light[k], mn_l), ("dark", dark[k], mn_d)):
                got = Decimal(repr(min(vals))).quantize(q, rounding=ROUND_HALF_UP)
                if got != claimed:
                    err("T2", rel(appendix), f"{gid} row {k + 1} {theme}: table {claimed}, recomputed {got}")
        rowed = sum(r[1] for r in rows if r[4] == "بله")
        total = rowed + rows[5][1] + rows[6][1]
        if rowed != 96 or total != 105 or total * 2 != 210:
            err("T2", rel(appendix), f"AX-06 totals broken: rows-in-2-8={rowed} (96), per theme={total} (105), both themes={total * 2} (210)")
else:
    if tokens is not None:
        warn("T2", rel(appendix), "appendix missing; contrast numbers not recomputed")

# ---------- S1 spec internal ----------
if "--spec-report" in sys.argv:
    unresolved = sorted(i for i in spec_ids if i not in spec_defs)
    print(f"S1 spec ids referenced but not defined as a row/bullet ({len(unresolved)}):")
    print(" ".join(unresolved))

for w in warns: print(w)
for e in errors: print(e)
print(f"docs_check: {len(errors)} error(s), {len(warns)} warning(s); {len(NON_SPEC_MD)} non-spec md files, {len(spec_ids)} spec ids")
sys.exit(1 if errors or (warns and "--strict" in sys.argv) else 0)
