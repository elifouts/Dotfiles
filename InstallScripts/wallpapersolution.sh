#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

section "Wallpaper + Pywal Installer"
ensure_prereqs

install_packages swww python-pywal16 fd wofi
copy_config_dir "wal" "wal"
copy_config_file "hypr/utilities/wallpaper.sh" "hypr/utilities/wallpaper.sh"

# Required by wallpaper.sh launcher styles and menu config.
copy_config_file "wofi/config" "wofi/config"
copy_config_file "wofi/style-wallpaper.css" "wofi/style-wallpaper.css"

read -rp "Install optional pywalfox integration package? (Y/n): " pywalfox_choice
if [[ "${pywalfox_choice:-y}" =~ ^[Yy]$ ]]; then
	install_packages python-pywalfox
fi

wallpaper_script="$CONFIG_DIR/hypr/utilities/wallpaper.sh"
if [ -x "$wallpaper_script" ]; then
	info "Launching wallpaper selector to initialize wallpaper and Pywal."
	"$wallpaper_script"
else
	warn "Wallpaper script not found at $wallpaper_script; applying the default Pywal theme instead."
	apply_default_pywal
fi
success "Wallpaper solution installed."
