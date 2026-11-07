#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/fullinstall-packages.sh"

DOTFILES_DIR="$HOME/Dotfiles"
HYPRLAND_STYLE_DIR=""
INSTALLING=false

backup_config() {
    local stamp="$(date +%Y%m%d_%H%M%S)" name src dest

    for name in .config .icons wallpapers .bashrc; do
        src="$HOME/$name" dest="$HOME/${name}_backup_$stamp"
        [[ -e "$src" ]] || { warn "$name not found, skipping."; continue; }
        info "Backing up $src → $dest"
        mkdir -p "$dest"
        if [[ -d "$src" ]]; then cp -a "$src/." "$dest/"; else cp -a "$src" "$dest/"; fi
    done
    success "Backups done."
}

select_hyprland_style() {
    section "Hyprland Style"

    local profiles
    mapfile -t profiles < <("$DOTFILES_DIR/.config/hypr/utilities/settings/hypr-profile.sh" list)
    ((${#profiles[@]})) || { error "No Hyprland profiles found."; return 1; }

    pick "Choose a style" "${profiles[@]/\// / }"
    HYPRLAND_STYLE_DIR="${profiles[PICK]}"
    success "Selected ${HYPRLAND_STYLE_DIR/\// / }"
}

link_entry() {
    local target="$1" link="$2" backup="$3"

    [[ -L "$link" && "$(readlink -f "$link")" == "$(readlink -f "$target")" ]] && return
    if [[ -e "$link" || -L "$link" ]]; then
        mkdir -p "$backup"
        mv "$link" "$backup/$(basename "$link")"
        warn "Moved existing $link to $backup/"
    fi
    mkdir -p "$(dirname "$link")"
    ln -s "$target" "$link"
    success "Linked $link -> $target"
}

apply_dotfiles() {
    section "Linking Dotfiles"

    local src="$DOTFILES_DIR/.config" entry
    local backup="$HOME/.dotfiles_replaced_$(date +%Y%m%d_%H%M%S)"

    shopt -s nullglob dotglob
    for entry in "$src"/*; do
        link_entry "$entry" "$HOME/.config/${entry##*/}" "$backup/.config"
    done
    link_entry "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc" "$backup"
    shopt -u nullglob dotglob

    [[ -L "$HOME/wallpapers" ]] && rm "$HOME/wallpapers"
    mkdir -p "$HOME/wallpapers/library"
    link_entry "$DOTFILES_DIR/wallpapers/library/favorites.txt" "$HOME/wallpapers/library/favorites.txt" "$backup/wallpapers"
    cp -rn "$DOTFILES_DIR/wallpapers/library/." "$HOME/wallpapers/library/"

    git -C "$DOTFILES_DIR" config core.hooksPath .githooks
    link_entry "$HOME/.config/hypr/utilities/pypr/pypr.py" "$HOME/.local/bin/pypr" "$backup/.local/bin"

    local old_style
    old_style="$(cut -d/ -f1 "$src/hypr/state/profile" 2>/dev/null || true)"

    [[ -z "$HYPRLAND_STYLE_DIR" ]] ||
        "$src/hypr/utilities/settings/hypr-profile.sh" apply "${HYPRLAND_STYLE_DIR%%/*}" "${HYPRLAND_STYLE_DIR#*/}" --offline

    success "Dotfiles linked."
    apply_colors
    nohup bash -c 'sleep 1; hyprctl reload' >/dev/null 2>&1 &

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        HYPR_STYLE="$old_style" "$src/hypr/utilities/session/session.sh" stop
        "$src/hypr/utilities/session/session.sh" start
    fi
}

apply_colors() {
    $INSTALLING || [[ ! -f "$HOME/.cache/wal/colors.json" ]] || return 0
    section "Applying Colors"

    local daemon
    daemon="$(command -v awww-daemon || true)"
    if [[ -n "${WAYLAND_DISPLAY:-}" && -n $daemon ]] && ! pgrep -x "${daemon##*/}" >/dev/null; then
        setsid -f "$daemon" >/dev/null 2>&1
        sleep 0.5
    fi
    if "$HOME/.config/hypr/utilities/wallpaper/wallpaper-apply.sh" "$DOTFILES_DIR/wallpapers/pywallpaper.jpg" >/dev/null; then
        success "Colors generated from the dotfiles wallpaper."
    else
        warn "Couldn't generate colors; pick a color theme in settings later."
    fi
}

pull_wallpapers() {
    ask "Pull the full wallpaper library?" || return 0
    "$HOME/.config/hypr/utilities/wallpaper/wallpapers.sh" install || warn "Couldn't pull wallpapers, sticking with the defaults."
}

setup_space() {
    section "Space Theme"
    local qsb=/usr/lib/qt6/bin/qsb f
    [[ -x $qsb ]] || { warn "qsb not found (qt6-shadertools), using the precompiled shaders."; return 0; }
    for f in "$DOTFILES_DIR"/.config/hypr/quickshell/*/*/*.frag; do
        [[ -f $f ]] && "$qsb" --qt6 -o "$f.qsb" "$f"
    done
    success "Shaders compiled."
}

setup_mirrors() {
    section "Updating Pacman Mirrorlist"
    yay -S --needed reflector rsync
    sudo reflector --country US --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    success "Mirrorlist updated."
}

autologin_install() {
    local user="$(id -un)"
    yay -S --needed greetd greetd-tuigreet

    sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd start-hyprland"
user = "greeter"

[initial_session]
command = "start-hyprland"
user = "$user"
EOF

    sudo systemctl disable getty@tty1.service
    sudo systemctl enable greetd.service
    success "Autologin configured for $user."
}

autologin_uninstall() {
    sudo systemctl disable greetd.service 2>/dev/null || true
    sudo systemctl enable getty@tty1.service || return 1

    yay -Rns --noconfirm greetd greetd-tuigreet || return 1
    sudo rm -rf /etc/greetd

    sudo systemctl daemon-reload
    sudo systemctl reset-failed greetd.service 2>/dev/null || true
    success "Autologin removed; the default tty1 login will be used on next boot."
}


setup_bluetooth() {
    section "Bluetooth"
    yay -S --needed blueman bluez
    sudo systemctl enable --now bluetooth
    success "Bluetooth enabled."
}

setup_pipewire() {
    section "PipeWire & Audio"
    yay -S --needed pipewire pipewire-pulse pipewire-alsa pipewire-jack \
        pavucontrol pulsemixer gnome-network-displays gst-plugins-bad
    systemctl --user enable --now pipewire.service pipewire-pulse.service
    success "PipeWire configured."
}

run_install() {
    local manual="$1" pkg
    section "$($manual && echo Manual || echo Automatic) Installation"
    INSTALLING=true

    ask "Update mirrorlist?" && setup_mirrors
    if $manual; then
        section "Package Selection"
        for pkg in "${CORE_PACKAGES[@]}"; do
            ask "Install $pkg?" && { yay -S --needed "$pkg" || warn "Failed to install $pkg"; }
        done
        ask "Install Bluetooth support?" && setup_bluetooth
        ask "Configure PipeWire?" && setup_pipewire
    else
        info "Installing core packages..."
        yay -S --needed "${CORE_PACKAGES[@]}"
        sudo systemctl enable --now avahi-daemon
        setup_bluetooth
        setup_pipewire
    fi

    apply_dotfiles
    setup_space
    pull_wallpapers
    cast_firewall allow
    ask "Set up autologin?" && { install_or_remove Autologin autologin_install autologin_uninstall || warn "Autologin setup failed."; }
    ask "Install optional packages?" && { yay -S --needed "${OPTIONAL_PACKAGES[@]}" || warn "Some optional packages failed."; }

    success "Installation complete!"
    touch "$HOME/.cache/dotfiles-welcome"

    if ask "Reboot now?"; then
        info "Rebooting..."
        sync
        sudo systemctl reboot || sudo reboot || { error "Reboot failed; reboot manually."; return 1; }
    fi
}

main() {
    echo -e "${CYAN}${BOLD}"
    cat <<'EOF'
  ____        _    __ _ _
 |  _ \  ___ | |_ / _(_) | ___  ___
 | | | |/ _ \| __| |_| | |/ _ \/ __|
 | |_| | (_) | |_|  _| | |  __/\__ \
 |____/ \___/ \__|_| |_|_|\___||___/
EOF
    echo -e "${RESET}"

    [[ -d "$DOTFILES_DIR" ]] ||
        { error "Dotfiles directory not found: $DOTFILES_DIR"; return 1; }
    command -v yay >/dev/null ||
        { error "Install yay first."; return 1; }

    section "Welcome"
    select_hyprland_style

    local mode
    read -rp "Installation mode: (A)utomatic or (M)anual? [A]: " mode
    mode="${mode:-a}"
    [[ "${mode,,}" == [am] ]] || { error "Unknown option '$mode'."; return 1; }

    ask "Back up current dotfiles?" && backup_config
    run_install "$([[ ${mode,,} == m ]] && echo true || echo false)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
