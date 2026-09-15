#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo "======================================"
echo " Dotfiles Installer"
echo "======================================"
echo "1. Full install"
echo "2. Waybar"
echo "3. Wofi"
echo "4. Swaync"
echo "5. Hyprlock"
echo "6. Neovim"
echo "7. Wlogout"
echo "8. Wallpaper solution"
echo "9. Starship"
echo "0. GTK themes"
echo "p. Package manager TUI"
echo "q. Quit"
echo ""
read -rp "Choose an option: " choice

case "${choice,,}" in
    1) target="fullinstall.sh" ;;
    2) target="waybarinstall.sh" ;;
    3) target="wofiinstall.sh" ;;
    4) target="swayncinstall.sh" ;;
    5) target="hyprlockinstall.sh" ;;
    6) target="nviminstall.sh" ;;
    7) target="wlogoutinstall.sh" ;;
    8) target="wallpapersolution.sh" ;;
    9) target="starshipinstall.sh" ;;
    0) target="gtkthemesinstall.sh" ;;
    p) target="../.config/hypr/utilities/package-tui.sh" ;;
    q) echo "Goodbye."; exit 0 ;;
    *) echo "Invalid choice: $choice"; exit 1 ;;
esac

script_path="$SCRIPT_DIR/$target"
if [ ! -f "$script_path" ]; then
    echo "Installer not found: $script_path"
    exit 1
fi

chmod +x "$script_path"
clear
exec "$script_path"

