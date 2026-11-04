#!/usr/bin/env python3
"""T-015 (SP-03): fetch the pinned Vazirmatn release into build/fonts.

Stdlib only. Nothing is committed: the output folder is git-ignored
(UI spec §3-1, ADVISOR_REPLY-001). With an empty pin (tag/asset/sha256) the
tool takes the latest upstream release, prints what it found and writes
build/fonts/PIN_MISSING so the CI pin job fails until the values are
committed in tool/font_pin.json.

Usage: python3 -I tool/fetch_font.py --pin tool/font_pin.json --out build/fonts
"""
import argparse
import hashlib
import io
import json
import os
import re
import sys
import urllib.request
import zipfile


def notice(title, msg, level="notice"):
    msg = str(msg).replace("%", "%25").replace("\r", "").replace("\n", "%0A")
    if os.environ.get("GITHUB_ACTIONS"):
        print(f"::{level} title={title}::{msg}")
    else:
        print(f"[{level}] {title}: {msg}")


def get(url, accept=None):
    req = urllib.request.Request(url, headers={"User-Agent": "bluehesab-spike-T-015"})
    if accept:
        req.add_header("Accept", accept)
    token = os.environ.get("GITHUB_TOKEN")
    if token and url.startswith("https://api.github.com/"):
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


# Wanted files, matched by base name; the first path wins after sorting by
# (path depth, path) so a top-level fonts/ copy beats nested duplicates.
WANTED = {
    "variable.ttf": re.compile(r"^Vazirmatn\[wght\]\.ttf$"),
    "nl_variable.ttf": re.compile(r"^Vazirmatn-?NL\[wght\]\.ttf$|^Vazirmatn\[wght\]-NL\.ttf$"),
    "static-400.ttf": re.compile(r"^Vazirmatn-Regular\.ttf$"),
    "static-500.ttf": re.compile(r"^Vazirmatn-Medium\.ttf$"),
    "static-600.ttf": re.compile(r"^Vazirmatn-SemiBold\.ttf$"),
    "static-700.ttf": re.compile(r"^Vazirmatn-Bold\.ttf$"),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pin", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    pin = json.load(open(args.pin, encoding="utf-8"))
    repo = pin["repo"]
    tag, asset, want_sha = pin.get("tag", ""), pin.get("asset", ""), pin.get("sha256", "")
    os.makedirs(args.out, exist_ok=True)
    missing_marker = os.path.join(args.out, "PIN_MISSING")
    if os.path.exists(missing_marker):
        os.remove(missing_marker)

    if not (tag and asset and want_sha):
        rel = json.loads(get(f"https://api.github.com/repos/{repo}/releases/latest",
                             "application/vnd.github+json"))
        tag = rel["tag_name"]
        assets = [(a["name"], a["size"]) for a in rel.get("assets", [])]
        notice("release (discovery)", f"{repo} latest={tag} published={rel.get('published_at')} "
               f"assets={assets}")
        zips = [n for n, _ in assets if n.lower().endswith(".zip")]
        if not zips:
            notice("fetch", "no .zip asset in the latest release", "error")
            return 1
        asset = zips[0]

    url = f"https://github.com/{repo}/releases/download/{tag}/{asset}"
    data = get(url)
    sha = hashlib.sha256(data).hexdigest()
    if want_sha:
        if sha != want_sha:
            notice("fetch", f"SHA-256 mismatch for {url}: got {sha}, pinned {want_sha}", "error")
            return 1
        notice("fetch", f"{url} {len(data)} bytes sha256={sha} (matches pin)")
    else:
        open(missing_marker, "w", encoding="utf-8").write(
            json.dumps({"tag": tag, "asset": asset, "sha256": sha}) + "\n")
        notice("fetch", f"{url} {len(data)} bytes sha256={sha} (NOT PINNED: commit tag/asset/sha256)",
               "warning")

    zf = zipfile.ZipFile(io.BytesIO(data))
    ttfs = sorted((n for n in zf.namelist() if n.lower().endswith(".ttf")),
                  key=lambda n: (n.count("/"), n))
    notice("archive TTF files", f"{len(ttfs)}: " + "; ".join(ttfs)[:3500])
    manifest = {"url": url, "tag": tag, "sha256": sha, "files": {}}
    for out_name, pattern in WANTED.items():
        hit = next((n for n in ttfs if pattern.match(n.rsplit("/", 1)[-1])), None)
        if hit is None:
            notice("select", f"{out_name}: no match for {pattern.pattern}", "warning")
            continue
        blob = zf.read(hit)
        open(os.path.join(args.out, out_name), "wb").write(blob)
        manifest["files"][out_name] = {"source": hit, "bytes": len(blob)}
    with open(os.path.join(args.out, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    notice("select", json.dumps(manifest["files"]))
    if "variable.ttf" not in manifest["files"]:
        notice("select", "variable font not found in the archive", "error")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
