# Lima records the guest login shell in the instance itself
# (LIMA_CIDATA_SHELL=/bin/bash) and runs that for `limactl shell`, so changing
# /etc/passwd in the guest does not move `limactl shell` to zsh. Hand an
# interactive Bash login over instead. `bash -lc ...`, which Lima uses to run
# commands, stays Bash.
if [[ $- == *i* && -x /usr/bin/zsh ]]; then
    export SHELL=/usr/bin/zsh
    exec /usr/bin/zsh -l
fi
