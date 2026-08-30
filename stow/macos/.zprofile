if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Keychain remembers the key passphrase, but the agent stays empty until
# something asks for it: a cold boot leaves Git unable to sign and the VM's
# forwarded agent with no identities, which is what a failed guest clone looks
# like. Loading it at login is idempotent.
ssh-add --apple-load-keychain -q 2>/dev/null

typeset -U path PATH
path=("$HOME/.local/bin" $path)
