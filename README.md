# Dotfiles

Dotfiles and machine definitions for thin Arch and macOS hosts plus a shared,
disposable Fedora development VM.

The repository does not model personal and work as separate tool environments.
Home and non-secret account configuration are shared. Credentials determine
which identities are active on a machine.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the boundary rationale.

## Repository layout

```text
stow/       application and account GNU Stow packages
machines/   physical-host targets and Linux VM targets
tests/      focused smoke tests with isolated temporary homes and fake Lima
```

## Apple Silicon Mac

The Mac remains thin: FileVault, Safari, Bitwarden, other native graphical
applications, Homebrew, Stow, and Lima live on macOS. Development tools, tmux,
Neovim, and terminal mail live in the Fedora VM.

After enabling FileVault and installing Homebrew, generate this machine's SSH
key with a passphrase, load it into macOS's native agent, and register the
public half at <https://github.com/settings/keys> twice — as an authentication
key and as a signing key. Private keys are machine state: generated here, never
copied anywhere.

```sh
ssh-keygen -t ed25519
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
git clone git@github.com:nicktalati/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Then run on macOS:

```sh
./machines/mac-host/bootstrap.sh
```

The bootstrap installs Lima and Stow, installs Bitwarden only for web passwords,
and configures `UseKeychain` for the native SSH agent. Open a new terminal,
verify the agent with `ssh-add -L`, then create and enter the VM:

```sh
./machines/fedora-vm/create-lima.sh
limactl shell dev
```

Inside the VM, install the shared environment:

```sh
~/dotfiles/machines/fedora-vm/install.sh
```

Open a new macOS shell and run `dev` to start the VM if necessary and attach to
its persistent tmux session.

### Mail enrollment

Each mail account has a writable OAuth-token location:

```text
~/.local/share/mail/oauth/cultivate
~/.local/share/mail/oauth/personal
```

The token file contains the registration values, refresh token, and mutable
access state; it is recreatable and deliberately not backed up. Enroll an
account fresh with:

```sh
mail-enroll cultivate
```

The script prompts for the client id and secret (kept in Bitwarden; also
recoverable from the Google Cloud console), runs Google's consent flow through
a printed URL, and starts the account's mail services. Open the URL in a
browser on the host; Lima forwards the localhost redirect into the guest.

Alternatively, copy an existing token file from another machine into the same
path, then start push notifications:

```sh
systemctl --user start goimapnotify@cultivate.service
```

Every account's mail units are always enabled and condition on the token file,
so mbsync resumes on its next timer fire either way. There are no launchd mail
services: NeoMutt, mbsync, and goimapnotify run as systemd user services inside
the Linux VM.

## Physical Arch host

The existing desktop is represented by `machines/arch-host` and currently
enables every account:

```sh
./machines/arch-host/install.sh
```

This is a transitional full-system installer. It installs packages, writes the
two declared `/etc` files, configures the existing Firefox profiles, enables
services, and changes the login shell. It deliberately preserves the current
development, mail, and backup behavior while the Fedora VM is proven on the
Mac. After the same Fedora VM is validated on Arch, the host will be
reduced to hardware, desktop, native applications, Lima, and minimal host
operation.

## Accounts

The account packages are:

- `account-cultivate`: the Cultivate Git identity and Google Workspace mail
- `account-personal`: the personal Git identity and Gmail

They contain ordinary application configuration only; SSH keys and OAuth tokens
are machine state. Put repositories under `~/code/cultivate` or
`~/code/personal`; Git conditional includes select the corresponding identity.

## Backups

restic snapshots `~/docs`, `~/photos`, `~/reading`, `~/dotfiles`, and the Zsh
history to S3 daily, and to the offline USB drive with `mount_drive` followed
by `backup usb`. The service conditions on machine credentials, so enrolling a
machine is one file created from the Bitwarden "restic backup" item:

```sh
mkdir -p ~/.config/restic
nvim ~/.config/restic/env    # the three export lines from Bitwarden
chmod 600 ~/.config/restic/env
```

```sh
export RESTIC_PASSWORD='...'
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
```

Restore by sourcing that file, then `restic snapshots` and `restic restore`.

## Package maintenance and validation

Use `pkgsync diff` to compare the active machine manifest with explicitly
installed packages, and `pkgsync sync` to run that machine's package-only
installer.

Run the smoke suite with:

```sh
./tests/run.sh
```
