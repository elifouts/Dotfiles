#!/bin/bash
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"
grep -qs awww "$STYLE/base/session.sh" || exit 0
if ! awww query >/dev/null 2>&1; then
    setsid -f awww-daemon --no-cache </dev/null >/dev/null 2>&1
    for _ in $(seq 1 60); do awww query >/dev/null 2>&1 && break; sleep 0.05; done
fi
if [ $# -eq 0 ]; then
    src="$(cat ~/.cache/wallpaper-picker/current 2>/dev/null)"
    [ -f "$src" ] || exit 0
    [ -x "$STYLE/base/wallpaper.sh" ] && src="$("$STYLE/base/wallpaper.sh" "$src" || echo "$src")"
    set -- "$src" --transition-type none
fi
awww img "$@"
