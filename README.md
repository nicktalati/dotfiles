# NT's Dotfiles

This repository manages a physical Arch desktop and an isolated Linux work
environment that can run as a VM on macOS or Linux.

The physical Arch setup remains the existing combined personal/work machine.
The work guest is work-only: it owns terminal development and mail while a thin
physical host owns hardware, the graphical session, browsers, and the VM
runtime. Apple Silicon uses Fedora; x86-64 hosts can use Arch.

Stow symlinks user configuration and systemd user units. Rclone downloads
gocryptfs ciphertext, and gocryptfs mounts the selected secret vault at
`~/decrypt`.

## Stack

**OS:** Arch desktop; Fedora work VM on Apple Silicon

**WM:** Sway

**Shell:** Zsh

**Secrets:** Gocryptfs

**Cloud:** Rclone + S3

**Management:** Stow

**Email:** Goimapnotify + mbsync + neomutt

## Work VM

The work VM is currently the migration path for the MacBook. It is also usable
from a Linux host, but the existing physical Arch environment will remain the
default until the VM workflow has been exercised in practice.

Install Lima on the host, clone this repository, and run:

```bash
./machines/fedora-work-guest/create-lima.sh
```

Then enter the VM and provision it:

```bash
limactl shell work
~/dotfiles/install_work_guest.sh
```

The guest has no host-home mount. Repositories and mutable state live on its
own disk. See [`machines/work-guest/README.md`](machines/work-guest/README.md)
for the `vz` versus QEMU rollback tradeoff, work-secret enrollment, mail
behavior, and validation. The Fedora-specific image and package boundary is in
[`machines/fedora-work-guest`](machines/fedora-work-guest/README.md).

For a new Mac, [`machines/mac-work-host`](machines/mac-work-host/README.md)
contains the deliberately small Homebrew/Stow host bootstrap.

[`ARCHITECTURE.md`](ARCHITECTURE.md) records the target boundaries, invariants,
and why package-role composition is intentionally deferred.

## New Physical Arch Machines

Visit [https://archlinux.org/download](https://archlinux.org/download) and
retrieve the .iso and .iso.sig files.

Run

```bash
gpg --keyserver-options auto-key-retrieve --verify archlinux-version-x86_64.iso.sig archlinux-version-x86_64.iso
```

Verify the fingerprint at
[https://archlinux.org/people/developers](https://archlinux.org/people/developers).

Plug in an (unused!) usb drive and run

```bash
cp archlinux-version-x86_64.iso /dev/drive
```

And finish with `sync`.

Plug the drive into the new machine and boot into it (hold
f12/machine-specific-key during boot).

Identify the main disk and create EFI (512M) and Linux partitions with `fdisk`.

Create filesystems with `mkfs.ext4` (Linux) and `mkfs.fat -F 32` (EFI).

Mount the Linux partition to `/mnt` and the EFI partition to `/mnt/boot`.

Connect to internet with `iwctl` and run:

```bash
pacstrap -K /mnt base linux linux-firmware grub efibootmgr neovim sudo iwd git # install essentials
genfstab -U /mnt >> /mnt/etc/fstab # so partitions mount automatically
arch-chroot /mnt # chroot
passwd # create password
grub-install --efi-directory=/boot # install grub
grub-mkconfig -o /boot/grub/grub.cfg # make grub config
useradd -m -G wheel talati # create non-root user
passwd talati # create password
EDITOR=nvim visudo # uncomment # %wheel ALL=(ALL:ALL) ALL to grant wheel sudo privs
```

Reboot into the new install. Log in as talati, connect to internet and run

```bash
git clone https://github.com/nicktalati/dotfiles $HOME/dotfiles && cd $HOME/dotfiles
./install_arch.sh
```

Then update `~/.config/rclone/rclone.conf` and run:

```bash
rclone sync crypt:talati-crypt/crypt ~/crypt
```

And reboot.

Firefox profiles, extensions, and policies are managed by `firefox/setup.sh`
(called by `install_arch.sh`). After install, launch each profile and sign into
the corresponding Mozilla account to restore bookmarks, passwords, etc. via Sync.
