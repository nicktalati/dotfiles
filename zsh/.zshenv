# xdg dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

export PAGER="less"
export EDITOR="nvim"
export VISUAL="nvim"
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export XDG_CURRENT_DESKTOP=sway

export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
mkdir -p "$(dirname $ZSH_COMPDUMP)"
export HISTFILE="$ZDOTDIR/.zsh_history"

# docker config
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export DOCKER_DATA_HOME="$XDG_DATA_HOME/docker"
mkdir -p "$XDG_CONFIG_HOME/docker"
mkdir -p "$XDG_DATA_HOME/docker"


# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$HOME/.elan/bin:$PATH"
export PATH="$HOME/bin:$PATH"
eval "$(pyenv init - zsh)"

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

export PATH=$(echo $PATH | awk -v RS=':' -v ORS=':' '!a[$0]++ {if (NR > 1) printf ORS; printf $0}')
