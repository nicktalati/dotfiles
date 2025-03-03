# vi mode
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
