# Variables
VISUAL='nvim'
EDITOR='nvim'
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
PATH="$HOME/.arkade/bin/:/usr/bin:$PATH"

# Default override
alias ls='ls -hN --color=auto --group-directories-first'
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -vI"
alias bc="bc -ql"
alias sudo='sudo -v; sudo '
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias vim='nvim'

# Common typos
alias cd..='cd ..'

# Extend default features
alias ll='ls -alF'
alias la='ls -A'
alias incognito='HISTFILE="" exec bash'
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"
alias mylocalip="ip -j -4 address | jq '.[].addr_info[0] | \"\(.label): \(.local)\"' | sed 's/\"//g' | grep -v 'lo:.*'"
alias fcat='cat $(fzf)'
alias fed='nvim $(fzf)'
alias cd2='cd ../..'
alias compress="time tar -I 'zstd -8 -v' -cf"
alias k=kubectl
complete -F __start_kubectl k
alias ark=arkade
complete -F __start_arkade ark
if [[ $TERM == "xterm-kitty" ]]; then
    alias ssh="kitty +kitten ssh"
fi

# Git commands
alias glog='git log --decorate --date=relative'
alias gtoday='git log --since=midnight --branches --no-merges --pretty=format:"%t%C(green)%d %C(magenta)%an %C(default)%cr: %C(bold)%s"'
alias gco='git checkout'
alias gdropl='git reset --hard HEAD~1'
alias gignore='git update-index --assume-unchanged'
alias gcall='git add -A && git commit -s -m $@'
alias gbcleanmr="git branch --merged origin/master | xargs git branch -d"
alias gbcleanmn="git branch --merged origin/main | xargs git branch -d"
alias gpull='git pull --rebase'

# Container commands
alias pm='podman'
alias cr='podman run --rm -it'
alias node='podman run --rm -it --init -v $HOME/pm-cache/npm/:/root/:Z -v $PWD:/app:Z -w /app --network host node $@'
alias npm='podman run --rm -it --init -v $HOME/pm-cache/npm/:/root/:Z -v $PWD:/app:Z -w /app --network host npm $@'
alias npx='podman run --rm -it --init -v $HOME/pm-cache/npm/:/root/:Z -v $PWD:/app:Z -w /app --network host npx $@'

# Functions
# Copies the 1st argument to the clipboard using wl-copy or pbcopy
function ctc() {
    if [ -x "$(command -v wl-copy)" ]; then
        cat $1 | wl-copy
    elif [ -x "$(command -v pbcopy)" ]; then
        cat $1 | pbcopy
    else
        echo "No clipboard command found"
    fi
}

# Pastes the clipboard using wl-paste or pbpaste
function pfc() {
    if [ -x "$(command -v wl-paste)" ]; then
        wl-paste
    elif [ -x "$(command -v pbpaste)" ]; then
        pbpaste
    else
        echo "No clipboard command found"
    fi
}

# Flatpak
alias flatpak-export='flatpak list --app --columns=origin,application | tail -n +1'
alias flatpak-import='xargs -n2 flatpak install -y'

# Extends
# Load bash completion scripts on macOS and Linux
[[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
[[ -r "/usr/share/bash-completion/bash_completion" ]] && source "/usr/share/bash-completion/bash_completion"
eval "$(starship init bash)"
eval "$(zoxide init bash)"
source <(arkade completion bash)
source <(kubectl completion bash)
