#!/bin/bash

set -euo pipefail

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"
DEST="$HOME/.config/waybar"
STYLE_DIR=""

PACKAGES=(
    waybar otf-codenewroman-nerd hyprpicker wl-clipboard libnotify pacman-contrib
    kitty networkmanager bluez bluez-utils blueman
)
AUR_PACKAGES=(python-pywal16)

select_style() {
    section "Waybar Style"

    local styles=() labels=() d
    for d in "$REPO"/.config/hypr/*/waybar/*/; do
        d="${d%/}"
        [[ -f "$d/style.css" ]] || continue
        styles+=("$d") labels+=("$(basename "${d%/waybar/*}") / ${d##*/}")
    done
    ((${#styles[@]})) || { error "No waybar styles found under $REPO/.config/hypr/."; exit 1; }

    echo "   (previews: $REPO/.config/hypr/<style>/waybar/<name>/preview.png)"
    pick "Choose a style" "${labels[@]}" || exit 1
    STYLE_DIR="${styles[PICK]}"
    success "Selected $(basename "$STYLE_DIR")"
}

install_config() {
    section "Installing Waybar Config"

    if [[ -L "$DEST" ]]; then
        warn "$DEST was a link to $(readlink -f "$DEST"); replacing it with a standalone copy."
        rm "$DEST"
    elif [[ -e "$DEST" && ! -e "$DEST/.standalone" ]]; then
        local backup="$DEST.backup_$(date +%Y%m%d_%H%M%S)"
        mv "$DEST" "$backup"
        warn "Moved the old config to $backup"
    fi

    mkdir -p "$DEST/scripts"
    [[ -f "$STYLE_DIR/config" ]] && cp "$STYLE_DIR/config" "$DEST/config" || cp "${STYLE_DIR%/*}/default/config" "$DEST/config"
    cp "$STYLE_DIR/style.css" "$DEST/style.css"
    cp -a "$REPO/.config/waybar/scripts/." "$DEST/scripts/"
    chmod +x "$DEST"/scripts/*.sh
    basename "$STYLE_DIR" > "$DEST/.standalone"
    [[ -x "$HOME/.config/hypr/utilities/session/shells.sh" ]] || sed -i 's|"custom/notification",\s*||' "$DEST/config"

    success "Installed to $DEST"
}

ensure_palette() {
    local css="$HOME/.cache/wal/colors-waybar.css"
    ensure_wal "$css" && return
    mkdir -p "$(dirname "$css")"
    cat > "$css" <<'EOF'
@define-color foreground #c7c6c2;
@define-color background #101418;
@define-color cursor #c7c6c2;
@define-color color0 #101418;
@define-color color1 #e06c75;
@define-color color2 #98c379;
@define-color color3 #e5c07b;
@define-color color4 #5f87af;
@define-color color5 #c3a6ff;
@define-color color6 #9fe0d0;
@define-color color7 #c7c6c2;
@define-color color8 #5c6370;
@define-color color9 #8fd3ff;
@define-color color10 #98c379;
@define-color color11 #e5c07b;
@define-color color12 #87afd7;
@define-color color13 #c3a6ff;
@define-color color14 #9fe0d0;
@define-color color15 #ffffff;
EOF
    warn "pywal unavailable; wrote a default palette to $css (run 'wal -i <image>' later for wallpaper colors)."
}

enable_bluetooth() {
    command -v systemctl >/dev/null || return 0
    systemctl is-enabled --quiet bluetooth 2>/dev/null && return 0
    ask "Enable the Bluetooth service?" || return 0
    sudo systemctl enable --now bluetooth || warn "Could not enable bluetooth; run 'sudo systemctl enable --now bluetooth'."
}

restart_waybar() {
    [[ -n "${WAYLAND_DISPLAY:-}" ]] || return 0
    if pgrep -x waybar >/dev/null; then
        pkill -x waybar || true
        setsid -f waybar >/dev/null 2>&1 </dev/null
        success "Restarted waybar with the new style."
    elif ask "Start waybar now?"; then
        setsid -f waybar >/dev/null 2>&1 </dev/null && success "Waybar started."
    fi
    return 0
}

instructions() {
    section "Startup & Keybind"
    cat <<EOF
Add these to your Hyprland config to start waybar at login and toggle it with ALT+A.

${BOLD}~/.config/hypr/hyprland.conf${RESET}
    exec-once = waybar
    bind = ALT, A, exec, pkill -x waybar || waybar

${BOLD}~/.config/hypr/hyprland.lua${RESET} (if you configure Hyprland in Lua)
    hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
    end)
    hl.bind("ALT + a", hl.dsp.exec_cmd("pkill -x waybar || waybar"))

Then reload Hyprland (hyprctl reload).

Config:   $DEST/config and $DEST/style.css
Colors:   ~/.cache/wal/colors-waybar.css (run 'wal -i <image>' to recolor from a wallpaper)
Restyle:  re-run this installer and pick another style.
EOF
    [[ ! -e "$HOME/.config/hypr/utilities/bars/bar.sh" ]] ||
        { echo; warn "The full dotfiles install is present: it already starts the bar (bar.sh) and binds ALT+A, so skip the lines above."; }
}

main() {
    section "Waybar Installer"
    [[ -d "$REPO/.config/waybar" ]] || { error "Run this from the Dotfiles repo (InstallScripts/)."; exit 1; }

    select_style
    install_packages
    install_config
    ensure_palette
    enable_bluetooth
    restart_waybar
    success "Waybar installed."
    instructions
}

main "$@"
