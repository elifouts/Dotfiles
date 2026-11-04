#!/bin/bash
set -euo pipefail

LIB="${WALLPAPER_LIBRARY:-$HOME/wallpapers/library}"
URL=https://github.com/elifouts/wallpapers.git
mkdir -p "$LIB" && cd "$LIB"

case "${1:-}" in
    install)
        if [[ ! -d .git ]]; then
            git init -q -b main
            git remote add -t main origin "$URL"
            echo favorites.txt >> .git/info/exclude
        fi
        git fetch --depth 1 origin main
        git checkout -qf -B main origin/main ;;
    pull) git pull --ff-only ;;
    dev-pull)
        [[ $(git rev-parse --is-shallow-repository) == true ]] && git fetch --unshallow origin
        git fetch origin '+refs/heads/*:refs/remotes/origin/*'
        git pull --ff-only
        mkdir -p ../archive
        git archive origin/archive | tar -x -C ../archive ;;
    push)
        git add -A
        git commit -qm "${2:-update wallpapers}" || true
        git push origin main ;;
    *) git "${@:-status}" ;;
esac
