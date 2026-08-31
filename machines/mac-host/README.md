# mac-host

This is intentionally a thin macOS target. It owns FileVault, Safari and other
native graphical applications, Ghostty, AeroSpace, and Lima. Development tools
and terminal mail belong in a Linux VM.

## Bootstrap

1. Update macOS and enable FileVault.
2. Install Homebrew using its official installer. Skip its suggested
   `~/.zprofile` edit: the Stowed `.zprofile` runs `brew shellenv`, and the
   bootstrap's Stow step refuses to replace a real file it does not own.
3. Generate this machine's SSH key with a passphrase and load it into macOS's
   native agent. Private keys are machine state: generated here, never copied
   anywhere.

   ```sh
   ssh-keygen -t ed25519
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ```

4. Register `~/.ssh/id_ed25519.pub` at <https://github.com/settings/keys>
   twice: as an authentication key and as a signing key. Commits sign with the
   machine key; repository location selects only the account e-mail.

5. Clone this repository to `~/dotfiles` using the agent:

   ```sh
   git clone git@github.com:nicktalati/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

6. Run:

   ```sh
   ./machines/mac-host/bootstrap.sh
   ```

The Brewfile installs Bitwarden for web passwords, Ghostty and the 0xProto Nerd
Font it renders the guest with, AeroSpace, Lima, and Stow. The bootstrap then Stows the
`stow/macos` package, which owns `~/.zprofile`, `~/.ssh/config`,
`~/.config/ghostty/config`, `~/.config/aerospace/aerospace.toml`, and
`~/.local/bin/dev`, plus `stow/wallpaper`,
which owns the image Ghostty draws behind the terminal and Sway draws behind
the Arch desktop. It applies no `defaults` settings, does not configure
Safari, and installs no native development toolchain.

The SSH configuration uses `AddKeysToAgent` and Apple's `UseKeychain` extension,
and `.zprofile` loads the Keychain-held identity at login: Keychain remembering
a passphrase does not by itself put a key in the agent, and an empty agent is
what a failed guest clone and an unsignable commit both look like. Bitwarden has
no SSH role. Open a new terminal and verify the native agent before creating the
VM:

```sh
ssh-add -L
```

Lima forwards this agent into the guest; SSH private keys do not need to be
copied into the VM.

Check for missing declared packages with
`brew bundle check --file ~/dotfiles/machines/mac-host/Brewfile`.

## Tiling

AeroSpace mirrors the Sway layout with `alt` (option) as the modifier:
`alt-digits` switch workspaces, `alt-shift-digits` move the focused window,
`alt-h`/`alt-l` move focus, `alt-q` closes the window (quitting the app with
its last window, as on Linux), `alt-enter` opens Ghostty, `alt-b` opens
Safari.
The modifier is `alt` and not `cmd`, which Safari needs, or `ctrl`, which the
terminal needs. tmux keeps its `alt` bindings unchanged; inside Ghostty, `cmd`
plays that role — Ghostty translates `cmd`-combos into the ESC-prefixed
sequences `alt` would send, since AeroSpace owns the real `alt` keys and `cmd`
sits where `alt` does on a PC keyboard. Two things are macOS's to grant, not
this repository's:

1. AeroSpace asks for Accessibility permission on first launch and manages
   nothing until it is granted (System Settings, Privacy & Security).
2. Turn off "Displays have separate Spaces" (System Settings, Desktop & Dock,
   Mission Control) before using more than one display, then log out and back
   in. macOS otherwise fights AeroSpace over which windows belong where.

## Development VM

Create and provision the default Apple Silicon VM:

```sh
./machines/fedora-vm/create-lima.sh
limactl shell dev
~/dotfiles/machines/fedora-vm/install.sh
```

After provisioning, open a new macOS shell and run `dev`. The launcher starts
the VM when necessary and attaches to its persistent `dev` tmux session.

The initial target intentionally does not manage Safari settings, notifications,
attachment opening, Slack, macOS defaults, or backup settings.

## Host footprint and removal

The managed footprint is:

- Homebrew casks `bitwarden`, `ghostty`, `font-0xproto-nerd-font`, and
  `aerospace`, and formulas `lima` and `stow`
- Homebrew tap `nikitabobko/tap`
- `~/.zprofile`, `~/.ssh/config`, `~/.config/ghostty/config`,
  `~/.config/aerospace/aerospace.toml`, `~/.local/bin/dev`, and
  `~/.local/share/wallpapers` Stow links
- this machine's SSH key under `~/.ssh`, generated locally and not owned by
  this repository
- Lima instance data under its normal application-support directory

Remove the configuration links with:

```sh
stow --delete --no-folding --dir ~/dotfiles/stow --target "$HOME" macos wallpaper
```

`limactl delete dev` deletes the VM and all unpushed VM state. Homebrew packages
are not uninstalled automatically because the bootstrap cannot safely infer
whether they predated this repository.
