#!/usr/bin/env python3
"""Add the T-014 share glue to the Android folder that `flutter create` made.

Run from spike/T-014-share after:
  flutter create --no-pub --platforms=android --org dev.bluehesab.spike \
      --project-name spike_share .

It does exactly two things and checks both (SP-07, builder-platform digest):
  1. copies native/MainActivity.kt over the generated MainActivity.kt
     (the package lines must be equal);
  2. adds one <intent-filter> for ACTION_SEND text/plain to MainActivity in
     the main AndroidManifest.xml.
It also fails if the main manifest asks for any permission.
Standard library only.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

FILTER = """            <!-- T-014 (SP-07): share text/plain only. -->
            <intent-filter>
                <action android:name="android.intent.action.SEND"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data android:mimeType="text/plain"/>
            </intent-filter>
"""


def package_of(text: str) -> str:
    match = re.search(r"^package\s+([\w.]+)", text, re.MULTILINE)
    if not match:
        raise SystemExit("no package line")
    return match.group(1)


def main() -> int:
    root = Path.cwd()
    generated = sorted((root / "android/app/src/main").rglob("MainActivity.kt"))
    if len(generated) != 1:
        print(f"::error title=prepare_android::expected one MainActivity.kt, found {generated}")
        return 1
    ours = (root / "native/MainActivity.kt").read_text(encoding="utf-8")
    theirs = generated[0].read_text(encoding="utf-8")
    if package_of(ours) != package_of(theirs):
        print(f"::error title=prepare_android::package {package_of(ours)} != generated {package_of(theirs)}")
        return 1
    generated[0].write_text(ours, encoding="utf-8")

    manifest_path = root / "android/app/src/main/AndroidManifest.xml"
    manifest = manifest_path.read_text(encoding="utf-8")
    if "android.intent.action.SEND" in manifest:
        print("::error title=prepare_android::manifest already has a SEND filter")
        return 1
    if "<uses-permission" in manifest:
        print("::error title=prepare_android::main manifest asks for a permission")
        return 1
    activity = re.search(r'<activity\b[^>]*android:name="\.MainActivity"[\s\S]*?</activity>', manifest)
    if not activity:
        print("::error title=prepare_android::MainActivity element not found")
        return 1
    if 'android:launchMode="singleTop"' not in activity.group(0):
        print("::warning title=prepare_android::MainActivity is not singleTop; warm shares may start a new instance")
    end = activity.end() - len("</activity>")
    line_start = manifest.rfind("\n", 0, end) + 1
    manifest = manifest[:line_start] + FILTER + manifest[line_start:]
    manifest_path.write_text(manifest, encoding="utf-8")
    print(f"prepared {generated[0].relative_to(root)} and {manifest_path.relative_to(root)}")
    print(activity.group(0).split(">")[0] + ">")
    return 0


if __name__ == "__main__":
    sys.exit(main())
