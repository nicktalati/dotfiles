# config editing
alias ze="$EDITOR $ZDOTDIR/.zshrc"
alias zs="source $ZDOTDIR/.zshrc"
alias ae="$EDITOR $HOME/.aws/credentials"
alias ne="$EDITOR $HOME/.config/nvim/init.lua"

# utils
alias tree="tree --gitignore --dirsfirst"
alias ls="ls --color=tty --group-directories-first"
alias lsa="ls -a --color=tty"
alias l="ls -lAh"
alias history="history 0"

# Git aliases
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gb='git branch'
alias gba='git branch -a'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcam='git commit -a -m'
alias gcb='git checkout -b'
alias gcm='git checkout main'
alias gco='git checkout'
alias gd='git diff'
alias gdca='git diff --cached'
alias gf='git fetch'
alias gl='git pull'
alias glog='git log --oneline --decorate --graph'
alias gp='git push'
alias grb='git rebase'
alias gss='git status -s'
alias gst='git status'

# private
[[ -f $ZDOTDIR/aliases_private.zsh ]] && source $ZDOTDIR/aliases_private.zsh
