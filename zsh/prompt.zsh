# like oh-my-zsh
setopt prompt_subst
autoload -U colors && colors
zmodload zsh/ vcs_info 2>/dev/null || true

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

PROMPT='%(!.%{$fg_bold[red]%}➜ .%{$fg_bold[green]%}➜ )'
PROMPT+=' %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
