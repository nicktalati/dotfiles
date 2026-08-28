# Dotfiles architecture

The repository has three explicit kinds of configuration:

1. A machine target owns operating-system packages, system configuration, and
   bootstrap behavior.
2. A Stow package owns a coherent part of `$HOME`.
3. An account Stow package contains one identity's native, non-secret Git, SSH,
   and mail configuration.

There is no personal/work machine hierarchy. Tools and non-secret account
configuration are shared; credentials determine which accounts are active.

## Machine targets

`machines/` contains concrete targets:

- `arch-host`: the physical Arch desktop
- `mac-host`: a thin macOS host for native applications and Lima
- `fedora-vm`: the default Linux development VM on Apple Silicon and x86-64

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
- `backup`: restic snapshots to S3 and the offline USB drive
- `arch-desktop`: Sway, Foot, and the Arch graphical environment
- `macos`: Homebrew setup, native macOS SSH configuration, and the VM launcher

`account-cultivate` and `account-personal` contain the native configuration
files for those identities. Repeated facts are kept in the formats that consume
them. Two stable accounts do not justify a private schema or configuration
renderer.

## Target composition

```text
linux-home = shell + nvim + tmux + git + mail + psql + task

mac-host  = macos

fedora-vm = linux-home + all account packages
```

The intended physical-Arch endpoint mirrors the Mac boundary: the host owns
hardware, networking, the graphical desktop, native browser and password
manager, Lima, and only enough shell configuration to operate the host. The
Fedora VM owns development tools, terminal mail, and account configuration.

The current `arch-host` implementation is deliberately transitional. It still
composes `linux-home`, all account packages, `backup`, and `arch-desktop` so
this live machine remains functional while the Mac environment is validated. It must not be pruned until the Fedora VM works in real use on
both hosts. The still-functional physical Arch environment is the rollback path
during this migration; a second guest distribution is unnecessary.

Both account packages are Stowed because they contain no secrets. NeoMutt's
account composition and Notmuch's identity list are ordinary static
configuration in the `mail` package. OAuth-token presence controls mail
services, and the keys loaded in the host agent control SSH access.

Git identity is repository-scoped:

- repositories under `~/code/personal` use the personal identity
- repositories under `~/code/cultivate` use the Cultivate identity

Mail synchronization and IMAP watching use per-account systemd instances such
as `mbsync@cultivate.timer` and `goimapnotify@cultivate.service`. All accounts'
units are enabled; each conditions on its account's OAuth-token file
(`ConditionPathExists`), so credentials alone determine which ones run.

## Package policy

Each machine has one concrete package manifest. Distribution package names and
installation mechanics are not abstracted into cross-platform fragments.

The physical Arch host uses Pacman plus yay. Fedora uses DNF first. Tools
unavailable from Fedora repositories are pinned in
`machines/fedora-vm/tools.lock.json`; the installer verifies checksums and keeps
versioned payloads under `~/.local/opt`.

The Fedora cloud-image digest and directly downloaded binaries remain pinned.
Those checksums are integrity and reproducibility boundaries, not generated
configuration that should be removed.

## Credential boundary

Account packages contain no secrets.

Each machine generates its own passphrase-protected SSH key and registers the
public half where it needs access; private keys never leave the machine that
made them. Git signs with the machine key, so repository location selects only
the account e-mail. On the Mac, the native agent holds the unlocked identity
and Keychain may remember the passphrase. Lima forwards the agent into the
Fedora VM at `/run/host-services/ssh-auth.sock`; private keys do not enter the
guest.

OAuth refresh-token files are different: NeoMutt's helper rewrites them during
refresh. On every Linux target they live as mode-0600 files under
`~/.local/share/mail/oauth`. They are deliberately not backed up and are
recreated with `mail-enroll`, which prompts for the registration values kept in
Bitwarden. FileVault protects the VM disk at rest.

Personal documents live in plain directories and are protected off-machine by
restic, which encrypts client-side before writing to S3 or the offline USB
drive. The backup service conditions on `~/.config/restic/env`, so machines
without the Bitwarden-held credentials silently skip it; the restic password
exists only in Bitwarden and on enrolled machines. The Arch root filesystem is
not currently encrypted.

## Invariants

- Machine names describe topology, not personal/work policy.
- Account configuration is shared; credentials activate accounts.
- Account configuration is native and inspectable; there is no renderer.
- Machine installers perform only system-level actions; application state is
  created by the owning Stow package or by the program itself.
- Physical hosts receive no development toolchain after migration.
- Host home directories are not mounted into development VMs.
- SSH private keys are forwarded to the VM through an agent, not copied.
- Machine SSH keys are generated on the machine and never leave it.
- Directly downloaded artifacts are versioned and checksummed.
- Valuable VM state must survive VM deletion independently.
- Repeated installation is safe.
