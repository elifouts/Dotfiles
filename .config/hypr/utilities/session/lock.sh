#!/bin/bash
set -uo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"
SHOTS="${XDG_RUNTIME_DIR:-/tmp}/quickshell-lock"

shoot() {
    rm -rf "$SHOTS" && mkdir -p "$SHOTS"
    (
        for o in $(hyprctl -j monitors | jq -r '.[].name'); do grim -t ppm -o "$o" "$SHOTS/$o.ppm" & done
        wait
        : >"$SHOTS/.done"
    ) 9>&- &
}

if [ "${1:-}" = --preview ]; then
    shoot
    LOCK_PREVIEW=1 qs -p "$QS/lock.qml" </dev/null >/dev/null 2>&1
    exit 0
fi

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/quickshell-lock.lock"
flock -w 1 9 || exit 0
shoot
qs -p "$QS/lock.qml" </dev/null >/dev/null 2>&1
rm -rf "$SHOTS"
