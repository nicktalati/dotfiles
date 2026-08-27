# macOS work host

This is intentionally a thin host. It owns FileVault, native applications, the
browser, a terminal, and Lima. Development tools and terminal mail belong in
the Fedora work guest.

## Initial setup

1. Update macOS and enable FileVault.
2. Install Homebrew using its official installer. Make its `brew` command
   available in the current shell, but let this repository own `~/.zprofile`
   rather than manually persisting Homebrew's suggested shell line.
3. Clone this repository to `~/dotfiles`.
4. Run:

   ```sh
   ./machines/mac-work-host/bootstrap.sh
   ```

The bootstrap uses the checked-in Brewfile to install Lima, Stow, and Firefox.
It then Stows a minimal `.zprofile` and the `work` launcher. It applies no
`defaults` settings and installs no native development stack.

Use `./machines/mac-work-host/bootstrap.sh --check` for a read-only package
check.

## Work guest

Create the guest:

```sh
./machines/fedora-work-guest/create-lima.sh
```

Provision it as described in
[`../fedora-work-guest/README.md`](../fedora-work-guest/README.md). Once provisioned,
open a new host shell and run `work`; it starts the VM if necessary and attaches
to the persistent `work` tmux session.

The initial host target intentionally does not manage Firefox profiles,
notifications, attachment opening, Slack, macOS defaults, or backup settings.
Those should be added only after the core guest workflow is working.

## What changes on the host

The managed footprint is deliberately inspectable:

- Homebrew formulas `lima` and `stow`, plus the Firefox cask
- two Stow symlinks: `~/.zprofile` and `~/.local/bin/work`
- Lima's instance data under its normal application-support directory

To remove the configuration links, run:

```sh
stow --delete --no-folding --dir ~/dotfiles --target "$HOME" mac-host
```

`limactl delete work` deletes the VM and all unpushed guest state. Homebrew
packages are intentionally not uninstalled automatically because the bootstrap
cannot safely infer whether they predated this repository.
