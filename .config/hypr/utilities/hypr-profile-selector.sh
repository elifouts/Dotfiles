#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVE_HYPR_DIR="$HOME/.config/hypr"

declare -A PROFILE_ICONS=(
    ["Modern"]="󰆍"
    ["Modern Laptop"]="󰌢"
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
    marker=""
    [ "$profile" = "$active_profile" ] && marker="  (active)"
    menu_entries+=("$icon  $profile$marker")
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
mkdir -p "$ACTIVE_HYPR_DIR"
find "$ACTIVE_HYPR_DIR" -maxdepth 1 -type f -name '*.lua' -delete
cp -a "$profile_dir/." "$ACTIVE_HYPR_DIR/"

declare -A profile_utility_paths=()
for utility_dir in "$ACTIVE_HYPR_DIR"/*/utilities; do
    [ -d "$utility_dir" ] || continue
    while IFS= read -r -d '' utility_file; do
        relative_path="${utility_file#"$utility_dir"/}"
        profile_utility_paths["$relative_path"]=1
    done < <(find "$utility_dir" -type f -print0)
done

for relative_path in "${!profile_utility_paths[@]}"; do
    rm -rf "$ACTIVE_HYPR_DIR/utilities/$relative_path"
done

if [ -d "$profile_dir/utilities" ]; then
    mkdir -p "$ACTIVE_HYPR_DIR/utilities"
    cp -a "$profile_dir/utilities/." "$ACTIVE_HYPR_DIR/utilities/"
fi

printf '%s\n' "$selected_profile" > "$ACTIVE_HYPR_DIR/.active-profile"

hyprctl reload
notify-send "Hyprland Profile" "Loaded $selected_profile" 2>/dev/null || true
