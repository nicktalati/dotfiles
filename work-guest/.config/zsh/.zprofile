export PAGER=less
export MANPAGER="less -R"
export EDITOR=nvim
export VISUAL=nvim

export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"
export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export MPLBACKEND=Agg
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export PSQLRC="$XDG_CONFIG_HOME/psql/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/psql/history"
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

export CODEX_HOME="$XDG_CONFIG_HOME/codex"
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
export TASKRC="$XDG_CONFIG_HOME/task/taskrc"
export TASKDATA="$XDG_DATA_HOME/task"

typeset -U path PATH
path=(
    "$HOME/.local/bin"
    $path
)
