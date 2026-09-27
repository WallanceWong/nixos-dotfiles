# Reinstall with full-disk encryption (then Secure Boot)

The current install has an unencrypted root partition: anyone who takes the SSD
out can read it. Encryption (LUKS) can only be added by reinstalling. Because the
whole system is in this repo, the reinstall is mostly "wipe, encrypt, install from
the flake".

**Read this on your phone — the laptop will be wiped during step 4.**

Time: about 45 minutes, most of it downloading. You need a USB stick (4 GB+, it
gets erased) and Wi-Fi. Your files come back from the Google Drive backup.

---

## 0. Before you start: save your data

Everything on the laptop is erased. Your home folder is backed up to Google
Drive by restic (see `configuration.nix`), so:

1. Run a fresh backup and check it finished:
   ```bash
   sudo systemctl start restic-backups-gdrive
   restic-gdrive snapshots
   ```
   The newest snapshot's time should be a minute or two ago.
2. **Save the restic password somewhere off this laptop** (password manager, or
   on paper). It is in `~/.config/restic/password`. Without it the backup
   cannot be decrypted — nobody can recover it.
3. Firefox: turn on **Firefox Sync** (Settings → Sync) so bookmarks and passwords come back.
4. Make sure every change in `~/nixos-dotfiles` is committed **and pushed**:
   `git -C ~/nixos-dotfiles status` should say "up to date with 'origin/main'" and "nothing to commit".
5. Note your Wi-Fi password.

Not in the config, so reinstall by hand afterwards: Flatpak apps (Sober).

## 1. Make the installer USB

1. The installer is already downloaded and checksum-verified at `~/Downloads/nixos-minimal.iso`.
   (If it's missing: <https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso>.)
2. Plug in the USB stick and find its name:
   ```bash
   lsblk
   ```
   It's the ~4–64 GB disk that is **not** `nvme0n1` — usually `sda`.
3. Write the ISO (replace `sdX`; this erases the stick):
   ```bash
   sudo dd if=$HOME/Downloads/nixos-minimal.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

## 2. Boot the installer

1. Shut down, plug in the USB stick, power on and press **F12** repeatedly for the boot menu.
2. Pick the USB stick. (Secure Boot is off on this laptop, so the installer boots.)
3. At the prompt, become root:
   ```bash
   sudo -i
   ```

## 3. Connect to Wi-Fi

```bash
nmtui
```
Choose "Activate a connection", pick your network, enter the password. Then check:
```bash
ping -c 2 nixos.org
```

## 4. Wipe, partition and encrypt

> **This erases the whole SSD.** Double-check with `lsblk` that `nvme0n1` is the 476.9G disk.

```bash
lsblk
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 2GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root 2GiB 100%
```

Encrypt the big partition. Type `YES` in capitals when asked, then choose a
passphrase — **you will type it at every boot, and there is no way to recover
the data if you forget it**:
```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot
```

Format and mount:
```bash
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/nvme0n1p1 /mnt/boot
```

## 5. Install from this repo

Generate a hardware config for the new disk layout:
```bash
nixos-generate-config --root /mnt
grep -A1 'luks.devices' /mnt/etc/nixos/hardware-configuration.nix
```
The `grep` **must** print a `boot.initrd.luks.devices...` line. If it prints
nothing, stop — the system would not be able to unlock the disk at boot.

Get the dotfiles and swap in the new hardware config:
```bash
mkdir -p /mnt/home/Wallance
git clone https://github.com/WallanceWong/nixos-dotfiles /mnt/home/Wallance/nixos-dotfiles
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/Wallance/nixos-dotfiles/
cd /mnt/home/Wallance/nixos-dotfiles
git add hardware-configuration.nix
```

Install (this downloads a few GB). It asks for a new **root** password at the end:
```bash
nixos-install --flake /mnt/home/Wallance/nixos-dotfiles#hyprland-btw
```

Set your user password and give yourself your home folder back:
```bash
nixos-enter --root /mnt -c 'passwd Wallance'
nixos-enter --root /mnt -c 'chown -R Wallance:users /home/Wallance'
```

Remove the USB stick and reboot:
```bash
reboot
```

## 6. First boot

1. Type the **disk passphrase** at the "Please enter passphrase for disk" prompt.
2. You're logged in automatically and hyprlock appears — unlock with your **user password**.
   This also creates your keyring with the matching password.
3. Log in to GitHub and save the new hardware config:
   ```bash
   gh auth login
   gh auth setup-git
   cd ~/nixos-dotfiles
   git commit -am "Hardware config for encrypted install"
   git push
   ```
4. Restore your files from the backup. First reconnect Google Drive (a browser
   window opens — log in and allow access), then put the restic password back:
   ```bash
   rclone config create gdrive drive scope=drive.file
   mkdir -p ~/.config/restic
   read -rsp "restic password: " p; echo; printf %s "$p" > ~/.config/restic/password; unset p
   chmod 600 ~/.config/restic/password
   restic-gdrive snapshots
   restic-gdrive restore latest --target / \
     --include /home/Wallance/Pictures \
     --include /home/Wallance/Downloads \
     --include /home/Wallance/.claude \
     --include /home/Wallance/.claude.json \
     --include /home/Wallance/.config/mozilla \
     --include /home/Wallance/.local/share/keyrings \
     --include /home/Wallance/.var
   ```
   Only your data is restored, not the whole home folder: files like `~/.bashrc`
   and `~/.config/hypr` are links that Home Manager just recreated, and restoring
   the old ones would break them. If you've added other folders (e.g. `Documents`),
   add an `--include` line for each — `restic-gdrive ls latest /home/Wallance` lists
   what's in the backup. Log out (Super + M) afterwards so Firefox and the keyring
   pick up the restored files.
5. Reinstall Sober:
   ```bash
   flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
   flatpak install flathub org.vinegarhq.Sober
   ```
6. Check encryption is on — `lsblk` should show `cryptroot` of type `crypt`:
   ```bash
   lsblk -o NAME,TYPE,MOUNTPOINTS
   ```

---

## 7. Later, optional: Secure Boot with lanzaboote

Secure Boot stops someone from swapping in a tampered bootloader or kernel. It
only makes sense once the disk is encrypted. NixOS needs
[lanzaboote](https://github.com/nix-community/lanzaboote) for it. This changes
`flake.nix`, so ask Claude to make the config part of these changes with you.

1. Create your own signing keys:
   ```bash
   sudo nix run nixpkgs#sbctl -- create-keys
   ```
2. Config change (Claude can do this): add the lanzaboote flake input and module, set
   `boot.loader.systemd-boot.enable = lib.mkForce false;` and
   `boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; };`, then rebuild.
3. Check the boot files are signed:
   ```bash
   sudo nix run nixpkgs#sbctl -- verify
   ```
4. Reboot and press **F1** for BIOS setup. Under Security → Secure Boot, choose
   the option to reset to **Setup Mode** (may be called "Clear All Secure Boot Keys").
   Save and boot normally.
5. Enroll your keys, keeping Microsoft's (needed for firmware updates and some hardware):
   ```bash
   sudo nix run nixpkgs#sbctl -- enroll-keys --microsoft
   ```
6. Reboot, press **F1**, and turn **Secure Boot on**. After booting, check:
   ```bash
   bootctl status | grep -i 'secure boot'
   ```

If the laptop won't boot after step 6, press F1, turn Secure Boot off again, and
ask for help — nothing is lost.
