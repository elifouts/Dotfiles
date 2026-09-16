#!/bin/sh
set -eu
profile="${1:?profile required}"
active_dir="$HOME/.config/hypr"
profile_dir="$active_dir/$profile"
[ -f "$profile_dir/hyprland.lua" ] || exit 1
find "$active_dir" -maxdepth 1 -type f -name '*.lua' -delete

rm -rf "$active_dir/utilities"
find "$profile_dir" -mindepth 1 -maxdepth 1 ! -name utilities -exec cp -a {} "$active_dir/" \;
if [ -d "$profile_dir/utilities" ]; then
    cp -a "$profile_dir/utilities" "$active_dir/"
fi
printf '%s\n' "$profile" > "$active_dir/.active-profile"
pkill -x waybar 2>/dev/null || true
pkill -x quickshell 2>/dev/null || true
hyprctl reload
case "$profile" in
    Retro)
        quickshell --path "$active_dir/utilities/quickshell/bar.qml" --no-duplicate --daemonize &
        ;;
    Modern|"Modern Laptop")
        waybar >/dev/null 2>&1 &
        ;;
esac
notify-send "Hyprland Profile" "Loaded $profile" 2>/dev/null || true
