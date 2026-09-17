# NT's DFs

Machine configs for Arch/Mac. Each host runs the same Fedora VM.

## New Mac

Enable FileVault and install Homebrew.

Generate an SSH key and put it in the keychain:

```bash
ssh-keygen -t ed25519
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Add the public key at
[https://github.com/settings/keys](https://github.com/settings/keys) twice, once
as an authentication key and once as a signing key.

Clone and bootstrap:

```bash
git clone git@github.com:nicktalati/dotfiles.git ~/dotfiles && cd ~/dotfiles
./machines/mac-host/bootstrap.sh
```

This installs Ghostty, AeroSpace, Lima, Stow, and Bitwarden, and stows the
`macos` and `wallpaper` packages. Open a new terminal and check that
`ssh-add -L` prints the key. If it doesn't, run `ssh-add --apple-load-keychain`.

Create the VM and install into it:

```bash
./machines/fedora-vm/create-lima.sh
limactl shell dev
~/dotfiles/machines/fedora-vm/install.sh
```

From then on `dev` starts the VM if needed and attaches to its tmux session.

AeroSpace asks for Accessibility permission on first launch. Turn off "Displays
have separate Spaces" (Desktop & Dock → Mission Control) before plugging in a
second monitor, or macOS fights it over which window goes where.

## New Arch Machine

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
./machines/arch-host/install.sh
```

Set up backups (below) and reboot.

Firefox profiles, extensions, and policies are managed by
`machines/arch-host/firefox/setup.sh` (called by `install.sh`). After install,
launch each profile and sign into the corresponding Mozilla account to restore
bookmarks, passwords, etc. via Sync.

## Mail

Mail runs as systemd user services: mbsync on a timer, goimapnotify for push.
Every account's units are enabled but only run if a token exists at
`~/.local/share/mail/oauth/<account>`. To enroll an account:

```bash
mail-enroll cultivate
```

It asks for the client id and secret (in Bitwarden), prints a Google URL, and
starts syncing once you've clicked through it. Open the URL in a browser on the
host; Lima forwards the redirect into the VM.

Or copy the token file from another machine and start push by hand:

```bash
systemctl --user start goimapnotify@cultivate.service
```

## Backups

Restic snapshots `~/docs`, `~/photos`, `~/reading`, `~/dotfiles`, and the zsh
history to S3 daily. The timer does nothing until the credentials exist, so on a
new machine paste the three lines from the "restic backup" Bitwarden item:

```bash
mkdir -p ~/.config/restic
nvim ~/.config/restic/env
chmod 600 ~/.config/restic/env
```

```bash
export RESTIC_PASSWORD='...'
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
```

For the USB drive, `mount_drive` then `backup usb`.

To restore:

```bash
source ~/.config/backup/config; source ~/.config/restic/env; export RESTIC_REPOSITORY
restic snapshots
restic restore latest --target ~/restore
```

## Packages and Tests

`pkgsync diff` compares the machine's package list with what's actually
installed. `pkgsync sync` installs the list.

```bash
./tests/run.sh
```
