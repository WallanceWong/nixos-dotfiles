# NixOS + Hyprland Dotfiles

Rice setup for Wallance's ThinkPad E14 Gen 7, running NixOS with Hyprland,
Home Manager, and pywal-generated colors from a wallpaper.

## Structure

- `flake.nix`, `configuration.nix`, `home.nix` — NixOS system config (copy your working versions here)
- `hardware-configuration.nix` — hardware scan for this ThinkPad (machine-specific; replace it on other machines)
- `config/hypr/` — Hyprland, hyprpaper (wallpaper), hyprlock (lock screen), hypridle (idle), `screenshot.sh`
- `config/waybar/` — Waybar bar config + style (colors pulled from pywal)
- `config/rofi/` — Rofi launcher theme (colors pulled from pywal)
- `config/kitty/` — Kitty terminal config (colors pulled from pywal)
- `config/mako/` — Mako notifications (colors pulled from pywal)
- `wallpapers/wall.jpg` — the wallpaper pywal generates the palette from
- `docs/encrypted-reinstall.md` — reinstalling with full-disk encryption, then Secure Boot

## Keybindings

| Keys | Action |
| --- | --- |
| Super + Q | Terminal (kitty) |
| Super + R | App launcher (rofi) |
| Super + E | File manager (thunar) |
| Super + C | Close window |
| Super + F | Fullscreen |
| Super + V | Toggle floating |
| Super + L | Lock screen |
| Super + M | Log out (exit Hyprland) |
| Super + arrows | Move focus |
| Super + 1–5 / Super + Shift + 1–5 | Switch to / move window to workspace |
| 3-finger swipe | Switch workspace |
| PrtSc | Screenshot full screen |
| Shift + PrtSc, Super + Shift + S | Screenshot a region |
| Volume / mute / mic-mute / brightness keys | Work as labelled |

Screenshots are saved to `~/Pictures/Screenshots/` and copied to the clipboard.

## What runs at login

Getty autologins on tty1 and `.bash_profile` starts Hyprland, which then:

- generates pywal colors, starts hyprpaper, waybar, mako, the polkit agent and blueman-applet
- starts `hyprland-session.target`, which activates `graphical-session.target`
  (required by xdg-desktop-portal and hypridle's user service)
- runs hyprlock once — autologin skips the password, and unlocking also unlocks
  the gnome-keyring login keyring (its password must match the login password)

hypridle locks after 5 minutes idle and before sleep, and turns the screen off 30s later.

## How the color scheme works

On login, `wal -i ~/nixos-dotfiles/wallpapers/wall.jpg -n` generates a color
palette from the wallpaper and writes it to `~/.cache/wal/`. Waybar, Rofi,
Kitty, Mako, hyprlock and Hyprland's borders all read from those generated
files, so the whole desktop's accent colors match the wallpaper. GTK apps use
Adwaita-dark.

To change the wallpaper, replace `wallpapers/wall.jpg` (or update the path in
`config/hypr/hyprland.conf` and `config/hypr/hyprpaper.conf`), rebuild, and log out.

## Power and maintenance

- Battery charging stops at 80% (resumes below 75%). To charge to 100% until the next reboot:
  `echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold`
- Power profiles: `powerprofilesctl set power-saver|balanced|performance`
- Firmware updates: `fwupdmgr refresh && fwupdmgr get-updates`, then `fwupdmgr update`
- Old generations older than 14 days are garbage-collected weekly; the boot menu keeps 10.

## Applying changes

```bash
cd ~/nixos-dotfiles
git add .
git commit -m "describe the change"
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#hyprland-btw
```

If only Hyprland's config changed, `hyprctl reload` applies it. Anything started
with `exec-once` needs a log out (Super + M).

## Setup on a fresh machine

1. Clone this repo to `~/nixos-dotfiles`
2. Overwrite the tracked `hardware-configuration.nix` with the new machine's `/etc/nixos/hardware-configuration.nix` and `git add` it (it must stay tracked — flakes can't see untracked files)
3. `sudo nixos-rebuild switch --flake ~/nixos-dotfiles#hyprland-btw`

For a reinstall with disk encryption, follow `docs/encrypted-reinstall.md` instead.
