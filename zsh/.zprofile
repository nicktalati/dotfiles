export PAGER=less
export EDITOR=nvim
export VISUAL=nvim

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export WLR_DRM_NO_ATOMIC=1

export PGSERVICEFILE="$HOME/.config/pg/pg_service.conf"
export PGPASSFILE="$HOME/.config/pg/pgpass"

export DOCKER_CONFIG="$HOME/.config/docker"

export PYTHON_HISTORY="$HOME/.local/state/python/history"
export MPLBACKEND=Agg
export PYENV_ROOT="$HOME/.pyenv"

export AWS_CONFIG_FILE="$HOME/.config/aws/config"
export AWS_SHARED_CREDENTIALS_FILE="$HOME/.config/aws/credentials"

typeset -U path PATH
path=(
    $PYENV_ROOT/bin
    $HOME/.local/bin
    $HOME/.elan/bin
    $path
)
