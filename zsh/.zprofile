export PAGER=less
export EDITOR=nvim
export VISUAL=nvim

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export GTK_USE_PORTAL=1
export MOZ_ENABLE_WAYLAND=1
export WLR_DRM_NO_ATOMIC=1

export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"
export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"

export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export MPLBACKEND=Agg

export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
export ELAN_HOME="$XDG_DATA_HOME/elan"

export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"

export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"

export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NVM_DIR="$XDG_DATA_HOME/nvm"

export PSQLRC="$XDG_CONFIG_HOME/psql/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/psql/history"

typeset -U path PATH
path=(
    "$PYENV_ROOT/bin"
    "$ELAN_HOME/bin"
    "$HOME/.local/bin"
    $path
)
