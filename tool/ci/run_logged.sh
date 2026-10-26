#!/usr/bin/env bash
# Runs a command; on failure, repeats the tail of its output as a GitHub
# annotation so the cause is visible on the PR without opening raw logs.
# Usage: bash tool/ci/run_logged.sh "<title>" <command> [args...]
set -uo pipefail
title="$1"; shift
log="$(mktemp)"
"$@" 2>&1 | tee "$log"
code=${PIPESTATUS[0]}
if [ "$code" -ne 0 ] && [ -n "${GITHUB_ACTIONS:-}" ]; then
  # Keep error-looking lines first, then the plain tail; escape for ::error.
  { grep -E "(error|Error|ERROR|FAIL|Exception|failed|What went wrong)" "$log" | head -n 25
    echo "---- tail ----"
    tail -n 25 "$log"; } \
    | cut -c1-300 \
    | sed -e 's/%/%25/g' -e 's/\r/%0D/g' \
    | awk 'BEGIN{ORS="%0A"} {print}' > "$log.msg"
  echo "::error title=$title (exit $code)::$(cat "$log.msg")"
fi
rm -f "$log" "$log.msg"
exit "$code"
