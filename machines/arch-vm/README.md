# arch-vm

This is the Linux development VM for x86-64 Linux or Intel Mac hosts. It uses
Lima's Arch template and refuses to run on ARM because the available Arch ARM
image is stale and incompatible with Apple's native virtualization backend.

Create and provision it with:

```sh
./machines/arch-vm/create-lima.sh
limactl shell dev
~/dotfiles/scripts/install-vm --account cultivate
```

Repeat `--account` to enable additional identities. The installer uses Pacman
for repository packages and yay for the declared AUR packages; this target no
longer maintains private PKGBUILDs.

The default VM has six CPUs, 8 GiB of memory, and a 100 GiB sparse disk. Override
those with `LIMA_CPUS`, `LIMA_MEMORY_GIB`, and `LIMA_DISK_GIB`; override the
instance name with `LIMA_INSTANCE`.
