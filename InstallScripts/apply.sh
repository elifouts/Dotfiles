#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/full/fullinstall.sh"

[[ -d "$DOTFILES_DIR" ]] || { error "Dotfiles directory not found: $DOTFILES_DIR"; exit 1; }

select_hyprland_style
apply_dotfiles
cast_firewall allow
