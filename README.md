# NT's Dotfiles

This more or less contains my entire Arch Linux config.

`pkglist.txt` contains all packages to be installed. Stow symlinks all configs and systemd units. Rclone downloads encrypted personal files from S3, and gocryptfs decrypts them to `~/decrypt`.

## Stack

**OS:** Arch

**WM:** Sway

**Shell:** Zsh

**Secrets:** Gocryptfs

**Cloud:** Rclone + S3

**Management:** Stow

## New Machines

Visit [https://archlinux.org/download](https://archlinux.org/download) and retrieve the .iso and .iso.sig files.

Run

```bash
gpg --keyserver-options auto-key-retrieve --verify archlinux-version-x86_64.iso.sig archlinux-version-x86_64.iso
```

Verify the fingerprint at [https://archlinux.org/people/developers](https://archlinux.org/people/developers).

Plug in an (unused!) usb drive and run

```bash
cp archlinux-version-x86_64.iso /dev/drive
```

And finish with `sync`.

Plug the drive into the new machine and boot into it (hold f12/machine-specific-key during boot).

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

Firefox is finicky. After creating "personal" and "work" profiles, launching each and signing in, copy `firefox/userContent.css` to `~/.mozilla/firefox/<profile>/chrome/userContent.css`.
