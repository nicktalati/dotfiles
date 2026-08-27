# Dotfiles architecture

The repository has three explicit kinds of configuration:

1. A machine target owns operating-system packages, system configuration, and
   bootstrap behavior.
2. A Stow package owns a coherent part of `$HOME`.
3. An account Stow package contains one identity's native, non-secret Git, SSH,
   and mail configuration.

There is no personal/work machine hierarchy. Tools are shared, while each
machine selects the account packages whose credentials it should use.

## Machine targets

`machines/` contains concrete targets:

- `arch-host`: the physical Arch desktop
- `mac-host`: a thin macOS host for native applications and Lima
- `fedora-vm`: the default Linux development VM on Apple Silicon and x86-64
- `arch-vm`: a temporary x86-64 fallback retained until Fedora is proven on the
  physical Arch host

Each physical host and its Fedora VM are separate lifecycle and security
domains. Host home directories are not mounted in the VM. Repositories live on
the guest filesystem; explicit copies or a future narrowly scoped exchange
directory cross that boundary.

## Stow packages

The application-level packages remain independent because their filesystem
ownership is useful to inspect directly:

- `shell`: Zsh, readline, XDG environment, and shell-history backup
- `nvim`: Neovim
- `tmux`: tmux and the session launcher
- `git`: Git defaults, SSH defaults, and the Linux SSH-agent unit
- `mail`: account-independent NeoMutt and mail-service configuration
- `psql`: PostgreSQL client configuration
- `task`: Taskwarrior
- `arch-backup`: physical-Arch-host backup commands and timer
- `arch-desktop`: Sway, Foot, and the Arch graphical environment
- `arch-vault`: the Arch host's legacy gocryptfs and rclone integration
- `macos`: Homebrew setup, Bitwarden SSH-agent discovery, and the VM launcher

`account-cultivate`, `account-personal`, and `account-paypal` contain the native
configuration files for those identities. Repeated facts are kept in the
formats that consume them. Three stable accounts do not justify a private
schema or configuration renderer.

Repository commands that are not deployed configuration live in `bin/`.
`~/dotfiles/bin` is on the shell path.

## Target composition

```text
linux-home = shell + nvim + tmux + git + mail + psql + task

mac-host  = macos

fedora-vm = linux-home + explicitly selected account packages
```

The intended physical-Arch endpoint mirrors the Mac boundary: the host owns
hardware, networking, the graphical desktop, native browser and password
manager, Lima, and only enough shell configuration to operate the host. The
Fedora VM owns development tools, terminal mail, and account configuration.

The current `arch-host` implementation is deliberately transitional. It still
composes `linux-home`, all account packages, `arch-backup`, `arch-desktop`, and
`arch-vault` so this live machine remains functional while the Mac environment
is validated. It must not be pruned until the Fedora VM works in real use on
both hosts. `arch-vm` remains a fallback during the same migration; it is not a
second long-term guest standard.

The VM installer records the target and selected accounts in
`~/.config/dotfiles`. Omitting `--account` on a later run preserves the current
selection. NeoMutt's account source list and Notmuch's identity list are the
only generated account files.

Git identity is repository-scoped:

- repositories under `~/code/personal` use the personal identity
- repositories under `~/code/cultivate` use the Cultivate identity

Mail synchronization and IMAP watching use per-account systemd instances such
as `mbsync@cultivate.timer` and `goimapnotify@cultivate.service`.

## Package policy

Each machine has one concrete package manifest. Distribution package names and
installation mechanics are not abstracted into cross-platform fragments.

The physical Arch host and temporary Arch VM use Pacman plus yay. Fedora uses
DNF first. Tools unavailable from Fedora repositories are pinned in
`machines/fedora-vm/tools.lock.json`; the installer verifies checksums and keeps
versioned payloads under `~/.local/opt`.

The Fedora cloud-image digest and directly downloaded binaries remain pinned.
Those checksums are integrity and reproducibility boundaries, not generated
configuration that should be removed.

## Credential boundary

Account packages contain no secrets.

On the Mac, Bitwarden owns SSH private keys and exposes its SSH agent to the
host shell. Lima forwards that agent into the Fedora VM at
`/run/host-services/ssh-auth.sock`; private keys do not enter the guest.

OAuth refresh-token files are different: NeoMutt's helper rewrites them during
refresh, while Bitwarden CLI access requires an interactive unlocked session.
VM OAuth tokens therefore live as mode-0600 files under
`~/.local/share/mail/oauth`. They are deliberately not backed up and can be
recreated by authorizing the account again. FileVault protects the VM disk at
rest.

The Arch root filesystem is not currently encrypted. Its OAuth tokens and SSH
private keys remain in the existing gocryptfs vault. The Arch installer exposes
the OAuth files at the same `~/.local/share/mail/oauth/<account>` paths through
symlinks, so account configuration stays identical across Linux targets.

The VM does not install gocryptfs or rclone and does not create `~/crypt` or
`~/decrypt`.

## Invariants

- Machine names describe topology, not personal/work policy.
- Account selection is explicit and independently changeable.
- Account configuration is native and inspectable; there is no renderer.
- Physical hosts receive no development toolchain after migration.
- Host home directories are not mounted into development VMs.
- SSH private keys are forwarded to the VM through an agent, not copied.
- Directly downloaded artifacts are versioned and checksummed.
- Valuable VM state must survive VM deletion independently.
- Repeated installation is safe.
