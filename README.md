# Dotfiles

Dotfiles and machine definitions for thin Arch and macOS hosts plus a shared,
disposable Fedora development VM.

The repository does not model personal and work as separate tool environments.
Home configuration is shared; independently selected account packages provide
Git, SSH, and mail identities.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the boundary rationale.

## Repository layout

```text
bin/        repository maintenance commands available on PATH
stow/       application and account GNU Stow packages
machines/   physical-host targets and Linux VM targets
scripts/    VM provisioning and repository bootstrap helpers
tests/      focused smoke tests with isolated temporary homes and fake Lima
```

## Apple Silicon Mac

The Mac remains thin: FileVault, Safari, Bitwarden, other native graphical
applications, Homebrew, Stow, and Lima live on macOS. Development tools, tmux,
Neovim, and terminal mail live in the Fedora VM.

After enabling FileVault and installing Homebrew, install Bitwarden first so its
SSH agent can authenticate the private repository clone:

```sh
brew install --cask bitwarden
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
ssh-add -L
git clone git@github.com:nicktalati/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Then run on macOS:

```sh
./machines/mac-host/bootstrap.sh
```

The bootstrap installs Lima and Stow and records Bitwarden in its Brewfile. Open
a new terminal and verify that the installed shell profile still sees the
Bitwarden keys:

```sh
ssh-add -L
```

Then create and enter the VM:

```sh
./machines/fedora-vm/create-lima.sh
limactl shell dev
```

Inside the VM, provision the shared environment and choose accounts:

```sh
~/dotfiles/scripts/install-vm --account cultivate
```

Repeat `--account` to select more than one:

```sh
~/dotfiles/scripts/install-vm \
    --account cultivate \
    --account personal
```

The selection is preserved on later runs. Open a new macOS shell and run `dev`
to start the VM if necessary and attach to its persistent tmux session.

### Mail enrollment

Each selected account has a writable OAuth token at:

```text
~/.local/share/mail/oauth/cultivate
~/.local/share/mail/oauth/personal
~/.local/share/mail/oauth/paypal
```

Authorize a missing token with NeoMutt's `mutt_oauth2.py`, using the Google OAuth
client ID and secret stored in Bitwarden. Pass `--encryption-pipe cat` and
`--decryption-pipe cat`; FileVault protects the VM disk. Then restrict the file
and rerun the installer:

```sh
chmod 600 ~/.local/share/mail/oauth/cultivate
~/dotfiles/scripts/install-vm
```

The installer enables mail services only for accounts whose token file exists.
There are no launchd mail services: NeoMutt, mbsync, and goimapnotify run as
systemd user services inside the Linux VM.

## Physical Arch host

The existing desktop is represented by `machines/arch-host` and currently
enables all three accounts:

```sh
./machines/arch-host/install.sh
```

This is a transitional full-system installer. It installs packages, writes the
two declared `/etc` files, configures the existing Firefox profiles, enables
services, and changes the login shell. It deliberately preserves the current
development, mail, and gocryptfs/rclone behavior while the Fedora VM is proven
on the Mac. After the same Fedora VM is validated on Arch, the host will be
reduced to hardware, desktop, native applications, Lima, and minimal host
operation.

## Temporary x86-64 Arch VM fallback

An Arch guest remains available as a migration fallback:

```sh
./machines/arch-vm/create-lima.sh
limactl shell dev
~/dotfiles/scripts/install-vm --account cultivate
```

The Arch VM is intentionally rejected on ARM hosts. It is not the intended
second guest platform; the Fedora definition already pins both ARM64 and x86-64
images and is the target on both physical hosts.

## Accounts

The account packages are:

- `account-cultivate`: Cultivate Git, SSH, and Google Workspace mail
- `account-personal`: personal Git, SSH, and Gmail
- `account-paypal`: the separate PayPal Gmail account

They contain ordinary application configuration and public SSH keys, never
private keys or OAuth tokens. Put repositories under `~/code/cultivate` or
`~/code/personal`; Git conditional includes select the corresponding identity.

## Package maintenance and validation

Use `pkgsync diff` to compare the active machine manifest with explicitly
installed packages, and `pkgsync sync` to install the declared packages.

Run the smoke suite with:

```sh
./tests/run.sh
```
