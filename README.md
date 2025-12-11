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

After installing Arch and logging in as the new user, run:

```bash
sudo pacman -S git
git clone https://github.com/nicktalati/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install_arch.sh
```

Then update the following secrets files:

- `~/.config/zsh/secrets.zsh`
- `~/.config/gocryptfs/secrets`
- `~/.config/rclone/rclone.conf`

Run:
```bash
rclone sync crypt:talati-crypt/crypt ~/crypt
```

And reboot.

Firefox is finicky. After launching each profile once and signing in, copy `firefox/userContent.css` to `~/.mozilla/firefox/<profile>/chrome/userContent.css`.
