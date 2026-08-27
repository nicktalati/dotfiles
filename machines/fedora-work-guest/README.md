# Fedora work guest

This is the default work VM for Apple Silicon Macs. Fedora 44 provides a
current, Fedora-published aarch64 cloud image that boots with Lima's native
Apple `vz` backend. The repo pins the exact image URL and SHA-256 digest in
`lima.yaml`.

The terminal environment is intentionally the same `core` + `email` +
`work-guest` Stow composition used by the Arch work target. Fedora changes the
base image and package names, not the Git identity, shell, editor, tmux, mail,
or secret layout.

## Create and provision

From the Mac host:

```sh
./machines/fedora-work-guest/create-lima.sh
limactl shell work
~/dotfiles/install_work_guest.sh
```

The repository package manifest was checked against Fedora 44's aarch64
release metadata. `install-tools.sh` separately installs pinned, checksummed
upstream releases for dbmate, fnm, Lua Language Server, goimapnotify, and AWS's
Session Manager plugin. User tools live under `~/.local/opt`; the AWS plugin is
installed from AWS's official RPM through DNF.

Work-vault enrollment, validation, the `vz`/QEMU snapshot tradeoff, and the
rebuild model are documented in
[`../work-guest/README.md`](../work-guest/README.md).
