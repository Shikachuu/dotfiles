# Variables
VISUAL='nvim'
EDITOR='nvim'
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
PATH="/usr/bin:$HOME/.local/bin:$PATH"
XDG_CONFIG_HOME="$HOME/.config"

# Default override
alias ls='ls -h --color=auto'
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
alias g='git'
alias incognito='HISTFILE="" exec bash'
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"
alias mylocalip="ip -j -4 address | jq '.[].addr_info[0] | \"\(.label): \(.local)\"' | sed 's/\"//g' | grep -v 'lo:.*'"
alias fcat='cat $(fzf)'
alias fed='nvim $(fzf)'
alias cd2='cd ../..'
alias compress="time tar -I 'zstd -8 -v' -cf"
alias lg='lazygit --ucd ~/.config/jesseduffield/lazygit'
alias k=kubectl
alias ltree='find . | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"'
complete -F __start_kubectl k

# Git commands
alias gtoday='git log --since=midnight --branches --no-merges --pretty=format:"%t%C(green)%d %C(magenta)%an %C(default)%cr: %C(bold)%s"'
alias gbcleanmr="git branch --merged origin/master | xargs git branch -d"
alias gbcleanmn="git branch --merged origin/main | xargs git branch -d"

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

function get_container_runtime() {
    if [ -x "$(command -v podman)" ]; then
        alias cr='podman'
    elif [ -x "$(command -v docker)" ]; then
        alias cr='docker'
    else
        echo "No container runtime found"
    fi
}

# Container commands
get_container_runtime
alias crit='cr run --rm -it'

# Flatpak
alias flatpak-export='flatpak list --app --columns=origin,application | tail -n +1'
alias flatpak-import='xargs -n2 flatpak install -y'

# Extends
# Load bash completion scripts on macOS and Linux
[[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
[[ -r "/usr/share/bash-completion/bash_completion" ]] && source "/usr/share/bash-completion/bash_completion"
eval "$(starship init bash)"
eval "$(zoxide init bash)"
source <(kubectl completion bash)
eval "$(mise completion bash)"
eval "$(mise activate bash)"
