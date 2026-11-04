#!/bin/bash
set -euo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"
WAYBAR="$HOME/.config/waybar"
dir="$STYLE/waybar"

case "${1:-}" in
    list)
        for d in "$dir"/*/; do
            [ -f "$d/config" ] && basename "$d"
        done
        ;;
    apply)
        name="${2:?name}"
        [ -f "$dir/$name/config" ] && [ -f "$dir/$name/style.css" ] || {
            echo "No waybar style '$name' for ${STYLE##*/}" >&2
            exit 1
        }
        cp "$dir/$name/config" "$WAYBAR/config"
        cp "$dir/$name/style.css" "$WAYBAR/style.css"
        if [ "$("$UTIL/bars/bar.sh" current)" = waybar ]; then
            pkill -x waybar 2>/dev/null || true
            setsid -f waybar >/dev/null 2>&1 </dev/null
        fi
        [ -n "${HYPR_SETTINGS_NO_RECORD:-}" ] || python3 "$UTIL/settings/hypr-settings.py" set "waybar.style=\"$name\"" >/dev/null 2>&1 || true
        ;;
    *)
        echo "usage: waybar-style.sh apply <name> | list" >&2
        exit 2
        ;;
esac
