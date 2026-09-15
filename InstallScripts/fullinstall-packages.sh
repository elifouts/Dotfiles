#!/bin/bash

# Keep the package manifest in one place so installers and maintenance tools
# agree on which packages belong to the dotfiles setup.
CORE_PACKAGES=(
    python-pywal16 swww waybar swaync starship myfetch neovim python-pywalfox
    hypridle hyprpicker hyprshot hyprlock hyprmon pacman-contrib pyprland wlogout fd
    cava brightnessctl clock-rs-git nerd-fonts nwg-look qogir-icon-theme
    materia-gtk-theme illogical-impulse-bibata-modern-classic-bin
    thunar gvfs tumbler eza bottom htop libreoffice-fresh spotify-launcher ncspot
    discord visual-studio-code-bin yazi lazygit hyprdvd swayosd-git
)

OPTIONAL_PACKAGES=(
    blueman bluez pipewire pipewire-pulse pipewire-alsa pipewire-jack
    pavucontrol pulsemixer gnome-network-displays gst-plugins-bad
)

FULLINSTALL_PACKAGES=("${CORE_PACKAGES[@]}" "${OPTIONAL_PACKAGES[@]}")