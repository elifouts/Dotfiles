#!/bin/bash
# installs only the bar to ~/.config/quickshell/dotfiles-bar

set -euo pipefail

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"
NAME="dotfiles-bar"
DEST="$HOME/.config/quickshell/$NAME"
UTIL="$REPO/.config/hypr/Modern/utilities"
STYLE_FILE=""

PACKAGES=(
    quickshell otf-codenewroman-nerd networkmanager bluez bluez-utils blueman
    pipewire pipewire-pulse wireplumber pavucontrol cava jq wl-clipboard
    libnotify pacman-contrib kitty hyprpicker grim slurp wf-recorder
    brightnessctl ffmpeg python avahi xdg-desktop-portal-hyprland playerctl imagemagick
)
AUR_PACKAGES=(python-pywal16 gnome-network-displays)

select_style() {
    section "Quickshell Bar Style"

    local styles=() labels=() f d
    for f in "$REPO"/.config/hypr/*/quickshellbar/*/config.json; do
        [[ -f "$f" ]] || continue
        d="${f%/config.json}"
        styles+=("$f") labels+=("$(basename "${d%/quickshellbar/*}") / ${d##*/}")
    done
    ((${#styles[@]})) || { error "No quickshell bar styles found under $REPO/.config/hypr/."; exit 1; }

    echo "   (previews: $REPO/.config/hypr/<style>/quickshellbar/<name>/preview.svg)"
    pick "Choose a style" "${labels[@]}" || exit 1
    STYLE_FILE="${styles[PICK]}"
    success "Selected $(basename "$(dirname "$STYLE_FILE")")"
}

install_config() {
    section "Installing the Quickshell Bar"

    if [[ -e "$DEST" && ! -e "$DEST/style.json" ]]; then
        local backup="$DEST.backup_$(date +%Y%m%d_%H%M%S)"
        mv "$DEST" "$backup"
        warn "Moved the old $DEST to $backup"
    fi
    rm -rf "$DEST"
    mkdir -p "$DEST/styles"

    cp "$UTIL/shell.qml" "$DEST/shell.qml"
    cp -a "$UTIL/bar" "$UTIL/common" "$UTIL/overview" "$DEST/"
    cp "$REPO/.config/waybar/scripts/colorpicker.sh" "$DEST/colorpicker.sh"
    chmod +x "$DEST/colorpicker.sh" "$DEST/common/spotify.sh" "$DEST/bar/procs.sh" "$DEST/bar/capture.sh" "$DEST/bar/net.sh"

    local f
    for f in "$REPO"/.config/hypr/*/quickshellbar/*/config.json; do
        cp "$f" "$DEST/styles/$(basename "$(dirname "$f")").json"
    done
    cp "$STYLE_FILE" "$DEST/style.json"

    success "Installed to $DEST"
}

ensure_palette() {
    ensure_wal "$HOME/.cache/wal/colors.json" ||
        warn "No pywal palette; the bar uses its built-in colors (run 'wal -i <image>' later for wallpaper colors)."
}

enable_services() {
    command -v systemctl >/dev/null || return 0
    local unit

    # avahi is how the cast button finds tvs
    for unit in NetworkManager bluetooth avahi-daemon; do
        systemctl is-enabled --quiet "$unit" 2>/dev/null && continue
        ask "Enable the $unit service (used by the bar)?" || continue
        sudo systemctl enable --now "$unit" || warn "Could not enable $unit; run 'sudo systemctl enable --now $unit'."
    done
    cast_firewall allow
    systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service >/dev/null 2>&1 ||
        warn "Could not start PipeWire for this user; the audio page needs it."
    return 0
}

start_bar() {
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || return 0
    if qs list -c "$NAME" 2>/dev/null | grep -q '^Instance'; then
        qs kill -c "$NAME" >/dev/null 2>&1 || true
        sleep 0.3
        qs -c "$NAME" --daemonize >/dev/null 2>&1 </dev/null
        success "Restarted the bar."
        return 0
    fi

    ask "Start the bar now?" || return 0
    pgrep -x waybar >/dev/null && warn "waybar is running too; stop it (pkill waybar) if you want only this bar."
    qs -c "$NAME" --daemonize >/dev/null 2>&1 </dev/null && success "Bar started."
    return 0
}

instructions() {
    local ipc="qs -c $NAME ipc call bar" dir="${DEST/#$HOME/\~}"
    section "Startup & Keybinds"
    cat <<EOF
Add these to your Hyprland config to start the bar at login and control it from the keyboard.

${BOLD}~/.config/hypr/hyprland.conf${RESET}
    exec-once = qs -c $NAME
    bind = ALT, A, exec, $ipc toggle          # hide / show the bar
    bind = SUPER, TAB, exec, qs -c $NAME ipc call overview toggle    # workspace overview
    bind = SUPER, ESCAPE, exec, $ipc close    # close any open page

${BOLD}~/.config/hypr/hyprland.lua${RESET} (if you configure Hyprland in Lua)
    hl.on("hyprland.start", function()
        hl.exec_cmd("qs -c $NAME")
    end)
    hl.bind("ALT + a", hl.dsp.exec_cmd("$ipc toggle"))
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("qs -c $NAME ipc call overview toggle"))
    hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("$ipc close"))

Then reload Hyprland (hyprctl reload). For a blurred bar, add a blur layer rule for the namespace "quickshell-bar".

More IPC calls: $ipc menu network|audio|power|workspaces
                $ipc island media|timer|color|capture
Restart:  qs kill -c $NAME; qs -c $NAME --daemonize
Style:    cp $dir/styles/<name>.json $dir/style.json   (applies live)
Colors:   ~/.cache/wal/colors.json (run 'wal -i <image>' to recolor from a wallpaper)
EOF
    [[ ! -e "$HOME/.config/hypr/Modern/utilities/bar" ]] ||
        { echo; warn "The full dotfiles install is present and already has this bar (bar.sh apply quickshell); running both gives two bars."; }
}

main() {
    section "Quickshell Bar Installer"
    [[ -d "$UTIL/bar" ]] || { error "Run this from the Dotfiles repo (InstallScripts/)."; exit 1; }

    select_style
    install_packages
    install_config
    ensure_palette
    enable_services
    start_bar
    success "Quickshell bar installed."
    instructions
}

main "$@"
