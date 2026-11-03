#!/bin/bash
# rips hyprglass and hyprpm off this machine. kept breaking on multi monitor so it's gone

set -uo pipefail

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"
HYPR="$HOME/.config/hypr"

(( EUID )) || { error "Run this as yourself, not root."; exit 1; }
sudo -v || { error "Need sudo for the hyprpm cache and pacman."; exit 1; }

section "hyprglass"
if command -v hyprctl >/dev/null && hyprctl plugin list 2>/dev/null | grep -qi hyprglass; then
    for so in /var/cache/hyprpm/*/*/hyprglass.so; do
        [[ -e "$so" ]] && hyprctl plugin unload "$so" >/dev/null 2>&1
    done
    success "Unloaded it."
fi

# the live copies still require it, and a missing require kills the whole config
for f in "$HYPR/hyprland.lua" "$HYPR/startup.lua"; do
    [[ -f "$f" && ! -L "$f" ]] || continue
    sed -i '/require("hyprglass")/d; /only loads hyprglass/d; /hypr-settings.py glass")/d' "$f"
done
[[ -f "$HYPR/hyprglass.lua" && ! -L "$HYPR/hyprglass.lua" ]] && rm "$HYPR/hyprglass.lua" && info "Removed $HYPR/hyprglass.lua"

section "hyprpm"
# wiping the cache drops every plugin it built, no point asking hyprpm nicely first
[[ -d /var/cache/hyprpm ]] && sudo rm -rf /var/cache/hyprpm && success "Cleared /var/cache/hyprpm."
if pacman -Qq hyprpm >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm hyprpm && success "hyprpm uninstalled." || warn "pacman couldn't remove hyprpm."
else
    info "hyprpm isn't installed."
fi

command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1
success "Glass is gone."
