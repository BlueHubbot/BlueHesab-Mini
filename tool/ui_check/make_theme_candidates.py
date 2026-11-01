#!/usr/bin/env python3
"""Write design/brand/themes-v3-candidate.json (T-012; ADVISOR_REPLY-002 Action 3).

Status of the output: PROPOSED. Nothing in it binds code until the owner
approves or replaces the 28 owner values (ADVISOR_REPLY-002 Action 4) and
T-012 lands them in design/tokens/design_tokens.json (Action 5).

What it does, per theme of design/brand/themes-v2.json:
1. Seeds the seven owner values (success, warning, danger, info and the three
   module accents) with the v1 token of the same name (light seed for light
   themes, dark seed for dark themes).
2. Moves each seed to its nearest shade (same equal-step search as
   lib/design/tokens/contrast_guard.dart) that passes, inside that theme,
   VTG-02 (text on the text surfaces, 4.5), VTG-03 (on-fill on the fill and
   its hover/pressed, 4.5), VTG-04 (fill and text-primary on its subtle, 4.5),
   VTG-08 (implied by VTG-02) and, for module accents, VTG-07 (on ring-track,
   3).
3. Derives the other roles with the rule of
   lib/design/tokens/theme_derivation.dart (this file mirrors it; the Dart
   tool test test/tool/theme_derivation_test.dart re-derives every value
   from the same inputs and fails on any difference) and records the
   VTG-01...VTG-10 pair counts and minima per theme.

Python standard library only; deterministic output. Run from the repo root:
    python3 tool/ui_check/make_theme_candidates.py
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
V1 = json.loads((ROOT / "design/tokens/design_tokens.json").read_text("utf-8"))
V2 = json.loads((ROOT / "design/brand/themes-v2.json").read_text("utf-8"))
OUT = ROOT / "design/brand/themes-v3-candidate.json"

HOVER = V1["state-opacity"]["hover-layer"]
PRESSED = V1["state-opacity"]["pressed-layer"]
SUBTLE_LIGHT, SUBTLE_DARK, DISABLED, DARK_LUM = 0.08, 0.16, 0.4, 0.18
OWNER = ["accent-health", "accent-tasks", "accent-car", "success", "warning", "danger", "info"]
ACC = ["primary", "accent-health", "accent-tasks", "accent-car"]
SEM = ["success", "warning", "danger", "info"]
NO_BG_TEXT = {"clay"}  # ADR-UI-011 "Consequences"; SE-13 Clay exception


def rgb(h):
    return int(h[1:], 16)


def hx(c):
    return "#%06X" % c


def ch(c):
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)


def pack(t):
    return (t[0] << 16) | (t[1] << 8) | t[2]


def rnd(x):  # Dart's round() for x >= 0
    return int(math.floor(x + 0.5))


def lin(x):
    s = x / 255
    return s / 12.92 if s <= 0.04045 else ((s + 0.055) / 1.055) ** 2.4


def lum(c):
    r, g, b = ch(c)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def cr(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def mix(a, b, t):
    return pack(tuple(rnd(x + (y - x) * t) for x, y in zip(ch(a), ch(b))))


def step_mix(a, target, step):
    return pack(tuple(rnd(c + ((target - c) * step / 255)) for c in ch(a)))


def nearest(fg, ok):
    if ok(fg):
        return fg
    found = {}
    for target in (0, 255):
        for s in range(1, 256):
            if ok(step_mix(fg, target, s)):
                found[target] = s
                break
    if not found:
        return None
    if 255 not in found or (0 in found and found[0] <= found[255]):
        return step_mix(fg, 0, found[0])
    return step_mix(fg, 255, found[255])


def states(base, ink, onfill):
    h, p = mix(base, ink, HOVER), mix(base, ink, PRESSED)
    if max(abs(x - y) for x, y in zip(ch(base), ch(p))) < 3:
        h, p = mix(base, onfill, HOVER), mix(base, onfill, PRESSED)
    return h, p


def is_dark(surface):
    return lum(surface) < DARK_LUM


def text_surfaces(tid):
    return (["surface", "surface-raised"] if tid in NO_BG_TEXT
            else ["background", "surface", "surface-raised"])


def derive(tid, roles, owner):
    r = {k: rgb(v) for k, v in roles.items()}
    o = {"background": r["bg"], "surface": r["surface"], "surface-raised": r["surface2"],
         "border": r["line"], "ring-track": r["line"], "text-primary": r["ink"],
         "text-secondary": r["text2"], "on-fill": r["onaccent"], "primary": r["accent"]}
    dark = is_dark(o["surface"])
    ts = [o[s] for s in text_surfaces(tid)]

    def on_all(c, th):
        return all(cr(c, b) >= th for b in ts)

    o["primary-text"] = nearest(o["primary"], lambda c: on_all(c, 4.5))
    o["text-disabled"] = mix(o["text-secondary"], o["surface"], DISABLED)
    o["inverse-surface"] = o["text-primary"]
    o["inverse-text"] = o["surface"]
    o["scrim"] = 0 if dark else o["text-primary"]
    o["focus-ring"] = next(c for c in (o["primary"], o["text-primary"]) if on_all(c, 3))
    o["border-strong"] = nearest(mix(o["text-secondary"], o["border"], 0.5),
                                 lambda c: on_all(c, 3) and cr(c, o["surface"]) >= 3.3)
    for f in ACC + SEM:
        base = o["primary"] if f == "primary" else owner[f]
        o[f] = base
        o[f + "-hover"], o[f + "-pressed"] = states(base, o["text-primary"], o["on-fill"])
        o[f + "-subtle"] = mix(o["surface"], base, SUBTLE_DARK if dark else SUBTLE_LIGHT)
    return o


def fill_ok(tid, o, module):
    ts = [o[s] for s in text_surfaces(tid)]
    share = SUBTLE_DARK if is_dark(o["surface"]) else SUBTLE_LIGHT

    def ok(c):
        h, p = states(c, o["text-primary"], o["on-fill"])
        sub = mix(o["surface"], c, share)
        return (all(cr(c, b) >= 4.5 for b in ts)
                and all(cr(o["on-fill"], x) >= 4.5 for x in (c, h, p))
                and cr(c, sub) >= 4.5 and cr(o["text-primary"], sub) >= 4.5
                and (not module or cr(c, o["ring-track"]) >= 3))
    return ok


def text_fg(f):
    return "primary-text" if f == "primary" else f


def vtg_pairs(tid):
    ts = text_surfaces(tid)
    g = {
        "VTG-01": [(f, b, 4.5) for f in ["text-primary", "text-secondary"] for b in ts],
        "VTG-02": [(text_fg(f), b, 4.5) for f in ACC + SEM for b in ts],
        "VTG-03": [("on-fill", f + s, 4.5) for f in ACC + SEM for s in ["", "-hover", "-pressed"]],
        "VTG-04": [(text_fg(f), f + "-subtle", 4.5) for f in ACC + SEM]
        + [("text-primary", f + "-subtle", 4.5) for f in ACC + SEM],
        "VTG-05": [("inverse-text", "inverse-surface", 4.5)],
        "VTG-06": [("border-strong", b, 3) for b in ts],
        "VTG-07": [(f, "ring-track", 3) for f in ACC],
        "VTG-08": [(f, b, 3) for f in ACC + SEM for b in ts],
        "VTG-09": [("focus-ring", b, 3) for b in ts],
        "VTG-10": [(f, "surface", 3.3) for f in ["primary", "text-secondary", "border-strong"]],
    }
    if tid in NO_BG_TEXT:
        g["VTG-01"] += [("on_bg_text", "background", 4.5), ("on_bg_text2", "background", 3)]
    return g


def main():
    seeds = {"light": V1["color"]["light"], "dark": V1["color"]["dark"]}
    themes = {}
    for tid, t in V2["themes"].items():
        mode = "dark" if is_dark(rgb(t["roles"]["surface"])) else "light"
        seed = {f: rgb(seeds[mode][f]) for f in OWNER}
        o = derive(tid, t["roles"], seed)
        cand = {f: nearest(seed[f], fill_ok(tid, o, f.startswith("accent"))) for f in OWNER}
        o = derive(tid, t["roles"], cand)
        full = dict(o, on_bg_text=rgb(t["on_bg_text"]), on_bg_text2=rgb(t["on_bg_text2"]))
        groups = {}
        for gid, pairs in vtg_pairs(tid).items():
            ratios = [cr(full[a], full[b]) for a, b, _ in pairs]
            fails = [f"{a}/{b}" for (a, b, th), x in zip(pairs, ratios) if x < th]
            groups[gid] = {"count": len(pairs), "min": round(min(ratios), 2), "failing": fails}
        themes[tid] = {
            "mode": mode,
            "background_carries_text": tid not in NO_BG_TEXT,
            "owner_values": {f: {"seed_v1": hx(seed[f]), "proposed": hx(cand[f])} for f in OWNER},
            "derived": {k: hx(v) for k, v in o.items()},
            "vtg": groups,
        }
    doc = {
        "status": "PROPOSED",
        "version": "3-candidate",
        "source": "T-012; ESC-002; ADVISOR_REPLY-002 Actions 1-3; generated by tool/ui_check/make_theme_candidates.py",
        "note": "Not binding. design/tokens/design_tokens.json v1.1 binds code until the owner approves or replaces owner_values (ADVISOR_REPLY-002 Action 4).",
        "themes": themes,
    }
    OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", "utf-8")
    for tid, t in themes.items():
        n = sum(g["count"] for k, g in t["vtg"].items() if k != "VTG-10")
        bad = sum(len(g["failing"]) for g in t["vtg"].values())
        print(f"{tid}: VTG-01..09 {n} pairs, VTG-10 {t['vtg']['VTG-10']['count']}, failing {bad}")


if __name__ == "__main__":
    main()
