#!/bin/bash
set -euo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/paths.sh"

list() {
    local style variant
    for style in "$HYPR"/*/; do
        style="${style%/}"
        [ -d "$style/utilities" ] || continue
        for variant in "$style"/*/; do
            variant="${variant%/}"
            [ -f "$variant/machine.lua" ] && printf '%s/%s\n' "${style##*/}" "${variant##*/}"
        done
    done
}

apply() {
    local style="${1:?style}" variant="${2:?variant}" offline="${3:-}"

    [ -f "$HYPR/$style/$variant/machine.lua" ] && [ -f "$HYPR/$style/base/hyprland.lua" ] && [ -d "$HYPR/$style/utilities" ] || {
        echo "Profile not found: $style/$variant" >&2
        exit 1
    }

    # old style's shell and daemons go first
    [ "$offline" = "--offline" ] || "$UTIL/session.sh" stop

    mkdir -p "$HYPR/state"
    printf '%s/%s\n' "$style" "$variant" > "$HYPR/state/profile"

    python3 "$UTIL/hypr-settings.py" sync

    [ "$offline" = "--offline" ] && return 0

    # lua reruns from scratch so the old binds are gone
    hyprctl reload >/dev/null 2>&1 || true
    python3 "$UTIL/hypr-settings.py" cursor
    "$UTIL/session.sh" start
    python3 "$UTIL/hypr-settings.py" appearance
    notify-send "Hyprland Profile" "Loaded $style / $variant" 2>/dev/null || true
}

case "${1:-}" in
    apply) shift; apply "$@" ;;
    list) list ;;
    *) echo "usage: hypr-profile.sh apply <style> <variant> [--offline] | list" >&2; exit 2 ;;
esac
