#!/bin/bash
set -uo pipefail
unset ${!CLAUDE@}

LOCK="${XDG_RUNTIME_DIR:-/tmp}/pypr-supervisor-${HYPRLAND_INSTANCE_SIGNATURE:-0}.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

UTIL="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SOCK="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock"
cd "$HOME" || exit 1

while [ -S "$SOCK" ]; do
    "$UTIL/pypr.py" </dev/null >/dev/null 2>&1 9>&-
    sleep 1
done
