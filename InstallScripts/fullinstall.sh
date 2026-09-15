#!/bin/bash
# =============================================================================
#  Dotfiles Installer — by EF
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/fullinstall-packages.sh"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[•]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $*" >&2; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}\n"; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
  ____        _    __ _ _
 |  _ \  ___ | |_ / _(_) | ___  ___
 | | | |/ _ \| __| |_| | |/ _ \/ __|
 | |_| | (_) | |_|  _| | |  __/\__ \
 |____/ \___/ \__|_| |_|_|\___||___/

EOF
echo -e "${RESET}"

# ── Sanity checks ─────────────────────────────────────────────────────────────
DOTFILES_DIR="$HOME/Dotfiles"

# Add future profiles as: "Display name|Directory name"
HYPRLAND_STYLES=(
    "Modern|Modern"
    "Modern laptop|Modern Laptop"
)
HYPRLAND_STYLE_DIR=""

if [ ! -d "$DOTFILES_DIR" ]; then
    error "Dotfiles directory not found at $DOTFILES_DIR. Aborting."
    exit 1
fi

if ! command -v yay &>/dev/null; then
    error "'yay' AUR helper not found. Please install it first."
    exit 1
fi

# ── Shared helpers ────────────────────────────────────────────────────────────

backup_config() {
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"

    local items=(
        "$HOME/.config:$HOME/.config_backup_${timestamp}"
        "$HOME/.icons:$HOME/.icons_backup_${timestamp}"
        "$HOME/wallpapers:$HOME/wallpapers_backup_${timestamp}"
    )

    local backed_up=false

    for item in "${items[@]}"; do
        local source_path="${item%%:*}"
        local backup_path="${item#*:}"

        if [ -e "$source_path" ]; then
            info "Backing up $(basename "$source_path") → $backup_path"
            mkdir -p "$backup_path"
            cp -a "$source_path/." "$backup_path/"
            success "Backed up $(basename "$source_path")"
            backed_up=true
        else
            warn "$(basename "$source_path") not found — skipping backup."
        fi
    done

    if $backed_up; then
        success "Backups created for .config, .icons, and wallpapers"
    else
        warn "No dotfiles were backed up."
    fi
}

backup_bashrc() {
    local backup_dir="${HOME}/.bashrc_backup_$(date +%Y%m%d_%H%M%S)"

    if [ ! -f "$HOME/.bashrc" ]; then
        warn "~/.bashrc not found — skipping backup."
        return
    fi

    info "Backing up .bashrc → $backup_dir"
    mkdir -p "$backup_dir"
    cp -a "$HOME/.bashrc" "$backup_dir/.bashrc"
    success "Backup created at $backup_dir/.bashrc"
}

select_hyprland_style() {
    section "Hyprland Style"

    local index=1
    local style
    for style in "${HYPRLAND_STYLES[@]}"; do
        echo "${index}. ${style%%|*}"
        ((index++))
    done

    local style_choice
    read -rp "Choose a Hyprland style [1]: " style_choice
    style_choice="${style_choice:-1}"

    if ! [[ "$style_choice" =~ ^[0-9]+$ ]] || (( style_choice < 1 || style_choice > ${#HYPRLAND_STYLES[@]} )); then
        error "Unknown Hyprland style '$style_choice'. Exiting."
        exit 1
    fi

    style="${HYPRLAND_STYLES[$((style_choice - 1))]}"
    HYPRLAND_STYLE_DIR="${style#*|}"

    if [ ! -d "$DOTFILES_DIR/.config/hypr/$HYPRLAND_STYLE_DIR" ]; then
        error "Hyprland style directory not found: $HYPRLAND_STYLE_DIR"
        exit 1
    fi

    success "Selected Hyprland style: ${style%%|*}"
}

apply_dotfiles() {
    section "Applying Dotfiles"
    info "Copying wallpapers..."
    cp -a "$DOTFILES_DIR/wallpapers" "$HOME/"

    info "Copying .icons..."
    cp -a "$DOTFILES_DIR/.icons" "$HOME/"

    info "Copying .config files..."
    mkdir -p "$HOME/.config"
    for config_entry in "$DOTFILES_DIR/.config/"*; do
        [ -e "$config_entry" ] || continue
        [ "$(basename "$config_entry")" = "hypr" ] && continue
        cp -a "$config_entry" "$HOME/.config/"
    done

    local hypr_source="$DOTFILES_DIR/.config/hypr"
    local hypr_dest="$HOME/.config/hypr"
    mkdir -p "$hypr_dest"

    for shared_file in hypridle.conf hyprlock.conf; do
        cp -a "$hypr_source/$shared_file" "$hypr_dest/"
    done

    mkdir -p "$hypr_dest/utilities"
    cp -a "$hypr_source/utilities/." "$hypr_dest/utilities/"

    cp -a "$hypr_source/$HYPRLAND_STYLE_DIR/." "$hypr_dest/"
    printf '%s\n' "$HYPRLAND_STYLE_DIR" > "$hypr_dest/.active-profile"

    info "Copying .bashrc..."
    cp -a "$DOTFILES_DIR/.bashrc" "$HOME/"

    fix_wofi_paths
    success "Dotfiles applied."
}

fix_wofi_paths() {
    local config_dir="$HOME/.config/wofi"

    if [ ! -d "$config_dir" ]; then
        warn "Wofi config directory not found at $config_dir — skipping path fix."
        return
    fi

    info "Fixing wofi CSS paths for user: $USER"
    find "$config_dir" -maxdepth 1 -type f -name "*.css" -print0 \
    | while IFS= read -r -d '' file; do
        sed -i -E \
            "s|/home/[^/]+/\.cache/wal/colors-waybar\.css|$HOME/.cache/wal/colors-waybar.css|g" \
            "$file"
        success "Updated: $file"
    done
}

setup_wallpaper() {
    section "Setting Wallpaper (pywal)"
    local wallpaper="$DOTFILES_DIR/wallpapers/pywallpaper.jpg"
    if [ -f "$wallpaper" ]; then
        wal -i "$wallpaper" -n
        success "Wallpaper set."
    else
        warn "Wallpaper not found at $wallpaper — skipping."
    fi
}

setup_dynamic_cursors() {
    section "Dynamic Cursors"
    if hyprpm add https://github.com/virtcode/hypr-dynamic-cursors && \
       hyprpm enable dynamic-cursors; then
        success "Dynamic cursors enabled."
    else
        warn "Dynamic cursors setup failed — you may need to run this manually."
    fi
}

setup_mirrors() {
    section "Updating Pacman Mirrorlist"
    yay -S --needed reflector rsync
    sudo reflector --country 'US' --latest 10 --sort rate \
        --save /etc/pacman.d/mirrorlist
    success "Mirrorlist updated."
}

setup_bluetooth() {
    section "Bluetooth"
    yay -S --needed blueman bluez
    sudo systemctl enable --now bluetooth
    success "Bluetooth enabled."
}

setup_pipewire() {
    section "Pipewire & Audio"
    yay -S --needed pipewire pipewire-pulse pipewire-alsa pipewire-jack \
        pavucontrol pulsemixer gnome-network-displays gst-plugins-bad
    systemctl --user enable --now pipewire.service
    systemctl --user enable --now pipewire-pulse.service
    success "Pipewire configured."
}

finish() {
    success "Installation complete! 🎉"
    notify-send \
        "Dotfiles Installed" \
        "Open Terminal with MOD+Q\nHello $USER — Thanks for using my Dotfiles!\n-EF" \
        2>/dev/null || true
}

# ── Installation modes ────────────────────────────────────────────────────────

auto_install() {
    section "Automatic Installation"

    setup_mirrors

    info "Installing all packages..."
    yay -S --needed "${CORE_PACKAGES[@]}"
    success "Core packages installed."

    sudo systemctl enable --now avahi-daemon

    setup_bluetooth
    setup_pipewire
    setup_wallpaper
    setup_dynamic_cursors
    apply_dotfiles
    finish
}

manual_install() {
    section "Manual Installation"

    read -rp "Update mirrorlist for best US servers? (Y/n): " m
    [[ "${m:-y}" =~ ^[Yy]$ ]] && setup_mirrors

    section "Package Selection"
    for pkg in "${CORE_PACKAGES[@]}"; do
        read -rp "  Install ${BOLD}${pkg}${RESET}? (Y/n): " choice
        [[ "${choice:-y}" =~ ^[Yy]$ ]] && yay -S --needed "$pkg" && clear
    done

    setup_wallpaper

    read -rp "Install Bluetooth support? (Y/n): " b
    [[ "${b:-y}" =~ ^[Yy]$ ]] && setup_bluetooth

    read -rp "Configure Pipewire & Network Displays? (Y/n): " p
    [[ "${p:-y}" =~ ^[Yy]$ ]] && setup_pipewire

    read -rp "Enable Dynamic Cursors? (Y/n): " c
    [[ "${c:-y}" =~ ^[Yy]$ ]] && setup_dynamic_cursors

    apply_dotfiles
    finish
}

# ── Entry point ───────────────────────────────────────────────────────────────

section "Welcome"

select_hyprland_style

read -rp "Installation mode — (A)utomatic or (M)anual? [A]: " install_choice
install_choice="${install_choice:-a}"

read -rp "Backup your current dotfiles before installing? (Y/n): " backup_choice
[[ "${backup_choice:-y}" =~ ^[Yy]$ ]] && backup_config && backup_bashrc

case "${install_choice,,}" in
    a) auto_install  ;;
    m) manual_install ;;
    *) error "Unknown option '$install_choice'. Exiting."; exit 1 ;;
esac
