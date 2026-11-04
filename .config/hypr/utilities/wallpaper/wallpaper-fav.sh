#!/bin/bash
set -euo pipefail

LIB="${WALLPAPER_LIBRARY:-$HOME/wallpapers/library}"
LIST=$(readlink -f "$LIB/favorites.txt")
path="${1:?usage: wallpaper-fav.sh <image>}"
rel=$(realpath --relative-to="$(readlink -f "$LIB")" "$(readlink -f "$path")")

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/wallpaper-index.lock"
flock -w 5 9 || exit 1

touch "$LIST"
if grep -qxF -- "$rel" "$LIST"; then
    grep -vxF -- "$rel" "$LIST" > "$LIST.tmp" || true
    mv "$LIST.tmp" "$LIST"
else
    echo "$rel" >> "$LIST"
fi
