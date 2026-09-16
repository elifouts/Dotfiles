#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVE_HYPR_DIR="$HOME/.config/hypr"

declare -A PROFILE_ICONS=(
    ["Modern"]="󰆍"
    ["Modern Laptop"]="󰌢"
    ["Retro"]="󰊠"
)
declare -A PROFILE_BARS=(
    ["Modern"]="Waybar"
    ["Modern Laptop"]="Waybar"
    ["Retro"]="Quickshell"
)
DEFAULT_ICON="󰘔"
WOFi_CONFIG="$HOME/.config/wofi/waybar"
WOFi_STYLE="$HOME/.config/wofi/style-waybar.css"

mapfile -t profiles < <(
    find "$ACTIVE_HYPR_DIR" -mindepth 1 -maxdepth 1 -type d \
        ! -name old -exec test -f '{}/hyprland.lua' \; \
        -printf '%f\n' | sort
)

if [ "${#profiles[@]}" -eq 0 ]; then
    notify-send "Hyprland Profiles" "No profiles with hyprland.lua were found." 2>/dev/null || true
    exit 1
fi

active_profile=""
if [ -f "$ACTIVE_HYPR_DIR/.active-profile" ]; then
    active_profile="$(<"$ACTIVE_HYPR_DIR/.active-profile")"
fi

menu_entries=()
for profile in "${profiles[@]}"; do
    icon="${PROFILE_ICONS[$profile]:-$DEFAULT_ICON}"
    bar="${PROFILE_BARS[$profile]:-Unknown bar}"
    marker=""
    [ "$profile" = "$active_profile" ] && marker="  (active)"
    menu_entries+=("$icon  $profile  [$bar]$marker")
done

choice="$(printf '%s\n' "${menu_entries[@]}" | wofi \
    -c "$WOFi_CONFIG" \
    -s "$WOFi_STYLE" \
    --show dmenu \
    --prompt "  Select Hyprland Profile" \
    -n || true)"

[ -n "$choice" ] || exit 0

selected_profile=""
for profile in "${profiles[@]}"; do
    icon="${PROFILE_ICONS[$profile]:-$DEFAULT_ICON}"
    expected_prefix="$icon  $profile"
    [[ "$choice" == "$expected_prefix"* ]] && selected_profile="$profile" && break
done

[ -n "$selected_profile" ] || exit 1

profile_dir="$ACTIVE_HYPR_DIR/$selected_profile"
find "$ACTIVE_HYPR_DIR" -maxdepth 1 -type f -name '*.lua' -delete

rm -rf "$ACTIVE_HYPR_DIR/utilities"
find "$profile_dir" -mindepth 1 -maxdepth 1 ! -name utilities -exec cp -a {} "$ACTIVE_HYPR_DIR/" \;

if [ -d "$profile_dir/utilities" ]; then
    cp -a "$profile_dir/utilities" "$ACTIVE_HYPR_DIR/"
fi

printf '%s\n' "$selected_profile" > "$ACTIVE_HYPR_DIR/.active-profile"

pkill -x waybar 2>/dev/null || true
pkill -x quickshell 2>/dev/null || true
hyprctl reload
case "$selected_profile" in
    Retro)
        quickshell --path "$ACTIVE_HYPR_DIR/utilities/quickshell/bar.qml" --no-duplicate --daemonize &
        ;;
    Modern|"Modern Laptop")
        waybar >/dev/null 2>&1 &
        ;;
esac
notify-send "Hyprland Profile" "Loaded $selected_profile" 2>/dev/null || true
