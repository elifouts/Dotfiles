#!/bin/bash
set -euo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"

list() {
    local style variant
    for style in "$QS"/*/; do
        style="$(basename "$style")"
        [ -f "$HYPR/$style/base/style.lua" ] || continue
        for variant in "$HYPR"/machine/*.lua; do
            variant="$(basename "$variant" .lua)"
            printf '%s/%s\n' "$style" "$variant"
        done
    done
}

apply() {
    local style="${1:?style}" variant="${2:?variant}" offline="${3:-}"

    [ -f "$HYPR/machine/$variant.lua" ] && [ -f "$HYPR/$style/base/style.lua" ] && [ -d "$QS/$style" ] || {
        echo "Profile not found: $style/$variant" >&2
        exit 1
    }

    if [ "$offline" != "--offline" ]; then
        "$UTIL/session/transition.sh" begin
        trap '"$UTIL/session/transition.sh" reveal' EXIT
        HYPR_STYLE="${STYLE##*/}" "$UTIL/session/session.sh" stop &
        stopping=$!
    fi

    mkdir -p "$HYPR/state"
    printf '%s/%s\n' "$style" "$variant" > "$HYPR/state/profile"
    ln -sfn "$style" "$QS/style"

    python3 "$UTIL/settings/hypr-settings.py" sync

    [ "$offline" = "--offline" ] && return 0

    wait "$stopping" || true
    hyprctl reload >/dev/null 2>&1 || true
    python3 "$UTIL/settings/hypr-settings.py" cursor &
    python3 "$UTIL/settings/hypr-settings.py" colors &
    coloring=$!
    "$UTIL/session/session.sh" start
    wait "$coloring" || true
    COLORS_DONE=1 HYPR_SETTINGS_WAIT=1 WALLPAPER_TRANSITION=none python3 "$UTIL/settings/hypr-settings.py" appearance
    "$UTIL/session/transition.sh" reveal
    trap - EXIT
    sleep 0.35
    notify-send -e "Hyprland Profile" "Loaded $style / $variant" 2>/dev/null || true
}

case "${1:-}" in
    apply) shift; apply "$@" ;;
    list) list ;;
    *) echo "usage: hypr-profile.sh apply <style> <variant> [--offline] | list" >&2; exit 2 ;;
esac
