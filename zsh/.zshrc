# history
source $ZDOTDIR/history.zsh

# colors
eval "$(dircolors -b)"

# completions
source $ZDOTDIR/completion.zsh

# prompt
source $ZDOTDIR/prompt.zsh

# aliases
source $ZDOTDIR/aliases.zsh

# vi mode
source $ZDOTDIR/vi-mode.zsh

# functions
source $ZDOTDIR/functions/python.zsh
source $ZDOTDIR/functions/search.zsh
source $ZDOTDIR/functions/git.zsh
source $ZDOTDIR/functions/tmux.zsh

# api keys
[[ -f $ZDOTDIR/secrets.zsh ]] && source $ZDOTDIR/secrets.zsh
