# Work guest

The work guest owns development tools, work Git identity, terminal mail, and
work secrets. The thin physical host owns hardware, the graphical session,
browsers, and Lima. The guest has no host-home mount.

The Mac target uses Fedora because Lima has a current Fedora-published ARM64
cloud image. The Arch target remains available on x86-64 hosts. Both apply the
same `core` + `email` + `work-guest` configuration and use the same installer.

Both creation scripts default to six CPUs, 8 GiB of memory, and a 100 GiB
sparse disk. Override those with `LIMA_CPUS`, `LIMA_MEMORY_GIB`, and
`LIMA_DISK_GIB`; override the instance name with `LIMA_INSTANCE`.

## Provision

After creating a VM with its machine-specific `create-lima.sh`, enter it and
run:

```sh
~/dotfiles/install_work_guest.sh
```

Re-running the command is supported. Use `--configure-only` to restow and
render configuration without installing packages, changing the login shell,
or enabling services.

The installer does not copy personal secrets and does not enable mail until a
work-only vault has been enrolled. It enables systemd user lingering so mail,
the SSH agent, and the encrypted mount remain active when no guest shell is
open.

Repository packages track the selected distribution rather than producing a
bit-for-bit image. Exceptional packages or upstream binaries are pinned and
checksummed in the corresponding machine definition.

## Rollback model

On Apple Silicon, Lima defaults to Apple's `vz` virtualization backend. That is
the efficient path, but Lima 2.2 does not implement snapshots for `vz`. The
initial rollback model is coarse-grained: keep code in Git and work secrets in
the separate encrypted remote, then delete and rebuild the guest when its
mutable state is no longer trustworthy.

Lima's QEMU backend supports experimental snapshots. To choose that tradeoff
before creating a VM, install QEMU on the host and set `LIMA_VM_TYPE=qemu` when
running the machine's `create-lima.sh`. Save and restore with:

```sh
limactl snapshot create work --tag known-good
limactl snapshot apply work --tag known-good
```

QEMU adds a large host dependency and is not the default. A snapshot is not a
backup: it lives with the Lima instance.

## Enroll work secrets

The expected work vault layout is:

```text
~/crypt/                         gocryptfs ciphertext
~/decrypt/secrets/oauth/cultivate.oauth2
~/decrypt/secrets/secrets.zsh
~/decrypt/secrets/ssh/config.d/work
~/decrypt/secrets/ssh/id_rsa_work_github
~/decrypt/secrets/ssh/id_rsa_work_github.pub
~/decrypt/secrets/ssh/id_rsa_work_gitlab
~/decrypt/secrets/ssh/id_rsa_work_gitlab.pub
```

On the current Arch machine, create a new vault from an explicit allowlist
rather than copying the mixed personal vault:

```sh
./machines/work-guest/create-work-vault.sh \
    ~/decrypt/secrets ~/crypt-work
```

The helper copies only Cultivate OAuth and work SSH material. It creates an
empty `secrets.zsh`; mount and review the new vault locally, then add only the
work API and shell secrets the guest actually needs. Keep the newly chosen
gocryptfs passphrase somewhere independent of the ciphertext.

`~/.config/gocryptfs/secrets` contains the gocryptfs passphrase. The bootstrap
enables `crypt-mount.service` only when both that passphrase file and
`~/crypt/gocryptfs.conf` exist. It enables mail only after the vault is mounted
and the Cultivate OAuth token is visible.

The S3/rclone location for the new work-only ciphertext has intentionally not
been guessed. Configure `~/.config/rclone/rclone.conf`, sync the selected work
vault to `~/crypt`, add the passphrase file, and rerun the installer. Do not
copy the existing all-purpose personal vault to the work Mac as a shortcut.

Automatic rclone backup remains disabled until the work remote and retention
policy are chosen.

## Validate

Run `dotfiles-doctor`. Missing enrolled secrets are warnings; incorrect machine
identity, missing tools, personal mail configuration, or a wrong notmuch path
are errors.

Desktop notifications and opening host applications from NeoMutt are not yet
bridged. Mail synchronization and sending do not depend on that bridge.

Run the repository smoke tests from the current Arch machine with:

```sh
./tests/run.sh
```
