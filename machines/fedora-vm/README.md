# fedora-vm

This is the default Linux development VM for both physical hosts. Its Lima
definition pins exact Fedora-published ARM64 and x86-64 cloud-image URLs and
SHA-256 digests. Lima uses Apple's `vz` backend on a compatible Mac and QEMU on
Linux.

Create and provision it with:

```sh
./machines/fedora-vm/create-lima.sh
limactl shell dev
~/dotfiles/machines/fedora-vm/install.sh
```

Fedora changes package names and exceptional installation mechanics; the
narrowly scoped application and native account packages under `stow/` are
shared with the physical Arch host. Account packages contain no secrets;
OAuth-token and SSH-agent contents determine which accounts are usable.

The host filesystem is not mounted. Repositories and mutable development state
live on the guest filesystem and cross the host boundary only through explicit
copying until a narrower exchange directory proves necessary.

The host's native SSH agent is forwarded into the guest, so the VM receives
signing and authentication operations but no SSH private keys. Mutable OAuth
tokens remain local to the VM under
`~/.local/share/mail/oauth`; the VM does not install or mount the Arch gocryptfs
vault.

The package manifest was checked against Fedora's ARM64 release metadata. Tools
not available from Fedora repositories are declared once in `tools.lock.json`.
`install-tools.sh` verifies their checksums, installs versioned payloads under
`~/.local/opt`, and creates stable commands under `~/.local/bin`. The AWS Session
Manager plugin is installed from AWS's RPM through DNF.

The default VM has six CPUs, 8 GiB of memory, and a 100 GiB sparse disk. Override
those with `LIMA_CPUS`, `LIMA_MEMORY_GIB`, and `LIMA_DISK_GIB`; override the
instance name with `LIMA_INSTANCE`.

Lima does not currently implement snapshots for the default Apple `vz` backend.
The rollback operation is deletion and rebuild. QEMU snapshots remain an
optional tradeoff when `LIMA_VM_TYPE=qemu` is set before VM creation.
