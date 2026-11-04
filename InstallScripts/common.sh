#!/bin/bash

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

info()    { echo -e "${CYAN}${BOLD}[•]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $*" >&2; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}\n"; }

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

ask() {
    local a def="${2:-y}"
    read -rp "$1 ($([[ $def == y ]] && echo Y/n || echo y/N)): " a
    [[ "${a:-$def}" =~ ^[Yy]$ ]]
}

pick() {
    local prompt="$1" i=1 label choice
    shift
    for label; do echo "$i. $label"; ((i += 1)); done
    read -rp "$prompt [1]: " choice
    choice="${choice:-1}"
    [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= $#)) || { error "Invalid choice."; return 1; }
    PICK=$((choice - 1))
}

install_or_remove() {
    local choice
    read -rp "$1: (1) Install/Update (2) Uninstall [1]: " choice
    case "${choice:-1}" in
        1) "$2" ;;
        2) "$3" ;;
        *) error "Invalid option."; return 1 ;;
    esac
}

install_packages() {
    local helper
    helper="$(command -v yay || command -v paru || true)"
    if [[ -n "$helper" ]]; then
        "$helper" -S --needed "${PACKAGES[@]}" "${AUR_PACKAGES[@]}"
    elif command -v pacman >/dev/null; then
        warn "No AUR helper (yay/paru) found; skipping ${AUR_PACKAGES[*]}."
        sudo pacman -S --needed "${PACKAGES[@]}"
    else
        warn "Not an Arch system; install these yourself: ${PACKAGES[*]} pywal16"
    fi
}

CAST_PORTS=7236:7240
CAST_LANS=(10.0.0.0/8 172.16.0.0/12 192.168.0.0/16)
cast_firewall() {
    local net proto
    if [[ $1 == allow ]]; then
        command -v ufw >/dev/null || firewall-cmd --state >/dev/null 2>&1 || return 0
        grep -q "dports $CAST_PORTS" /etc/ufw/user.rules 2>/dev/null ||
            firewall-cmd --list-ports 2>/dev/null | grep -q "${CAST_PORTS/:/-}/tcp" && return 0
        ask "Open ports ${CAST_PORTS/:/-} to your home network so casting to TVs works?" || return 0
    fi
    if command -v ufw >/dev/null; then
        for net in "${CAST_LANS[@]}"; do
            for proto in tcp udp; do
                if [[ $1 == allow ]]; then
                    sudo ufw allow from "$net" to any port "$CAST_PORTS" proto "$proto" comment dotfiles-cast >/dev/null
                else
                    sudo ufw delete allow from "$net" to any port "$CAST_PORTS" proto "$proto" >/dev/null 2>&1
                fi
            done
        done
    fi
    if command -v firewall-cmd >/dev/null && firewall-cmd --state >/dev/null 2>&1; then
        for proto in tcp udp; do
            sudo firewall-cmd -q --permanent --"$([[ $1 == allow ]] && echo add || echo remove)"-port="${CAST_PORTS/:/-}/$proto"
        done
        sudo firewall-cmd -q --reload
    fi
    return 0
}

ensure_wal() {
    [[ -f "$1" ]] && { success "Using your existing pywal palette."; return 0; }
    if command -v wal >/dev/null; then
        info "Generating a pywal palette from the default wallpaper."
        wal -q -n -s -t -i "$REPO/wallpapers/pywallpaper.jpg" || true
    fi
    [[ -f "$1" ]] && success "Pywal palette generated."
}
