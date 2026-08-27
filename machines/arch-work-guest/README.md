# Arch work guest

This is the work VM for x86-64 Linux or Intel Mac hosts. It uses Lima's current
Arch x86-64 cloud image and the concrete package manifest in this directory.

Do not use this target on Apple Silicon. Lima 2.2's ARM Arch template points to
an unmaintained March 2022 third-party image that does not boot with the native
`vz` backend; this remains tracked in
[Lima issue #2866](https://github.com/lima-vm/lima/issues/2866). The create
script refuses non-x86-64 hosts rather than silently falling back to it.

Create and provision with:

```sh
./machines/arch-work-guest/create-lima.sh
limactl shell work
~/dotfiles/install_work_guest.sh
```

Shared lifecycle, rollback, secret, mail, and validation behavior is documented
in [`../work-guest/README.md`](../work-guest/README.md).
