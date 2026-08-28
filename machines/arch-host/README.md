# arch-host

This is the physical Arch Linux desktop target. It combines the shared Linux
Stow packages with `stow/arch-backup`, `stow/arch-desktop`,
`stow/arch-vault`, and all current native account packages, then manages the
target's packages, Firefox profiles, two `/etc` files, and system services.

Run the installer only after inspecting it:

```sh
./machines/arch-host/install.sh
```

Unlike `machines/fedora-vm/install.sh`, this is intentionally a complete
physical-machine installer and is not isolated from the host. The existing
gocryptfs and rclone behavior is preserved pending a separate secret and backup
redesign.
