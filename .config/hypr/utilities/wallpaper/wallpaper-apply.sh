#!/bin/bash
set -euo pipefail
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../paths.sh"

selected_wallpaper="${1:?usage: wallpaper-apply.sh <image> [output,output...]}"

! pgrep -x awww-daemon >/dev/null || awww img ${2:+-o "$2"} "$selected_wallpaper" --transition-type "${WALLPAPER_TRANSITION:-none}" --transition-duration .5 || true
[ -n "${COLORS_DONE:-}" ] || "$UTIL/colors/color-apply.sh" "" "$selected_wallpaper"

mkdir -p ~/.cache/wallpaper-picker && printf "%s\n" "$selected_wallpaper" > ~/.cache/wallpaper-picker/current
cp -r "$selected_wallpaper" "$HOME/wallpapers/pywallpaper.jpg"
"$QS/style/home/home-wall.sh" >/dev/null 2>&1 &

[ -n "${HYPR_SETTINGS_NO_RECORD:-}" ] || python3 "$UTIL/settings/hypr-settings.py" set "wallpaper.path=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$selected_wallpaper")" >/dev/null 2>&1 || true
