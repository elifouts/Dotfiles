#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo "======================================"
echo " Dotfiles Installer"
echo "======================================"
echo "1. Full install"
echo "2. Waybar (standalone)"
echo "3. Quickshell bar (standalone)"
echo "p. Package manager TUI"
echo "u. Uninstall everything"
echo "q. Quit"
echo ""
read -rp "Choose an option: " choice

case "${choice,,}" in
    1) target="fullinstall.sh" ;;
    2) target="waybarinstall.sh" ;;
    3) target="quickshellbarinstall.sh" ;;
    p) target="../.config/hypr/utilities/packages/package-tui.sh" ;;
    u) target="uninstall.sh" ;;
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
