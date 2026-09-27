# Reinstall with full-disk encryption (then Secure Boot)

The current install has an unencrypted root partition: anyone who takes the SSD
out can read it. Encryption (LUKS) can only be added by reinstalling. Because the
whole system is in this repo, the reinstall is mostly "wipe, encrypt, install from
the flake".

**Read this on your phone — the laptop will be wiped during step 4.**

Time: about 45 minutes, most of it downloading. You need a USB stick (4 GB+, it
gets erased) and Wi-Fi. Your files come back from the backup you upload to Google Drive in step 0.

---

## 0. Before you start: save your data

Everything on the laptop is erased. Your home folder is backed up with restic
into an encrypted folder, `~/restic-thinkpad`, which you then upload to Google
Drive in the browser. (Automatic Drive backups need a Google Cloud client ID,
which this account can't create, so the upload is by hand.)

1. Refresh the backup so it includes everything up to now:
   ```bash
   restic-home backup $HOME \
     --exclude $HOME/.cache --exclude $HOME/restic-thinkpad \
     --exclude $HOME/.local/share/Trash --exclude "$HOME/.var/app/*/cache" \
     --exclude "$HOME/Downloads/*.iso"
   restic-home snapshots
   ```
   The newest snapshot's time should be a minute ago.
2. Pack it into one file and upload that to Google Drive (one file is much easier
   to upload and download than a folder):
   ```bash
   tar -cf ~/restic-thinkpad.tar -C ~ restic-thinkpad
   ```
   Open <https://drive.google.com>, click **New → File upload**, pick
   `restic-thinkpad.tar` from your home folder, and wait until Drive says
   "1 upload complete".
3. **Save the restic password somewhere off this laptop** (password manager, or
   on paper). It is in `~/.config/restic/password`. Without it the backup
   cannot be decrypted — nobody can recover it.
4. Firefox: turn on **Firefox Sync** (Settings → Sync) so bookmarks and passwords come back.
5. Make sure every change in `~/nixos-dotfiles` is committed **and pushed**:
   `git -C ~/nixos-dotfiles status` should say "up to date with 'origin/main'" and "nothing to commit".
6. Note your Wi-Fi password.

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

Set your user password (choose a **new** one — the old one was written in a chat
log) and give yourself your home folder back:
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
4. Restore your files from the backup:
   - Open Firefox with a **throwaway profile** (so your real profile isn't created
     before it's restored), log in to Google, and download `restic-thinkpad.tar`
     into `~/Downloads`:
     ```bash
     firefox --no-remote --profile "$(mktemp -d)" https://drive.google.com
     ```
     Close that Firefox window when the download is done, then unpack it:
     ```bash
     tar -xf ~/Downloads/restic-thinkpad.tar -C ~
     ```
   - Put the restic password back, then restore:
   ```bash
   mkdir -p ~/.config/restic
   read -rsp "restic password: " p; echo; printf %s "$p" > ~/.config/restic/password; unset p
   chmod 600 ~/.config/restic/password
   restic-home snapshots
   restic-home restore latest --target / \
     --include /home/Wallance/Pictures \
     --include /home/Wallance/Downloads \
     --include /home/Wallance/.claude \
     --include /home/Wallance/.claude.json \
     --include /home/Wallance/.config/mozilla \
     --include /home/Wallance/.var \
     --exclude /home/Wallance/.config/mozilla/firefox/btea7p9y.default/chrome \
     --exclude /home/Wallance/.config/mozilla/firefox/btea7p9y.default/user.js
   ```
   **Don't open Firefox normally before this step** — it would create a fresh profile.
   The two `--exclude` lines skip the Firefox theme links, which Home Manager
   has already recreated for the new system.
   The keyring is deliberately **not** restored: the old one is locked with your
   old password, and the new system already made one with your new password.

   Only your data is restored, not the whole home folder: files like `~/.bashrc`
   and `~/.config/hypr` are links that Home Manager just recreated, and restoring
   the old ones would break them. If you've added other folders (e.g. `Documents`),
   add an `--include` line for each — `restic-home ls latest /home/Wallance` lists
   what's in the backup. Log out (Super + M) afterwards so Firefox
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
