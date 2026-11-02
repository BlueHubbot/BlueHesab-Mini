#!/usr/bin/env python3
"""T-015 (SP-03): read TTF tables and report the UI spec §3-1 rows.

Stdlib only. Reads every *.ttf in the given folder (build/fonts from
fetch_font.py) and reports: coverage (cmap), weights (fvar wght axis or the
static files present), tabular digits (hmtx advances, GSUB `tnum`), vertical
metrics (head, hhea, OS/2), Latin vs Persian digit ink height (glyf yMax) and
file size. Findings are evidence, not assertions: the tool fails only when a
file cannot be parsed.

Usage: python3 -I tool/font_report.py --fonts build/fonts --tokens ../../design/tokens/design_tokens.json
"""
import argparse
import json
import os
import struct
import sys

# UI spec §3-1 row "coverage": پ چ ژ گ، Persian yeh/kaf, ZWNJ, U+06F0..U+06F9
# and the marks ، ؛ ؟ « » ٪ ٫ ٬ − (code points, so no Persian literal here).
REQUIRED = {
    "peh": 0x067E, "tcheh": 0x0686, "jeh": 0x0698, "gaf": 0x06AF,
    "farsi-yeh": 0x06CC, "keheh": 0x06A9, "zwnj": 0x200C,
    "arabic-comma": 0x060C, "arabic-semicolon": 0x061B, "arabic-question": 0x061F,
    "guillemet-left": 0x00AB, "guillemet-right": 0x00BB,
    "arabic-percent": 0x066A, "arabic-decimal": 0x066B, "arabic-thousands": 0x066C,
    "minus": 0x2212,
}
for _d in range(10):
    REQUIRED[f"fa-digit-{_d}"] = 0x06F0 + _d
FA_DIGITS = [0x06F0 + d for d in range(10)]
# UI spec §3-1 vertical-metric sample, as code points (nominal forms).
SPECIMEN = [0x06AF, 0x0686, 0x067E, 0x0698, 0x06CC, 0x0626, 0x0624] + \
    [0x06F0 + d for d in range(1, 10)] + [0x06F0]
LATIN_DIGITS = [0x30 + d for d in range(10)]


def notice(title, msg, level="notice"):
    msg = str(msg).replace("%", "%25").replace("\r", "").replace("\n", "%0A")
    if os.environ.get("GITHUB_ACTIONS"):
        print(f"::{level} title={title}::{msg}")
    else:
        print(f"[{level}] {title}: {msg}")


class Font:
    def __init__(self, path):
        self.path = path
        self.data = open(path, "rb").read()
        num = struct.unpack_from(">H", self.data, 4)[0]
        self.tables = {}
        for i in range(num):
            tag, _, off, length = struct.unpack_from(">4sIII", self.data, 12 + 16 * i)
            self.tables[tag.decode("latin-1")] = (off, length)
        self.upem = self.u16("head", 18)
        self.loca_long = self.i16("head", 50) == 1
        self.num_glyphs = self.u16("maxp", 4)
        self.cmap = self._cmap()

    def off(self, tag):
        return self.tables[tag][0]

    def u16(self, tag, o):
        return struct.unpack_from(">H", self.data, self.off(tag) + o)[0]

    def i16(self, tag, o):
        return struct.unpack_from(">h", self.data, self.off(tag) + o)[0]

    def _cmap(self):
        base = self.off("cmap")
        n = struct.unpack_from(">H", self.data, base + 2)[0]
        subs = {}
        for i in range(n):
            pid, eid, so = struct.unpack_from(">HHI", self.data, base + 4 + 8 * i)
            subs[(pid, eid)] = base + so
        for key in ((3, 10), (0, 4), (0, 6), (3, 1), (0, 3)):
            if key in subs:
                o = subs[key]
                fmt = struct.unpack_from(">H", self.data, o)[0]
                if fmt == 12:
                    return self._fmt12(o)
                if fmt == 4:
                    return self._fmt4(o)
        raise ValueError("no Unicode cmap subtable (format 4 or 12)")

    def _fmt4(self, o):
        d = self.data
        segx2 = struct.unpack_from(">H", d, o + 6)[0]
        ends = o + 14
        starts = ends + segx2 + 2
        deltas = starts + segx2
        ranges = deltas + segx2
        m = {}
        for s in range(segx2 // 2):
            end = struct.unpack_from(">H", d, ends + 2 * s)[0]
            start = struct.unpack_from(">H", d, starts + 2 * s)[0]
            delta = struct.unpack_from(">h", d, deltas + 2 * s)[0]
            ro = struct.unpack_from(">H", d, ranges + 2 * s)[0]
            for c in range(start, end + 1):
                if c == 0xFFFF:
                    continue
                if ro == 0:
                    g = (c + delta) & 0xFFFF
                else:
                    addr = ranges + 2 * s + ro + 2 * (c - start)
                    g = struct.unpack_from(">H", d, addr)[0]
                    if g:
                        g = (g + delta) & 0xFFFF
                if g:
                    m[c] = g
        return m

    def _fmt12(self, o):
        n = struct.unpack_from(">I", self.data, o + 12)[0]
        m = {}
        for i in range(n):
            a, b, g = struct.unpack_from(">III", self.data, o + 16 + 12 * i)
            for c in range(a, b + 1):
                m[c] = g + (c - a)
        return m

    def advance(self, gid):
        n = self.u16("hhea", 34)
        base = self.off("hmtx")
        idx = gid if gid < n else n - 1
        return struct.unpack_from(">H", self.data, base + 4 * idx)[0]

    def y_max(self, gid):
        return self._bbox_y(gid, 8)

    def y_min(self, gid):
        return self._bbox_y(gid, 4)

    def _bbox_y(self, gid, field):
        if "glyf" not in self.tables:
            return None
        lb = self.off("loca")
        if self.loca_long:
            a, b = struct.unpack_from(">II", self.data, lb + 4 * gid)
        else:
            a, b = (2 * x for x in struct.unpack_from(">HH", self.data, lb + 2 * gid))
        if a == b:
            return 0
        return struct.unpack_from(">h", self.data, self.off("glyf") + a + field)[0]

    def fvar_axes(self):
        if "fvar" not in self.tables:
            return {}
        base = self.off("fvar")
        axes_off, _, count, size = struct.unpack_from(">HHHH", self.data, base + 4)
        axes = {}
        for i in range(count):
            tag, mn, df, mx = struct.unpack_from(">4siii", self.data, base + axes_off + size * i)
            axes[tag.decode("latin-1")] = (mn / 65536, df / 65536, mx / 65536)
        return axes

    def gsub_features(self):
        if "GSUB" not in self.tables:
            return set()
        base = self.off("GSUB")
        fl = base + struct.unpack_from(">H", self.data, base + 6)[0]
        n = struct.unpack_from(">H", self.data, fl)[0]
        return {self.data[fl + 2 + 6 * i: fl + 6 + 6 * i].decode("latin-1") for i in range(n)}

    def metrics(self):
        m = {"upem": self.upem,
             "hhea": (self.i16("hhea", 4), self.i16("hhea", 6), self.i16("hhea", 8))}
        if "OS/2" in self.tables:
            m["typo"] = (self.i16("OS/2", 68), self.i16("OS/2", 70), self.i16("OS/2", 72))
            m["win"] = (self.u16("OS/2", 74), self.u16("OS/2", 76))
            m["use_typo_metrics"] = bool(self.u16("OS/2", 62) & (1 << 7))
        return m


def report(path, tokens):
    f = Font(path)
    name = os.path.basename(path)
    out = {"file": name, "bytes": len(f.data), "glyphs": f.num_glyphs}
    missing = [k for k, cp in REQUIRED.items() if cp not in f.cmap]
    out["coverage"] = "PASS" if not missing else "FAIL"
    out["coverage_missing"] = missing
    axes = f.fvar_axes()
    out["axes"] = {k: list(v) for k, v in axes.items()}
    if "wght" in axes:
        mn, _, mx = axes["wght"]
        out["weights"] = "PASS" if mn <= 400 and mx >= 700 else "FAIL"
    fa_gids = [f.cmap.get(c) for c in FA_DIGITS]
    la_gids = [f.cmap.get(c) for c in LATIN_DIGITS]
    if all(fa_gids):
        adv = sorted({f.advance(g) for g in fa_gids})
        out["fa_digit_advances"] = adv
        out["fa_digits_tabular_by_design"] = len(adv) == 1
    if all(la_gids):
        out["latin_digit_advances"] = sorted({f.advance(g) for g in la_gids})
    feats = f.gsub_features()
    out["gsub_tnum"] = "tnum" in feats
    out["gsub_features"] = sorted(feats)
    out["tabular"] = ("PASS" if all(fa_gids) and (out.get("fa_digits_tabular_by_design") or out["gsub_tnum"])
                      else "FAIL")
    if all(fa_gids) and all(la_gids) and "glyf" in f.tables:
        fa_h = sorted(f.y_max(g) for g in fa_gids[1:])  # skip zero: a dot by design
        la_h = sorted(f.y_max(g) for g in la_gids)
        fa_med, la_med = fa_h[len(fa_h) // 2], la_h[len(la_h) // 2]
        out["digit_ink_height"] = {"fa_median_1_9": fa_med, "latin_median": la_med,
                                   "ratio_fa_over_latin": round(fa_med / la_med, 3) if la_med else None}
    met = f.metrics()
    out["metrics"] = met
    asc, desc, gap = met["typo"] if met.get("use_typo_metrics") else met["hhea"]
    natural = (asc - desc) / f.upem
    rows = []
    for tok, v in tokens.items():
        need = natural * v["size"]
        rows.append({"token": tok, "size": v["size"], "line": v["line"],
                     "ascent_plus_descent": round(need, 2),
                     "fits": need <= v["line"] + 1e-9})
    out["vertical"] = rows
    # Ink of the sample glyphs (glyf bbox), to tell "line box larger than the
    # token line" from "ink would be cut" (TY-04, RKX-04).
    gids = [f.cmap.get(c) for c in SPECIMEN]
    if all(gids) and "glyf" in f.tables:
        top = max(f.y_max(g) for g in gids)
        bottom = min(f.y_min(g) for g in gids)
        out["specimen_ink_units"] = [top, bottom]
        for r in rows:
            ink = (top - bottom) / f.upem * r["size"]
            r["ink"] = round(ink, 2)
            r["ink_fits"] = ink <= r["line"] + 1e-9
        out["ink_status"] = "PASS" if all(r["ink_fits"] for r in rows) else "FAIL"
    out["vertical_status"] = "PASS" if all(r["fits"] for r in rows) else "FAIL"
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fonts", required=True)
    ap.add_argument("--tokens", required=True)
    ap.add_argument("--json", default=None)
    args = ap.parse_args()
    tokens = json.load(open(args.tokens, encoding="utf-8"))["typography"]["scale"]
    files = sorted(n for n in os.listdir(args.fonts) if n.endswith(".ttf"))
    if not files:
        notice("font report", f"no .ttf in {args.fonts}", "error")
        return 1
    results = [report(os.path.join(args.fonts, n), tokens) for n in files]
    statics = sorted(r["file"] for r in results if r["file"].startswith("static-"))
    summary = ["| file | bytes | coverage | weights | tabular | fa/latin digit height | vertical | ink |",
               "|---|---|---|---|---|---|---|---|"]
    for r in results:
        h = r.get("digit_ink_height", {})
        summary.append(f"| {r['file']} | {r['bytes']} | {r['coverage']} {r['coverage_missing'] or ''} "
                       f"| {r.get('weights', 'static')} {r.get('axes', {}).get('wght', '')} "
                       f"| {r['tabular']} adv={r.get('fa_digit_advances')} tnum={r['gsub_tnum']} "
                       f"| {h.get('ratio_fa_over_latin')} | {r['vertical_status']} | {r.get('ink_status')} |")
        notice(f"§3-1 {r['file']}",
               f"bytes={r['bytes']} coverage={r['coverage']} missing={r['coverage_missing']} "
               f"weights={r.get('weights', 'static')} wght={r.get('axes', {}).get('wght')} "
               f"tabular={r['tabular']} fa_adv={r.get('fa_digit_advances')} "
               f"latin_adv={r.get('latin_digit_advances')} tnum={r['gsub_tnum']} "
               f"digit_height={h} metrics={r['metrics']} vertical={r['vertical_status']} "
               f"ink={r.get('ink_status')} ink_units={r.get('specimen_ink_units')} | "
               + "; ".join(f"{v['token']} asc+desc {v['ascent_plus_descent']} ink {v.get('ink')}"
                           f" / line {v['line']}{'' if v['fits'] else ' OVER'}"
                           f"{'' if v.get('ink_fits', True) else ' INK-OVER'}" for v in r["vertical"]))
    notice("static weights present", statics or "none")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as s:
            s.write("### T-015 font report (UI spec §3-1)\n\n" + "\n".join(summary) + "\n")
    if args.json:
        with open(args.json, "w", encoding="utf-8") as j:
            json.dump(results, j, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
