#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/fullinstall-packages.sh"

if ! command -v pacman >/dev/null 2>&1 || ! command -v yay >/dev/null 2>&1; then
    printf 'This tool needs both pacman and yay. Install yay, then run it again.\n' >&2
    exit 1
fi

declare -a packages=()
declare -a sizes=()
declare -a sources=()
declare -a installed=()
declare -A known=()
declare -A fullinstall=()

for package in "${FULLINSTALL_PACKAGES[@]}"; do
    fullinstall["$package"]=1
done

human_size() {
    local size="$1"
    awk -v value="$size" 'BEGIN {
        split(value, fields, " ")
        number = fields[1] + 0
        unit = fields[2]
        if (unit == "KiB") number /= 1024
        else if (unit == "GiB") number *= 1024
        else if (unit == "TiB") number *= 1024 * 1024
        if (number >= 1024) printf "%.2f GiB", number / 1024
        else if (number >= 1) printf "%.1f MiB", number
        else printf "%.0f KiB", number * 1024
    }'
}

add_package() {
    local package="$1" size="$2" source="$3" is_installed="$4"
    [[ -n "${known[$package]:-}" ]] && return
    known["$package"]=1
    packages+=("$package")
    sizes+=("$size")
    sources+=("$source")
    installed+=("$is_installed")
}

load_packages() {
    local package version size source
    local -A aur=()
    while read -r package; do
        [[ -n "$package" ]] && aur["$package"]=1
    done < <(pacman -Qm 2>/dev/null || true)

    while read -r package version; do
        [[ -n "$package" ]] || continue
        size="$(pacman -Qi "$package" 2>/dev/null | awk -F ': ' '/^Installed Size/ {print $2; exit}')"
        if [[ -n "$size" ]]; then size="$(human_size "$size")"; else size="unknown"; fi
        if [[ -n "${aur[$package]:-}" ]]; then source="AUR"; else source="repo"; fi
        add_package "$package" "$size" "$source" 1
    done < <(pacman -Qe 2>/dev/null || true)

    for package in "${FULLINSTALL_PACKAGES[@]}"; do
        pacman -Q "$package" >/dev/null 2>&1 && continue
        add_package "$package" "not installed" "fullinstall" 0
    done

    if ((${#packages[@]})); then
        local -a order=() old_packages=("${packages[@]}") old_sizes=("${sizes[@]}")
        local -a old_sources=("${sources[@]}") old_installed=("${installed[@]}")
        local i
        mapfile -t order < <(printf '%s\n' "${!known[@]}" | sort)
        packages=(); sizes=(); sources=(); installed=(); known=()
        for package in "${order[@]}"; do
            for ((i = 0; i < ${#old_packages[@]}; i++)); do
                [[ "${old_packages[$i]}" == "$package" ]] || continue
                add_package "$package" "${old_sizes[$i]}" "${old_sources[$i]}" "${old_installed[$i]}"
                break
            done
        done
    fi
}

plain_list() {
    local i status
    printf '%-3s %-42s %-10s %-16s %s\n' ' ' 'PACKAGE' 'SOURCE' 'SIZE' 'STATUS'
    for i in "${!packages[@]}"; do
        if ((installed[i])); then status='installed'; else status='missing'; fi
        printf '%s %-42s %-10s %-16s %s\n' '●' "${packages[i]}" "${sources[i]}" "${sizes[i]}" "$status"
    done
}

load_packages
if [[ "${1:-}" == "--list" ]]; then
    plain_list
    exit 0
fi

if ((${#packages[@]} == 0)); then
    printf 'No explicit or full-install packages found.\n'
    exit 0
fi

cleanup() { printf '\033[0m\033[?25h\033[2J\033[H'; }
trap cleanup EXIT INT TERM

selected=0
draw() {
    local height i start end marker color action
    height="$(tput lines 2>/dev/null || echo 24)"
    ((height -= 8)); ((height < 5)) && height=5
    start=$((selected - height / 2)); ((start < 0)) && start=0
    end=$((start + height - 1)); ((end >= ${#packages[@]})) && end=$((${#packages[@]} - 1))
    ((start > end)) && start=0

    printf '\033[2J\033[H\033[?25l'
    printf '\033[1;36m  PACKAGE MANAGER\033[0m  %s packages\n' "${#packages[@]}"
    printf '  \033[2mGreen = installed   Red = missing   ↑↓/j/k move   Enter uninstall   r reinstall   q quit\033[0m\n\n'
    printf '  %-2s %-40s %-10s %16s\n' ' ' 'PACKAGE' 'SOURCE' 'SIZE'
    for ((i = start; i <= end; i++)); do
        if ((installed[i])); then marker='●'; color='32'; else marker='●'; color='31'; fi
        [[ $i -eq $selected ]] && action='\033[7m' || action=''
        printf '%b  \033[%sm%-2s\033[0m %-40s %-10s %16s\033[0m\n' "$action" "$color" "$marker" "${packages[i]}" "${sources[i]}" "${sizes[i]}"
    done
    printf '\n  \033[2mSelected: %s\033[0m\n' "${packages[selected]}"
}

confirm_action() {
    local key action="$1" package="${packages[selected]}"
    if [[ "$action" == uninstall && "${installed[selected]}" -eq 0 ]]; then
        printf '\n  %s is already missing. Press any key...' "$package"
        IFS= read -rsn1 key
        return
    fi
    if [[ "$action" == reinstall && -z "${fullinstall[$package]:-}" ]]; then
        printf '\n  Reinstall is limited to packages from fullinstall.sh. Press any key...'
        IFS= read -rsn1 key
        return
    fi
    printf '\n  %s %s? [y/N] ' "${action^}" "$package"
    IFS= read -rsn1 key; printf '\n'
    [[ "$key" =~ [Yy] ]] || return
    clear
    if [[ "$action" == uninstall ]]; then yay -Rns "$package"; else yay -S "$package"; fi
    printf '\n  Press any key to return...'
    IFS= read -rsn1 key
    load_packages
    ((selected >= ${#packages[@]})) && selected=$((${#packages[@]} - 1))
}

while :; do
    draw
    IFS= read -rsn1 key
    case "$key" in
        q|Q) exit 0 ;;
        j|B) ((selected < ${#packages[@]} - 1)) && ((selected++)) ;;
        k|A) ((selected > 0)) && ((selected--)) ;;
        d|D) confirm_action uninstall ;;
        r|R) confirm_action reinstall ;;
        '') confirm_action uninstall ;;
        $'\033')
            IFS= read -rsn2 key
            case "$key" in
                '[A') ((selected > 0)) && ((selected--)) ;;
                '[B') ((selected < ${#packages[@]} - 1)) && ((selected++)) ;;
                '[5') IFS= read -rsn1 key; selected=$((selected - 8)); ((selected < 0)) && selected=0 ;;
                '[6') IFS= read -rsn1 key; selected=$((selected + 8)); ((selected >= ${#packages[@]})) && selected=$((${#packages[@]} - 1)) ;;
            esac
            ;;
    esac
done