#!/bin/bash
U="$HOME/.config/hypr/utilities"
daemon="$(command -v awww-daemon)"
if [ -n "$daemon" ] && ! pgrep -x "$(basename "$daemon")" >/dev/null; then
    setsid -f "$daemon" </dev/null >/dev/null 2>&1
    for _ in $(seq 1 40); do awww query >/dev/null 2>&1 && break; sleep 0.05; done
fi
"$U/bars/bar.sh" boot
setsid -f "$U/pypr/pypr.sh" </dev/null >/dev/null 2>&1
