#!/bin/bash
set -uo pipefail

LOCK="${XDG_RUNTIME_DIR:-/tmp}/pypr-supervisor-${HYPRLAND_INSTANCE_SIGNATURE:-0}.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

UTIL="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SOCK="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock"
# scratchpads inherit pypr's cwd, so without this the term opened wherever the style switch got run from
cd "$HOME" || exit 1

while [ -S "$SOCK" ]; do
    # 9>&- so pypr itself never holds the supervisor lock, a slow dying one used to block the next supervisor
    "$UTIL/pypr.py" </dev/null >/dev/null 2>&1 9>&-
    sleep 1
done
