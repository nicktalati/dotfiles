function tmux_switch_session() {
    [[ $# -ne 1 ]] && echo "Takes tmux session index as only argument." && return 1
    local IDX=$(($1 + 1))
    local SESSION_NAME=$(tmux ls -F \#S | awk "NR==$IDX")
    [[ -n "$SESSION_NAME" ]] && tmux switch-client -t $SESSION_NAME && return 0
    echo "Session $1 does not exist." && return 1
}
