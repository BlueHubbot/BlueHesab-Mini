#!/usr/bin/env bash
# Installs the pinned Flutter SDK (tool/ci/flutter_version.env) into
# $RUNNER_TEMP/flutter (or $1) and adds it to PATH for later CI steps.
# Uses git only and verifies the exact commit, so no third-party action and
# no unpinned download is involved (SP-6).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$here/flutter_version.env"

dest="${1:-${RUNNER_TEMP:-$HOME}/flutter}"
if [ ! -x "$dest/bin/flutter" ]; then
  git init -q "$dest"
  git -C "$dest" remote add origin https://github.com/flutter/flutter.git
  git -C "$dest" fetch -q --depth 1 origin \
    "refs/tags/$FLUTTER_VERSION:refs/tags/$FLUTTER_VERSION"
  git -C "$dest" checkout -q "refs/tags/$FLUTTER_VERSION"
  git -C "$dest" checkout -q -B stable
fi

actual="$(git -C "$dest" rev-parse HEAD)"
if [ "$actual" != "$FLUTTER_COMMIT" ]; then
  echo "::error title=Flutter pin::expected $FLUTTER_COMMIT, got $actual"
  exit 1
fi

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$dest/bin" >> "$GITHUB_PATH"
fi
export PATH="$dest/bin:$PATH"
flutter config --no-analytics --no-cli-animations >/dev/null
dart --disable-analytics >/dev/null 2>&1 || true
flutter --version
