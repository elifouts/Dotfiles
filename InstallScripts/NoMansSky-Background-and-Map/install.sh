#!/usr/bin/env bash

set -eo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common.sh"
NAME="nms-sky"
DEST="$HOME/.config/quickshell/$NAME"
SRC="$REPO/.config/hypr/quickshell"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
QS_GUIDE="https://quickshell.org/docs/guide/install-setup/"

check_os() {
    case "$(uname -s)" in
        Linux) ;;
        Darwin) error "macOS has no Wayland, and Quickshell only runs on Wayland. Nothing to do here."; exit 1 ;;
        MINGW* | MSYS* | CYGWIN*) error "Windows can't run Quickshell. Use Linux (a VM works) with a Wayland compositor."; exit 1 ;;
        *) warn "$(uname -s) isn't tested. Quickshell needs Wayland, so this might work if your system has it." ;;
    esac
    grep -qi microsoft /proc/version 2>/dev/null && warn "WSL doesn't do layer-shell, so the wallpaper won't show up there."
    [[ -n "${WAYLAND_DISPLAY:-}" ]] || warn "You're not in a Wayland session right now. It'll work once you log into one."
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] ||
        warn "Not on Hyprland. The planet wallpaper works on any wlroots compositor (sway, river, niri...), the star map needs Hyprland workspaces."
}

as_root() { if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi; }

install_quickshell() {
    section "Quickshell"
    command -v qs >/dev/null && { success "Quickshell is already installed."; return 0; }

    local helper
    helper="$(command -v yay || command -v paru || true)"
    if command -v pacman >/dev/null; then
        if [[ -n "$helper" ]]; then "$helper" -S --needed quickshell
        else as_root pacman -S --needed quickshell; fi
    elif command -v dnf >/dev/null; then
        as_root dnf copr enable -y errornointernet/quickshell && as_root dnf install -y quickshell
    elif command -v nix >/dev/null; then
        nix profile install nixpkgs#quickshell
    elif command -v emerge >/dev/null; then
        warn "On Gentoo it's in the GURU overlay: eselect repository enable guru && emerge gui-apps/quickshell"
    elif command -v apt-get >/dev/null && apt-cache show quickshell >/dev/null 2>&1; then
        as_root apt-get install -y quickshell
    elif command -v zypper >/dev/null && zypper -q info quickshell 2>/dev/null | grep -q '^Name'; then
        as_root zypper install -y quickshell
    elif command -v xbps-install >/dev/null; then
        as_root xbps-install -S quickshell
    elif command -v apk >/dev/null; then
        as_root apk add quickshell
    fi

    command -v qs >/dev/null && { success "Quickshell installed."; return 0; }
    error "Couldn't install Quickshell for you. Your distro might not package it yet, build it from here:"
    echo "    $QS_GUIDE"
    echo "Then run this again."
    exit 1
}

install_font() {
    fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd" && return 0
    ask "Install the JetBrainsMono Nerd Font (the star map labels use it)?" || return 0

    if command -v pacman >/dev/null; then
        as_root pacman -S --needed ttf-jetbrains-mono-nerd && return 0
    fi
    command -v curl >/dev/null && command -v tar >/dev/null || { warn "Need curl and tar to grab the font, skipping."; return 0; }
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerd"
    mkdir -p "$dir"
    curl -fsSL "$FONT_URL" | tar -xJ -C "$dir" && success "Font installed to ${dir/#$HOME/\~}." || warn "Font download failed, the labels fall back to another font."
    command -v fc-cache >/dev/null && fc-cache -f "$dir" >/dev/null
    return 0
}

write_shell() {
    local widgets="QtObject { id: dm; property var items: []; property real shown: 1; property int picked: -1 }" editor=""
    if ask "Show the desktop widgets (clock, stats, music) on the wallpaper?" n; then
        widgets="WidgetModelShared { id: dm; screen: per.modelData; style: \"space\" }"
        editor="LazyLoader { active: WidgetStateShared.editing === per.modelData.name; WidgetsEditShared { model: dm } }"
        mkdir -p "$HOME/.config/hypr/state/layouts/space"
    fi

    cat >"$DEST/shell.qml" <<EOF
import QtQuick
import Quickshell
import Quickshell.Io
import "shared"
import "style/common"
import "style/wallpaper"
import "style/overview"

ShellRoot {
    id: shell

    property var mine: null
    function own() { mine = World.palette(World.hue); Theme.saved = mine }
    Component.onCompleted: own()
    Connections { target: World; function onHueChanged() { shell.own() } }
    Connections { target: Theme; function onSavedChanged() { if (Theme.saved !== shell.mine) shell.own() } }

    Variants {
        model: Quickshell.screens
        Scope {
            id: per
            required property var modelData
            $widgets
            Wallpaper { screen: per.modelData; widgets: dm }
            $editor
        }
    }

    LazyLoader { id: map; Overview { onDone: map.active = false } }

    function run(what) {
        if (what === "world") return World.hop()
        if (what === "widgets") return WidgetStateShared.toggle()
        if (map.active) return map.item?.close()
        Ui.target = HyprShared.focusedScreen()
        map.active = true
    }

    IpcHandler {
        target: "space"
        function toggle(what: string): void { shell.run(what) }
    }
}
EOF
}

install_config() {
    section "Installing the sky"
    [[ -d "$SRC/Space/wallpaper" ]] || { error "Run this from inside the Dotfiles repo, can't find $SRC/Space."; exit 1; }

    if [[ -e "$DEST" && ! -e "$DEST/style/wallpaper" ]]; then
        local backup="$DEST.backup_$(date +%Y%m%d_%H%M%S)"
        mv "$DEST" "$backup"
        warn "Moved the old $DEST to $backup"
    fi
    rm -rf "$DEST"
    mkdir -p "$DEST" "$HOME/.config/space" "$HOME/.config/wal/colorschemes/dark"
    cp -a "$SRC/shared" "$DEST/"
    cp -a "$SRC/Space" "$DEST/style"
    write_shell
    success "Installed to ${DEST/#$HOME/\~}"
}

start_sky() {
    [[ -n "${WAYLAND_DISPLAY:-}" ]] || return 0
    qs list -c "$NAME" 2>/dev/null | grep -q '^Instance' && qs kill -c "$NAME" >/dev/null 2>&1
    pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null &&
        warn "Another quickshell is running. If it draws its own wallpaper, one of them will cover the other."
    for other in swww-daemon hyprpaper swaybg; do
        pgrep -x "$other" >/dev/null && warn "$other is running too, stop it or it'll fight the planet for the background."
    done
    ask "Start it now?" || return 0
    qs -c "$NAME" --daemonize >/dev/null 2>&1 </dev/null && success "Started. Look at your desktop."
    return 0
}

instructions() {
    local ipc="qs -c $NAME ipc call space toggle"
    section "How to use it"
    cat <<EOF
${BOLD}Start it${RESET}
    qs -c $NAME

${BOLD}Commands${RESET} (bind these to whatever keys you want)
    $ipc overview     open/close the star map
    $ipc world        fly to a new planet, new colors
    $ipc widgets      move the desktop widgets around (if you turned them on)

${BOLD}In the star map${RESET}
    WASD or arrows to fly, Q/E to roll, Shift to go fast
    Tab cycles your workspaces, Enter warps to one, Space goes back home, Esc leaves

${BOLD}Hyprland${RESET} ~/.config/hypr/hyprland.conf
    exec-once = qs -c $NAME
    bind = SUPER, TAB, exec, $ipc overview
    bind = ALT, W, exec, $ipc world
    bind = ALT, D, exec, $ipc widgets

${BOLD}Hyprland${RESET} ~/.config/hypr/hyprland.lua (if your config is Lua)
    hl.on("hyprland.start", function() hl.exec_cmd("qs -c $NAME") end)
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("$ipc overview"))
    hl.bind("ALT + W", hl.dsp.exec_cmd("$ipc world"))
    hl.bind("ALT + D", hl.dsp.exec_cmd("$ipc widgets"))
    hl.layer_rule({ name = "space-wall-noanim", match = { namespace = "space-wall" }, no_anim = true })
    hl.layer_rule({ name = "space-overview-noanim", match = { namespace = "space-overview" }, no_anim = true })

${BOLD}Sway / River / others${RESET}
    exec qs -c $NAME
    bindsym Mod4+w exec $ipc world

Looks better with no open animation on the layers "space-wall" and "space-overview" (a no_anim layer rule).

Restart:   qs kill -c $NAME; qs -c $NAME --daemonize
Uninstall: qs kill -c $NAME; rm -rf ${DEST/#$HOME/\~} ~/.config/space
EOF
    [[ ! -e "$HOME/.config/hypr/quickshell/Space" ]] ||
        { echo; warn "You have the full dotfiles too. The Space style already has all of this, running both draws two wallpapers."; }
}

main() {
    section "No Man's Sky Background + Star Map"
    check_os
    install_quickshell
    install_font
    install_config
    start_sky
    success "Done."
    instructions
}

main "$@"
