# ~/.bashrc
clear && myfetch -c 8 -C " █"
eval "$(starship init bash)"
eval "$(fzf --bash)"
[[ $- != *i* ]] && return
alias lsd='eza --icons'
alias search='yay -Q | grep'
alias pacup='sudo pacman -Rns $(pacman -Qdtq)'
alias grep='grep --color=auto'
alias pool='clear && asciiquarium'
alias f='clear && myfetch -i e -f -c 16 -C "  "'
alias bye='paplay ~/.config/sounds/shudown.mp3 && shutdown now'
alias loop='sudo reboot'
alias h='start-hyprland'
alias fonts='fc-list -f "%{family}\n"'
alias tasks='btm'
alias Docs="cd ~/Documents && nvim"
alias docker="sudo docker"
alias Settings="cd ~/.config/hypr && nvim"
alias spot="ncspot"
alias untar="tar -xf"
alias n="nvim"
alias start-portainer='docker start portainer'
alias stop-portainer='docker stop portainer'
alias start-docker='sudo systemctl start docker'
alias stop-docker='sudo systemctl stop docker.service docker.socket'
alias restart-docker='sudo systemctl restart docker'
alias files="yazi"
alias wss="hyprdvd -s"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
PS1='[\u@\h \W]\$ '
export PATH=~/.npm-global/bin:$PATH
export EDITOR=nvim
export VISUAL=nvim

lol() {
    local status=$?
    if [ $status -ne 0 ]; then
        (paplay ~/.config/sounds/error.mp3 >/dev/null 2>&1 &)
    else
        (paplay ~/.config/sounds/good.mp3 >/dev/null 2>&1 &)
    fi
}
# PROMPT_COMMAND="lol; $PROMPT_COMMAND"
