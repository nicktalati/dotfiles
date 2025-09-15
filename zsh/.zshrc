###############################################################################
# pyenv
###############################################################################
command -v pyenv >/dev/null && eval "$(pyenv init - zsh)"

###############################################################################
# nvm
###############################################################################
if [ -z "${NVM_DIR:-}" ]; then
  NVM_DIR="$HOME/.nvm"
  [ -n "${XDG_CONFIG_HOME:-}" ] && NVM_DIR="$XDG_CONFIG_HOME/nvm"
fi
export NVM_DIR

# "nvm exec" and certain 3rd party scripts expect "nvm.sh" and "nvm-exec" to
# exist under $NVM_DIR
[ ! -e "$NVM_DIR" ] && mkdir -vp "$NVM_DIR"
[ ! -e "$NVM_DIR/nvm.sh" ] && ln -vs /usr/share/nvm/nvm.sh "$NVM_DIR/nvm.sh"
[ ! -e "$NVM_DIR/nvm-exec" ] && ln -vs /usr/share/nvm/nvm-exec "$NVM_DIR/nvm-exec"

. /usr/share/nvm/nvm.sh
. /usr/share/nvm/bash_completion

###############################################################################
# history
###############################################################################
HISTFILE=$HOME/.local/state/zsh/history
HISTSIZE=1000000
SAVEHIST=1000000
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

###############################################################################
# colors
###############################################################################
eval "$(dircolors -b)"

###############################################################################
# completions
###############################################################################
ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump"
autoload -U compinit
compinit -d $ZSH_COMPDUMP

[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

###############################################################################
# prompt like oh-my-zsh
###############################################################################
setopt prompt_subst
autoload -U colors && colors
zmodload zsh/vcs_info 2>/dev/null || true

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "

function git_prompt_info() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local ref
  ref="$(git symbolic-ref HEAD 2>/dev/null || git describe --exact-match HEAD 2>/dev/null)" || return
  ref="${ref#refs/heads/}"
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${ZSH_THEME_GIT_PROMPT_DIRTY}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
  else
    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${ZSH_THEME_GIT_PROMPT_CLEAN}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
  fi
}

PROMPT='%(?.%{$fg_bold[green]%}➜ .%{$fg_bold[red]%}➜ ) %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'

###############################################################################
# aliases
###############################################################################
alias ze="$EDITOR $ZDOTDIR/.zshrc"
alias zs="source $ZDOTDIR/.zshrc"
alias ae="$EDITOR $HOME/.config/aws/credentials"
alias ne="$EDITOR $HOME/.config/nvim/init.lua"

alias tree="tree --gitignore --dirsfirst"
alias ls="ls --color=tty --group-directories-first"
alias lsa="ls -a --color=tty"
alias l="ls -lAh"
alias history="history 1"

alias gco='git checkout'

alias connect-beats="bluetoothctl connect 28:2D:7F:04:C7:7D"
alias disconnect-beats="bluetoothctl disconnect 28:2D:7F:04:C7:7D"

###############################################################################
# vi mode
###############################################################################
set -o vi
bindkey '^R' history-incremental-search-backward
bindkey -M viins 'kj' vi-cmd-mode
bindkey -v '^?' backward-delete-char

# cursor
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]]; then
    echo -ne '\e[2 q'
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]]; then
    echo -ne '\e[6 q'
  fi
}

function zle-line-init {
  echo -ne '\e[6 q'
}

zle -N zle-keymap-select
zle -N zle-line-init
echo -ne '\e[6 q'

###############################################################################
# functions
###############################################################################
source $ZDOTDIR/functions/python.zsh
source $ZDOTDIR/functions/search.zsh

###############################################################################
# api keys
###############################################################################
[[ -f $ZDOTDIR/secrets.zsh ]] && source $ZDOTDIR/secrets.zsh
