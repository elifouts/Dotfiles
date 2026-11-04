#!/bin/bash
set -uo pipefail

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"
FILE="$HYPR/state/bar"

current() {
    [ "$(cat "$FILE" 2>/dev/null)" = quickshell ] && echo quickshell || echo waybar
}

record() {
    [ -n "${HYPR_SETTINGS_NO_RECORD:-}" ] || python3 "$UTIL/settings/hypr-settings.py" set "$1" >/dev/null 2>&1 || true
}

start() {
    pkill -x waybar 2>/dev/null || true
    [ "$(current)" = waybar ] && setsid -f waybar >/dev/null 2>&1 </dev/null
    "$UTIL/session/shells.sh" bar refresh
}

case "${1:-}" in
    current)
        current
        ;;
    start)
        start
        ;;
    boot)
        python3 "$UTIL/settings/hypr-settings.py" sync >/dev/null 2>&1 || true
        start
        ;;
    apply)
        kind="${2:?waybar|quickshell}"
        case "$kind" in
            waybar | quickshell) ;;
            *) echo "Unknown bar '$kind'" >&2; exit 1 ;;
        esac
        printf '%s\n' "$kind" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"
        start
        record "bar.kind=\"$kind\""
        if [ "$kind" = quickshell ]; then "$UTIL/bars/waybar-style.sh" apply default; fi
        ;;
    style)
        name="${2:?name}"
        [ -f "$STYLE/quickshellbar/$name/config.json" ] || { echo "No quickshell bar style '$name' for ${STYLE##*/}" >&2; exit 1; }
        printf '%s\n' "$name" > "$HYPR/state/bar-style.tmp" && mv -f "$HYPR/state/bar-style.tmp" "$HYPR/state/bar-style"
        record "quickshell.style=\"$name\""
        ;;
    toggle)
        if [ "$(current)" = waybar ]; then
            if pgrep -x waybar >/dev/null; then pkill -x waybar; else setsid -f waybar >/dev/null 2>&1 </dev/null; fi
        else
            "$UTIL/session/shells.sh" bar toggle
        fi
        ;;
    "")
        echo "usage: bar.sh start | boot | apply waybar|quickshell | style <name> | toggle | current | <call> [args...]" >&2
        exit 2
        ;;
    *)
        "$UTIL/session/shells.sh" bar "$@"
        ;;
esac
