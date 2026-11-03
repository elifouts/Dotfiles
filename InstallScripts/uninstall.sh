#!/bin/bash
# undoes fullinstall.sh. you pick the packages, everything else just happens
# nothing that isn't a symlink gets deleted, it gets moved to ~/.dotfiles_uninstalled_<time> instead. been burned before

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/fullinstall.sh"
# fullinstall turns on -e, one failed step shouldn't leave you half uninstalled
set +e -uo pipefail
shopt -s nullglob dotglob

LEFT="$HOME/.dotfiles_uninstalled_$(date +%Y%m%d_%H%M%S)"
# stuff your system probably still needs even after the dotfiles are gone
KEEP=" networkmanager pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber kitty xdg-desktop-portal-hyprland rsync unzip zip "
MODE=defaults
PICKED=()

ours() { [[ -L "$1" && "$(readlink -f "$1")" == "$REPO"/* ]]; }
stash() {
    [[ -e "$1" || -L "$1" ]] || return 0
    local to="$LEFT/${1#"$HOME"/}"
    mkdir -p "$(dirname "$to")" && mv "$1" "$to" && info "Moved $1 → $to"
}
picked() { [[ " ${PICKED[*]} " == *" $1 "* ]]; }

# oldest first, a reinstall backs up the dotfiles' own links so the first backup is the real one
backup_of() {
    local rel="$1" c alts=()
    case "$rel" in
        .config/*) alts=("$HOME"/.config_backup_*/"${rel#.config/}") ;;
        .bashrc) alts=("$HOME"/.bashrc_backup_*/.bashrc) ;;
        wallpapers) alts=("$HOME"/wallpapers_backup_*) ;;
    esac
    for c in "$HOME"/.dotfiles_replaced_*/"$rel" "${alts[@]}"; do
        [[ -e "$c" || -L "$c" ]] && ! ours "$c" && { echo "$c"; return 0; }
    done
    return 1
}

choose_mode() {
    section "What do you want back?"
    local backups=("$HOME"/.dotfiles_replaced_* "$HOME"/.config_backup_* "$HOME"/.bashrc_backup_* "$HOME"/wallpapers_backup_*)
    if (( ${#backups[@]} )); then
        info "Found backups:"
        printf '    %s\n' "${backups[@]}"
    else
        warn "No backups found, restoring would just give you defaults anyway."
    fi
    pick "Choose" "Restore my old configs from the backups (anything without one goes default)" "Defaults for everything" || exit 1
    MODE=$( ((PICK)) && echo defaults || echo restore )
}

choose_packages() {
    section "Packages"
    local -A have=() seen=()
    local args=() group pkg any out
    while read -r pkg; do have[$pkg]=1; done < <(pacman -Qq)

    for group in "Core:${CORE_PACKAGES[*]}" "Optional:${OPTIONAL_PACKAGES[*]}" \
                 "Audio, bluetooth, mirrors:${INSTALLER_PACKAGES[*]}" "Autologin:greetd greetd-tuigreet"; do
        any=()
        for pkg in ${group#*:}; do
            [[ -n "${have[$pkg]:-}" && -z "${seen[$pkg]:-}" ]] || continue
            seen[$pkg]=1
            [[ "$KEEP" == *" $pkg "* ]] && any+=("$pkg!") || any+=("$pkg")
        done
        (( ${#any[@]} )) && args+=("@${group%%:*}" "${any[@]}")
    done
    (( ${#args[@]} )) || { info "None of the dotfiles packages are installed."; return; }

    if command -v python3 >/dev/null; then
        out="$(mktemp)"
        python3 "$SCRIPT_DIR/uninstall-picker.py" "$out" "${args[@]}" || { rm -f "$out"; info "Cancelled, nothing touched."; exit 0; }
        mapfile -t PICKED < "$out"
        rm -f "$out"
    else
        # no python, the slow way
        for pkg in "${args[@]}"; do
            [[ "$pkg" == @* ]] && { echo -e "\n${BOLD}${pkg#@}${RESET}"; continue; }
            ask "Uninstall ${pkg%!}?" n && PICKED+=("${pkg%!}")
        done
    fi
}

undo_autologin() {
    [[ -f /etc/greetd/config.toml ]] && grep -q start-hyprland /etc/greetd/config.toml || return 0
    info "Turning off autologin..."
    # initial_session is the autologin part and it's the last block fullinstall writes
    sudo sed -i '/^\[initial_session\]/,$d' /etc/greetd/config.toml
    sudo systemctl disable greetd.service >/dev/null 2>&1
    sudo systemctl enable getty@tty1.service >/dev/null 2>&1
    success "Back to the normal tty1 login."
}

# only turn off what's actually getting uninstalled, no point killing bluetooth if you're keeping it
undo_services() {
    picked avahi && sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket >/dev/null 2>&1
    picked bluez && sudo systemctl disable --now bluetooth.service >/dev/null 2>&1
    cast_firewall delete
    picked pipewire && systemctl --user disable pipewire.service pipewire-pulse.service >/dev/null 2>&1
    true
}

undo_configs() {
    section "Configs"
    local entry name b

    for entry in "$REPO/.config"/*; do
        name="${entry##*/}"
        ours "$HOME/.config/$name" || continue
        rm "$HOME/.config/$name"
        if [[ $MODE == restore ]] && b="$(backup_of ".config/$name")"; then
            cp -a "$b" "$HOME/.config/$name" && success "Restored ~/.config/$name"
        else
            success "Removed ~/.config/$name"
        fi
    done

    if ours "$HOME/.bashrc"; then
        rm "$HOME/.bashrc"
        if [[ $MODE == restore ]] && b="$(backup_of .bashrc)"; then
            cp -a "$b" "$HOME/.bashrc" && success "Restored ~/.bashrc"
        else
            cp /etc/skel/.bashrc "$HOME/.bashrc" 2>/dev/null && success "~/.bashrc is the stock one now"
        fi
    fi

    ours "$HOME/.local/bin/pypr" && rm "$HOME/.local/bin/pypr"
    [[ $MODE == restore ]] && b="$(backup_of .local/bin/pypr)" && cp -a "$b" "$HOME/.local/bin/pypr"

    # ~/wallpapers didn't exist before, but it might have your own stuff in it now so it gets moved not deleted
    ours "$HOME/wallpapers/library/favorites.txt" && rm "$HOME/wallpapers/library/favorites.txt"
    stash "$HOME/wallpapers"
    if [[ $MODE == restore ]] && b="$(backup_of wallpapers)"; then
        mkdir -p "$HOME/wallpapers" && cp -a "$b/." "$HOME/wallpapers/" && success "Restored ~/wallpapers"
    fi

    # everything the dotfiles generate. the gitignored stuff sits in the repo behind the links
    # (hypr/state, cava/config, kitty theme...)
    # cava makes shaders/themes on its own, only the config is ours
    local made
    while IFS= read -r made; do
        ours "$REPO/$made" && rm "$REPO/$made" || stash "$REPO/$made"
    done < <(git -C "$REPO" ls-files -oi --exclude-standard .config ':!.config/cava/shaders' ':!.config/cava/themes')
    for made in .cache/wal .cache/wallpaper-picker .cache/hypr-home .cache/launcher .cache/colorpicker \
                .cache/capture-thumb.png .cache/dotfiles-welcome .local/state/hypr-settings .local/state/music-player \
                .local/state/overview .local/state/quickshell-lock.json; do
        stash "$HOME/$made"
    done
    success "Cleared out what the dotfiles generated."

    # stuff the apps would just remake
    if [[ $MODE == defaults ]]; then
        stash "$HOME/.local/share/nvim"
        stash "$HOME/.local/state/nvim"
        stash "$HOME/.cache/nvim"
    fi

    git -C "$REPO" config --unset core.hooksPath 2>/dev/null
}

undo_packages() {
    (( ${#PICKED[@]} )) || return 0
    section "Removing packages"
    sudo pacman -Rns --noconfirm "${PICKED[@]}" && { success "Removed ${#PICKED[@]} packages."; return; }

    # one of them is needed by something else and pacman bails on the whole batch, so go one by one
    warn "Batch removal failed, trying them one at a time..."
    local pkg stuck=()
    for pkg in "${PICKED[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || continue
        sudo pacman -Rns --noconfirm "$pkg" >/dev/null 2>&1 || stuck+=("$pkg")
    done
    (( ${#stuck[@]} )) && warn "Kept (something else needs them): ${stuck[*]}" || success "Removed them all."
}

main() {
    echo -e "${RED}${BOLD}"
    cat <<'EOF'
  _   _       _           _        _ _
 | | | |_ __ (_)_ __  ___| |_ __ _| | |
 | | | | '_ \| | '_ \/ __| __/ _` | | |
 | |_| | | | | | | | \__ \ || (_| | | |
  \___/|_| |_|_|_| |_|___/\__\__,_|_|_|
EOF
    echo -e "${RESET}"
    (( EUID )) || { error "Run this as yourself, not root."; exit 1; }
    command -v pacman >/dev/null || { error "pacman not found."; exit 1; }

    choose_mode
    choose_packages

    section "About to"
    echo "  • $( [[ $MODE == restore ]] && echo "unlink the dotfiles and restore your backups" || echo "unlink the dotfiles and leave everything default" )"
    echo "  • clear out everything the dotfiles generated (wallpaper-picker, wal colors, cava config...)"
    echo "  • turn off autologin if it's set up, close the cast firewall ports"
    echo "  • uninstall ${#PICKED[@]} package(s)${PICKED:+: ${PICKED[*]}}"
    echo "  • move anything that isn't a link to $LEFT"
    ask "Go?" n || { info "Cancelled, nothing touched."; exit 0; }

    sudo -v || { error "Need sudo for the system stuff."; exit 1; }
    undo_autologin
    undo_services
    undo_configs
    undo_packages

    section "Done"
    [[ -d "$LEFT" ]] && info "Leftovers are in $LEFT, delete it once you're sure."
    info "The mirrorlist reflector wrote is still there, it works so it stays."
    info "This folder ($REPO) is still here too, rm -rf it whenever."
    warn "Hyprland is still running on the old stuff, log out or reboot."
    ask "Reboot now?" n && { sync; sudo systemctl reboot; }
    exit 0
}

main "$@"
