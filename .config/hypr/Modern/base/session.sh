#!/bin/bash
# modern's extras, utilities/session.sh calls this
U="$HOME/.config/hypr/utilities"
# wait for awww's socket so the wallpaper apply after a switch lands
daemon="$(command -v awww-daemon)"
if [ -n "$daemon" ] && ! pgrep -x "$(basename "$daemon")" >/dev/null; then
    setsid -f "$daemon" </dev/null >/dev/null 2>&1
    for _ in $(seq 1 40); do awww query >/dev/null 2>&1 && break; sleep 0.05; done
fi
"$U/bar.sh" boot
setsid -f "$U/pypr.sh" </dev/null >/dev/null 2>&1
