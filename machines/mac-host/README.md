# mac-host

This is intentionally a thin macOS target. It owns FileVault, Safari and other
native graphical applications, a terminal emulator, and Lima. Development tools
and terminal mail belong in a Linux VM.

## Bootstrap

1. Update macOS and enable FileVault.
2. Install Homebrew using its official installer.
3. Install Bitwarden, sign in, import the personal SSH key, and enable its SSH
   agent:

   ```sh
   brew install --cask bitwarden
   export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
   ssh-add -L
   ```

4. Clone this repository to `~/dotfiles` using the agent:

   ```sh
   git clone git@github.com:nicktalati/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

5. Run:

   ```sh
   ./machines/mac-host/bootstrap.sh
   ```

The early Bitwarden install breaks the private-repository bootstrap cycle; the
Brewfile records it alongside Lima and Stow. The bootstrap then Stows the
`stow/macos` package, which owns `~/.zprofile` and `~/.local/bin/dev`. It applies
no `defaults` settings, does not configure Safari, and installs no native
development toolchain.

Import any remaining required SSH private keys into Bitwarden. The installed
shell profile detects either the Homebrew-cask or App Store socket. Open a new
terminal and verify it before creating the VM:

```sh
ssh-add -L
```

Lima forwards this agent into the guest; SSH private keys do not need to be
copied into the VM.

Use `./machines/mac-host/bootstrap.sh --check` for a read-only package check.

## Development VM

Create and provision the default Apple Silicon VM:

```sh
./machines/fedora-vm/create-lima.sh
limactl shell dev
~/dotfiles/scripts/install-vm --account cultivate
```

After provisioning, open a new macOS shell and run `dev`. The launcher starts
the VM when necessary and attaches to its persistent `dev` tmux session.

The initial target intentionally does not manage Safari settings, notifications,
attachment opening, Slack, macOS defaults, or backup settings.

## Host footprint and removal

The managed footprint is:

- Homebrew cask `bitwarden` and formulas `lima` and `stow`
- `~/.zprofile` and `~/.local/bin/dev` Stow links
- Lima instance data under its normal application-support directory

Remove the configuration links with:

```sh
stow --delete --no-folding --dir ~/dotfiles/stow --target "$HOME" macos
```

`limactl delete dev` deletes the VM and all unpushed VM state. Homebrew packages
are not uninstalled automatically because the bootstrap cannot safely infer
whether they predated this repository.
