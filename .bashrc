[[ $- != *i* ]] && return
export EDITOR=nvim
export VISUAL=nvim
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.npm-global/bin:$PATH"
export wallpaper="$HOME/wallpapers/pywallpaper.jpg"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
{ [[ $NOFETCH ]] || myfetch -c 8 -C " █"; } && eval "$(starship init bash)"
alias lsd='eza --icons'
alias grep='grep --color=auto'
alias c='clear'
alias n='nvim'
alias v='nvim'
alias tasks='btm'
alias spot='ncspot'
alias untar='tar -xf'
alias fonts='fc-list -f "%{family}\n"'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias Docs='cd "$HOME/Documents" && nvim'
alias Settings='cd "$HOME/.config/hypr" && nvim'
alias search='yay -Q | grep'
alias paci='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacs='pacman -Ss'
alias pacq='pacman -Qs'
alias pacinfo='pacman -Qi'
alias pacfiles='pacman -Ql'
alias pacclean='sudo paccache -r'
pacup() { sudo pacman -Syu "$@"; }
pacorphans() {
    local packages
    packages=$(pacman -Qdtq) || return
    [[ -z "$packages" ]] && {
        echo "No orphaned packages found."
        return 0
    }
    printf 'Orphaned packages:\n%s\n' "$packages"
    read -r -p "Remove these packages? [y/N] " confirm
    [[ "$confirm" == [yY] ]] && sudo pacman -Rns $packages
}

alias ports='ss -tulpn'
alias mem='free -h'
alias disk='df -h'
alias failed='systemctl --failed'
alias journal='journalctl -p 3 -xb'
alias boot='systemd-analyze'
alias gpu='nvidia-smi'
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph -15'
alias docker='sudo docker'
alias start-portainer='docker start portainer'
alias stop-portainer='docker stop portainer'
alias start-docker='sudo systemctl start docker'
alias stop-docker='sudo systemctl stop docker.service docker.socket'
alias restart-docker='sudo systemctl restart docker'
alias pool='clear && asciiquarium'
alias f='clear && myfetch -i e -f -c 16 -C "  "'
alias mefetch='clear && myfetch -c 8 -C " █" && eval "$(starship init bash)"'
alias h='dbus-launch Hyprland'
alias wss='hyprdvd -s'
alias hyprrefresh='hyprctl reload'
alias hypr='cd ~/.config/hypr && nvim'
alias bashrc='n .bashrc'
alias bye='sudo shutdown -h now'
alias loop='sudo reboot'
dotpull() { git -C ~/Dotfiles pull && ~/Dotfiles/InstallScripts/apply.sh; }
dotpush() {
    local dir=~/Dotfiles msg
    [[ -z "$(git -C "$dir" status --porcelain)" ]] && {
        echo "Nothing to commit."
        return 0
    }
    echo "Files changed:"
    git -C "$dir" status --short
    read -r -p "Commit message (empty to cancel): " msg
    [[ -z "$msg" ]] && {
        echo "Cancelled."
        return 1
    }
    git -C "$dir" add -A && git -C "$dir" commit -m "$msg" && git -C "$dir" push
}
alias InstallDots='~/Dotfiles/InstallScripts/install.sh'
alias reload='source "$HOME/.bashrc"'
alias Dotfiles='cd ~/Dotfiles/ && nvim'
alias Nvim='cd ~/.config/nvim/ && nvim'
function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
}
export PATH="$HOME/.local/bin:$PATH"
