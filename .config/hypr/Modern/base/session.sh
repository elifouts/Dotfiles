#!/bin/bash
U="$HOME/.config/hypr/utilities"
"$U/wallpaper/awww.sh" >/dev/null 2>&1
"$U/bars/bar.sh" boot
setsid -f "$U/pypr/pypr.sh" </dev/null >/dev/null 2>&1
