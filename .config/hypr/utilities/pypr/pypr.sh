#!/bin/bash
set -uo pipefail
unset ${!CLAUDE@}

LOCK="${XDG_RUNTIME_DIR:-/tmp}/pypr-supervisor-${HYPRLAND_INSTANCE_SIGNATURE:-0}.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

UTIL="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
HYPR_LOCK="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/hyprland.lock"
cd "$HOME" || exit 1

hyprland_alive() {
    local pid
    { read -r pid <"$HYPR_LOCK"; } 2>/dev/null && kill -0 "$pid" 2>/dev/null
}

while hyprland_alive; do
    "$UTIL/pypr.py" </dev/null >/dev/null 2>&1 9>&- &
    daemon=$!
    while hyprland_alive && kill -0 "$daemon" 2>/dev/null; do
        sleep 2 9>&-
    done
    kill "$daemon" 2>/dev/null
    wait "$daemon" 2>/dev/null
    sleep 1 9>&-
done
