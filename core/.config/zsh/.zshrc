# exports
export GPG_TTY=$(tty)

# history
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=1000000
SAVEHIST=1000000
unsetopt list_beep
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# completions
ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
autoload -U compinit
mkdir -p "${ZSH_COMPDUMP:h}"
compinit -d "$ZSH_COMPDUMP"

[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# colors
eval "$(dircolors -b)"

# prompt like oh-my-zsh
setopt prompt_subst
autoload -U colors && colors

git_prompt_prefix="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
git_prompt_dirty="%{$fg[blue]%}) %{$fg[yellow]%}✗"
git_prompt_clean="%{$fg[blue]%})"
git_prompt_suffix="%{$reset_color%} "

git_prompt_info() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local ref
  ref="$(git symbolic-ref HEAD 2>/dev/null || git describe --exact-match HEAD 2>/dev/null)" || return
  ref="${ref#refs/heads/}"
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "${git_prompt_prefix}${ref}${git_prompt_dirty}${git_prompt_suffix}"
  else
    echo "${git_prompt_prefix}${ref}${git_prompt_clean}${git_prompt_suffix}"
  fi
}

PROMPT='%(?.%{$fg_bold[green]%}➜ .%{$fg_bold[red]%}➜ ) %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'

# gimme vim
bindkey -M viins 'kj' vi-cmd-mode
bindkey -v '^?' backward-delete-char

zle-keymap-select() {
  if [[ ${KEYMAP} == vicmd ]]; then
    echo -ne '\e[2 q'
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]]; then
    echo -ne '\e[6 q'
  fi
}
zle-line-init() { echo -ne '\e[6 q' }
zle -N zle-keymap-select
zle -N zle-line-init
echo -ne '\e[6 q'

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# aliases

alias sv="uv sync && uv pip install python-lsp-server pylsp-mypy mypy"

alias t="nvim -c 'normal Go' -c 'startinsert' $HOME/decrypt/todo.txt"
alias n="nvim"
alias m="neomutt"

alias ze="$EDITOR $ZDOTDIR/.zshrc"
alias zs="source $ZDOTDIR/.zshrc"
alias ae="$EDITOR $XDG_CONFIG_HOME/aws/credentials"
alias ne="$EDITOR $XDG_CONFIG_HOME/nvim/init.lua"

alias tree="tree --dirsfirst -a -I .git"
alias gtree="tree --gitignore --dirsfirst"
alias ls="ls --color=tty --group-directories-first"
alias lsa="ls -a --color=tty"
alias l="ls -lAh"
alias history="history 1"

alias gco='git checkout'

alias connect-beats="bluetoothctl connect 28:2D:7F:04:C7:7D"
alias disconnect-beats="bluetoothctl disconnect 28:2D:7F:04:C7:7D"

alias pkgup="pacman -Qqen > $HOME/dotfiles/pkglist.txt && echo 'Package list updated.'"

# fast nvm
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"

# fzf
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

function commandsearch() { print -rz "$(print -l ${(k)commands} | fzf)" }

bindkey -M viins -s '^f' "commandsearch\n"
bindkey -M vicmd -s '^f' "icommandsearch\n"

# secrets
[[ -f "$ZDOTDIR/secrets.zsh" ]] && source "$ZDOTDIR/secrets.zsh"
