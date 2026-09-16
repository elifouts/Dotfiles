#!/bin/bash

set -euo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
STYLECSS="$WAYBAR_DIR/style.css"
CONFIG="$WAYBAR_DIR/config"
ASSETS="$WAYBAR_DIR/assets"
THEMES="$WAYBAR_DIR/themes"

menu() {
    find "$ASSETS" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
        | awk '{print "img:"$0}'
}

main() {
    local choice selected_wallpaper
    choice="$(menu | wofi -c ~/.config/wofi/waybar -s ~/.config/wofi/style-waybar.css \
        --show dmenu --prompt "  Select Waybar (Scroll with Arrows)" -n || true)"
    selected_wallpaper="${choice#img:}"
    [ -n "$choice" ] || exit 0

    case "$selected_wallpaper" in
        "$ASSETS/experimental.png")
            cat "$THEMES/experimental/style-experimental.css" > "$STYLECSS"
            cat "$THEMES/experimental/config-experimental" > "$CONFIG"
            ;;
        "$ASSETS/main.png")
            cat "$THEMES/default/style-default.css" > "$STYLECSS"
            cat "$THEMES/default/config-default" > "$CONFIG"
            ;;
        "$ASSETS/line.png")
            cat "$THEMES/line/style-line.css" > "$STYLECSS"
            cat "$THEMES/line/config-line" > "$CONFIG"
            ;;
        "$ASSETS/zen.png")
            cat "$THEMES/zen/style-zen.css" > "$STYLECSS"
            cat "$THEMES/zen/config-zen" > "$CONFIG"
            ;;
        *)
            exit 0
            ;;
    esac

    pkill waybar && waybar
}

main
