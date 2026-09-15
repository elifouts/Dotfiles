#!/bin/bash

exec python3 "$(dirname "${BASH_SOURCE[0]}")/package-tui.py" "$@"

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
declare -A selected_packages=()

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
    packages=()
    sizes=()
    sources=()
    installed=()
    known=()

    while read -r package version; do
        [[ -n "$package" ]] || continue
        size="$(pacman -Qi "$package" 2>/dev/null | awk -F ': ' '/^Installed Size/ {print $2; exit}')"
        if [[ -n "$size" ]]; then size="$(human_size "$size")"; else size="unknown"; fi
        if [[ -n "${fullinstall[$package]:-}" ]]; then source="dotfiles"; else source="external"; fi
        add_package "$package" "$size" "$source" 1
    done < <(pacman -Qe 2>/dev/null || true)

    for package in "${FULLINSTALL_PACKAGES[@]}"; do
        pacman -Q "$package" >/dev/null 2>&1 && continue
        add_package "$package" "N/A" "dotfiles" 0
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
    local i status marker
    printf '%-3s %-42s %-10s %-16s %s\n' ' ' 'PACKAGE' 'SOURCE' 'SIZE' 'STATUS'
    for i in "${!packages[@]}"; do
        if ((installed[i])); then marker='✓'; status='installed'; else marker='✗'; status='missing'; fi
        printf '%s %-42s %-10s %-16s %s\n' "$marker" "${packages[i]}" "${sources[i]}" "${sizes[i]}" "$status"
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

selected_column=0
selected_row=0
declare -a dotfiles_indexes=()
declare -a external_indexes=()
declare -a display_names=()

build_columns() {
    local i
    dotfiles_indexes=()
    external_indexes=()
    for i in "${!packages[@]}"; do
        if [[ "${sources[i]}" == "dotfiles" ]]; then
            dotfiles_indexes+=("$i")
        else
            external_indexes+=("$i")
        fi
    done
}

prepare_layout() {
    local index
    column_widths
    display_names=()
    for index in "${!packages[@]}"; do
        if [[ "${sources[index]}" == "dotfiles" ]]; then
            fit_package_name "${packages[index]}" "$left_package_width"
        else
            fit_package_name "${packages[index]}" "$right_package_width"
        fi
        display_names[index]="$fitted_name"
    done
}

selected_index() {
    if ((selected_column == 0)); then
        [[ -n "${dotfiles_indexes[selected_row]:-}" ]] && printf '%s\n' "${dotfiles_indexes[selected_row]}"
    else
        [[ -n "${external_indexes[selected_row]:-}" ]] && printf '%s\n' "${external_indexes[selected_row]}"
    fi
}

column_length() {
    if ((selected_column == 0)); then
        printf '%s\n' "${#dotfiles_indexes[@]}"
    else
        printf '%s\n' "${#external_indexes[@]}"
    fi
}

normalize_selection() {
    local length
    length="$(column_length)"
    if ((length == 0)); then
        selected_column=$((1 - selected_column))
        length="$(column_length)"
    fi
    if ((length > 0 && selected_row >= length)); then
        selected_row=$((length - 1))
    fi
}

move_column() {
    local target="$1"
    if ((target == 0 && ${#dotfiles_indexes[@]} > 0)) ||
       ((target == 1 && ${#external_indexes[@]} > 0)); then
        selected_column="$target"
        normalize_selection
    fi
}

build_columns
column_widths() {
    local index package terminal_width available desired_total
    left_package_width=7
    right_package_width=7
    left_size_width=4
    right_size_width=4
    for index in "${dotfiles_indexes[@]}"; do
        package="${packages[index]}"
        ((${#package} > left_package_width)) && left_package_width=${#package}
        ((${#sizes[index]} > left_size_width)) && left_size_width=${#sizes[index]}
    done
    for index in "${external_indexes[@]}"; do
        package="${packages[index]}"
        ((${#package} > right_package_width)) && right_package_width=${#package}
        ((${#sizes[index]} > right_size_width)) && right_size_width=${#sizes[index]}
    done

    terminal_width="${COLUMNS:-80}"
    available=$((terminal_width - 24 - left_size_width - right_size_width))
    desired_total=$((left_package_width + right_package_width))
    ((available < 24)) && available=24
    if ((desired_total > available)); then
        left_package_width=$((available * left_package_width / desired_total))
        right_package_width=$((available - left_package_width))
        ((left_package_width < 12)) && left_package_width=12
        ((right_package_width < 12)) && right_package_width=12
    fi
}

fit_package_name() {
    local package="$1" width="$2"
    if ((${#package} > width && width > 3)); then
        fitted_name="${package:0:width-3}..."
    else
        fitted_name="$package"
    fi
}

prepare_layout

draw() {
    local height row start end marker color action left_index right_index selection left_name right_name
    height="${LINES:-24}"
    ((height -= 8)); ((height < 5)) && height=5
    start=$((selected_row - height / 2)); ((start < 0)) && start=0
    end=$((start + height - 1))
    printf '\033[H\033[?25l'
    printf '\033[1;36m  PACKAGE MANAGER\033[0m  %s packages\n' "${#packages[@]}"
    printf '  \033[2mGreen ✓ = installed   Red ✗ = missing   [Space] select   d uninstall\033[0m\n'
    printf '  \033[2m←→/h/l columns   ↑↓/j/k move   r reinstall   q quit\033[0m\n\n'
    printf '  \033[1;35mDOTFILES\033[0m%-39s\033[1;33mEXTERNAL\033[0m\n' ''
    printf '  %-3s %-*s %*s    %-3s %-*s %*s\n' ' ' "$left_package_width" 'PACKAGE' "$left_size_width" 'SIZE' ' ' "$right_package_width" 'PACKAGE' "$right_size_width" 'SIZE'
    for ((row = start; row <= end; row++)); do
        left_index=''; right_index=''
        ((row < ${#dotfiles_indexes[@]})) && left_index="${dotfiles_indexes[row]}"
        ((row < ${#external_indexes[@]})) && right_index="${external_indexes[row]}"

        if [[ -n "$left_index" ]]; then
            if ((installed[left_index])); then marker='✓'; color='32'; else marker='✗'; color='31'; fi
            [[ -n "${selected_packages[${packages[left_index]}]:-}" ]] && selection='[x]' || selection='[ ]'
            ((selected_column == 0 && selected_row == row)) && action='\033[7m' || action=''
            left_name="${display_names[left_index]}"
            printf '%b  %s \033[%sm%-2s\033[0m %-*s %*s\033[0m' "$action" "$selection" "$color" "$marker" "$left_package_width" "$left_name" "$left_size_width" "${sizes[left_index]}"
        else
            printf '    %-3s %-*s %*s' '' "$left_package_width" '' "$left_size_width" ''
        fi

        if [[ -n "$right_index" ]]; then
            if ((installed[right_index])); then marker='✓'; color='32'; else marker='✗'; color='31'; fi
            [[ -n "${selected_packages[${packages[right_index]}]:-}" ]] && selection='[x]' || selection='[ ]'
            ((selected_column == 1 && selected_row == row)) && action='\033[7m' || action=''
            right_name="${display_names[right_index]}"
            printf '    %b  %s \033[%sm%-2s\033[0m %-*s %*s\033[0m' "$action" "$selection" "$color" "$marker" "$right_package_width" "$right_name" "$right_size_width" "${sizes[right_index]}"
        else
            printf '        %-3s %-*s %*s' '' "$right_package_width" '' "$right_size_width" ''
        fi
        printf '\n'
    done
    normalize_selection
    selected="$(selected_index)"
    if [[ -n "$selected" ]]; then
        printf '\n  \033[2mSelected: %s\033[0m\n' "${packages[selected]}"
    fi
}

confirm_action() {
    selected="$(selected_index)"
    local key action="$1" package="${packages[selected]}"
    local -a targets=()
    if [[ "$action" == uninstall && ${#selected_packages[@]} -gt 0 ]]; then
        for package in "${!selected_packages[@]}"; do
            targets+=("$package")
        done
    else
        targets=("${packages[selected]}")
    fi

    if [[ "$action" == uninstall && ${#targets[@]} -eq 0 ]]; then
        return
    fi
    if [[ "$action" == uninstall && ${#targets[@]} -eq 1 && "${installed[selected]}" -eq 0 ]]; then
        printf '\n  %s is already missing. Press any key...' "${packages[selected]}"
        IFS= read -rsn1 key
        return
    fi
    if [[ "$action" == reinstall && -z "${fullinstall[$package]:-}" ]]; then
        printf '\n  Reinstall is limited to packages from fullinstall.sh. Press any key...'
        IFS= read -rsn1 key
        return
    fi
    if ((${#targets[@]} > 1)); then
        printf '\n  Uninstall %s selected packages? [y/N] ' "${#targets[@]}"
    else
        printf '\n  %s %s? [y/N] ' "${action^}" "$package"
    fi
    IFS= read -rsn1 key; printf '\n'
    [[ "$key" =~ [Yy] ]] || return
    clear
    if [[ "$action" == uninstall ]]; then yay -Rns "${targets[@]}"; else yay -S "$package"; fi
    printf '\n  Press any key to return...'
    IFS= read -rsn1 key
    selected_packages=()
    load_packages
    build_columns
    prepare_layout
    normalize_selection
}

while :; do
    draw
    IFS= read -rsn1 key
    case "$key" in
        q|Q) exit 0 ;;
        j|B) ((selected_row < $(column_length) - 1)) && ((selected_row++)) ;;
        k|A) ((selected_row > 0)) && ((selected_row--)) ;;
        h) move_column 0 ;;
        l) move_column 1 ;;
        ' ')
            selected="$(selected_index)"
            if ((installed[selected])); then
                if [[ -n "${selected_packages[${packages[selected]}]:-}" ]]; then
                    unset "selected_packages[${packages[selected]}]"
                else
                    selected_packages["${packages[selected]}"]=1
                fi
            fi
            ;;
        d|D) confirm_action uninstall ;;
        r|R) confirm_action reinstall ;;
        '') confirm_action uninstall ;;
        $'\033')
            IFS= read -rsn2 key
            case "$key" in
                '[A') ((selected_row > 0)) && ((selected_row--)) ;;
                '[B') ((selected_row < $(column_length) - 1)) && ((selected_row++)) ;;
                '[D') move_column 0 ;;
                '[C') move_column 1 ;;
                '[5') IFS= read -rsn1 key; selected_row=$((selected_row - 8)); ((selected_row < 0)) && selected_row=0 ;;
                '[6') IFS= read -rsn1 key; selected_row=$((selected_row + 8)); ((selected_row >= $(column_length))) && selected_row=$(($(column_length) - 1)) ;;
            esac
            ;;
    esac
done