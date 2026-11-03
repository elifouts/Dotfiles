#!/bin/bash

CORE_PACKAGES=(
    python-pywal16 awww waybar starship myfetch neovim python-pywalfox
    hypridle hyprpicker hyprshot grim slurp wf-recorder ffmpeg jq wl-clipboard libnotify hyprmon pacman-contrib pyprland fd
    cava brightnessctl otf-codenewroman-nerd nwg-look qogir-icon-theme
    materia-gtk-theme bibata-cursor-theme-bin
    thunar gvfs tumbler eza bottom htop libreoffice-fresh yazi lazygit hyprdvd quickshell unzip zip mpv
    avahi xdg-desktop-portal-hyprland libvips kitty networkmanager wireplumber playerctl imagemagick
    qt6-shadertools ttf-jetbrains-mono-nerd
)

OPTIONAL_PACKAGES=(
    spotify-launcher ncspot
    discord visual-studio-code-bin clock-rs-git asciiquarium
    cbonsai genact cmatrix cowsay
)

INSTALLER_PACKAGES=(
    blueman bluez pipewire pipewire-pulse pipewire-alsa pipewire-jack pavucontrol pulsemixer gnome-network-displays gst-plugins-bad reflector rsync
)

FULLINSTALL_PACKAGES=("${CORE_PACKAGES[@]}" "${OPTIONAL_PACKAGES[@]}" "${INSTALLER_PACKAGES[@]}")
