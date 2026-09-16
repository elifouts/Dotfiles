#!/bin/sh
set -eu
wallpaper="${1:-}"
[ -n "$wallpaper" ] || exec quickshell --path "$HOME/.config/hypr/utilities/quickshell/wallpapers.qml" --no-duplicate
awww img "$wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
wal -i "$wallpaper" -n --cols16
hyprctl reload
pkill swayosd-server 2>/dev/null || true
swayosd-server -s "$HOME/.config/swayosd/style.css" &
[ -f "$HOME/.cache/wal/colors-kitty.conf" ] && cp "$HOME/.cache/wal/colors-kitty.conf" "$HOME/.config/kitty/current-theme.conf"
command -v pywalfox >/dev/null 2>&1 && pywalfox update || true
cp -f "$wallpaper" "$HOME/wallpapers/pywallpaper.jpg"
