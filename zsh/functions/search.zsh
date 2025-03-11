# search funcs
function commandsearch() {
    com=$(echo ${(k)commands} | tr ' ' '\n' | fzf)
    if [[ -z $com ]]; then
        return
    fi
    print -z "$com"
}

function historysearch() {
    selected=$(history | awk '{$1=""; print substr($0,2)}' | fzf)

    if [[ -z $selected ]]; then
        return
    fi

    print -z "$selected"
}

ulbs () {
    emulate -L zsh
    typeset -g __searching __savecursor
    if [[ $LBUFFER == *$'\n'* ]]
    then
        zle .up-line-or-history
        __searching=''
    elif [[ -n $PREBUFFER ]] && zstyle -t ':zle:up-line-or-beginning-search' edit-buffer
    then
        zle .push-line-or-edit
    else
        [[ $LASTWIDGET = $__searching ]] && CURSOR=$__savecursor
        __savecursor=$CURSOR
        __searching=$WIDGET
        zle .history-beginning-search-backward
        zstyle -T ':zle:up-line-or-beginning-search' leave-cursor && zle .end-of-line
    fi
}

dlbs () {
    emulate -L zsh
    typeset -g __searching __savecursor
    if [[ ${+NUMERIC} -eq 0 && ( $LASTWIDGET = $__searching || $RBUFFER != *$'\n'* ) ]]
    then
        [[ $LASTWIDGET = $__searching ]] && CURSOR=$__savecursor
        __searching=$WIDGET
        __savecursor=$CURSOR
        if zle .history-beginning-search-forward
        then
            [[ $RBUFFER = *$'\n'* ]] || zstyle -T ':zle:down-line-or-beginning-search' leave-cursor && zle .end-of-line
            return
        fi
        [[ $RBUFFER = *$'\n'* ]] || return
    fi
    __searching=''
    zle .down-line-or-history
}

zle -N ulbs
zle -N dlbs

# bindings
bindkey -M viins -s '^f' "commandsearch\n"
bindkey -M viins -s '^n' "historysearch\n"

bindkey -M vicmd -s '^f' "icommandsearch\n"
bindkey -M vicmd -s '^h' "ihistorysearch\n"

bindkey -M vicmd 'k' ulbs
bindkey -M vicmd 'j' dlbs
