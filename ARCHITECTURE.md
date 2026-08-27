# Dotfiles architecture

## Concrete targets

The repository currently defines four environments:

- `install_arch.sh` + `pkglist.txt`: the existing physical Arch desktop,
  containing personal and work state
- `machines/mac-work-host`: a thin macOS host with native hardware, browser,
  terminal, encryption, and Lima
- `machines/fedora-work-guest`: the Apple Silicon work VM, based on Fedora's
  current official ARM cloud image
- `machines/arch-work-guest`: the equivalent x86-64 work VM for Linux or Intel
  Mac hosts

The Mac host and Fedora guest are one logical work machine, but they are
separate security and lifecycle domains. The host home is not mounted in the
guest.

## Repository layers

`machines/<target>` is the machine definition: package manifest, bootstrap,
generated configuration templates, target documentation, and exceptional local
package builds.

Top-level Stow directories are configuration layers:

- `core` and `email` are the existing physical-Arch layers
- `work-guest` overrides identity, mail accounts, headless shell behavior,
  clipboard behavior, and service dependencies for the VM
- `fedora-work-guest` supplies wrappers for the few pinned user tools not in
  Fedora's repository
- `mac-host` contains only the two host-side shell entry points

The guest installer explicitly excludes physical-only files from `core` and
mixed-account files from `email` before applying `work-guest`. These exclusions
are intentional compatibility seams: moving the existing files today would
break live Stow symlinks on the current Arch machine.

## Invariants

- No personal or former-work account is configured in either work guest.
- The Mac host receives no development toolchain or copied secret vault.
- The VM receives no automatic host-home mount.
- Machine identity is explicit in `~/.config/dotfiles/machine`; utilities do not
  infer it from the kernel or hostname.
- Work ciphertext uses a separate gocryptfs vault and remote prefix.
- Automatic ciphertext upload remains off until its destination and retention
  semantics are chosen.
- Valuable guest state must survive VM deletion independently: source through
  Git, ciphertext through its encrypted remote, and any other mutable data
  through an explicitly chosen backup.

## Why package roles are not composed

Package lists are concrete per-distribution manifests, not compositions of
guessed roles such as `common + dev + mail + desktop`. The shared boundary is
behavioral configuration in `work-guest`; distro package names and exceptional
installation mechanics remain in each machine definition.

After both work targets have been used, extract only intersections with real
independent meaning. A manifest renderer may then be justified; a hierarchy of
fragments is not a goal by itself.

## Migration order

1. Exercise the Fedora work guest on the Mac without changing the current Arch
   host.
2. Resolve host integration from observed needs: notifications, attachment
   opening, terminal choice, and backup policy.
3. Decide from measurements whether Apple `vz` plus rebuilds is sufficient or
   QEMU snapshots are worth the extra host dependency.
4. Replace `install_arch.sh` with a physical-machine definition only after the
   new path is trustworthy; preserve personal-plus-work as that target's policy.
