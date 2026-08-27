if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

typeset -U path PATH
path=("$HOME/dotfiles/bin" "$HOME/.local/bin" $path)

# Support both Bitwarden distribution channels. Lima forwards whichever agent
# the host shell exposes when the VM starts.
for bitwarden_socket in \
    "$HOME/.bitwarden-ssh-agent.sock" \
    "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"; do
    if [[ -S "$bitwarden_socket" ]]; then
        export SSH_AUTH_SOCK="$bitwarden_socket"
        break
    fi
done
unset bitwarden_socket
