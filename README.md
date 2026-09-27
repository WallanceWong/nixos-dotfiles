# NixOS + Hyprland Dotfiles

Rice setup for Wallance's ThinkPad E14 Gen 7, running NixOS with Hyprland,
Home Manager, and **whisper** — a hand-picked palette taken from the wallpaper
(a starry night over the city lights: night-sky navy, moonlight text,
streetlamp cream and city-glow teal).

## Structure

- `flake.nix`, `configuration.nix`, `home.nix` — NixOS system config; `home.nix` also holds the GTK tint, cursor, icons, starship, fastfetch, btop and eza
- `hardware-configuration.nix` — hardware scan for this ThinkPad (machine-specific; replace it on other machines)
- `config/hypr/colors.conf` — the whisper palette, sourced by Hyprland and hyprlock
- `config/hypr/` — Hyprland, hyprpaper (wallpaper), hyprlock (lock screen), hypridle (idle), `screenshot.sh`, `osd.sh` (volume/brightness popups)
- `config/waybar/` — floating bar; workspaces are stars
- `config/rofi/` — launcher (also used for the window switcher and clipboard history)
- `config/kitty/` — terminal; `whisper.conf` is the 16-colour palette
- `config/mako/` — notifications and the OSD popup style
- `config/wlogout/` — power menu, with lamp-coloured icons
- `wallpapers/wall.jpg` — the wallpaper; `wallpapers/fetch.png` is the crop fastfetch shows
- `docs/encrypted-reinstall.md` — reinstalling with full-disk encryption, then Secure Boot

## Keybindings

| Keys | Action |
| --- | --- |
| Super + Q | Terminal (kitty) |
| Super + Space, Super + R | App launcher (rofi) |
| Super + W | Switch to an open window |
| Super + E | File manager (thunar) |
| Super + C | Close window |
| Super + F | Fullscreen |
| Super + V | Toggle floating |
| Super + J | Flip the split direction |
| Super + Shift + V | Clipboard history |
| Super + N / Super + Shift + N | Bring back the last notification / dismiss all |
| Super + L | Lock screen |
| Super + Escape | Power menu (lock, log out, sleep, restart, shut down) |
| Super + M | Log out (exit Hyprland) |
| Super + arrows / Super + Shift + arrows | Move focus / move window |
| Super + 1–5 / Super + Shift + 1–5 | Switch to / move window to workspace |
| Super + Tab, Super + scroll | Previous workspace, scroll through workspaces |
| Super + ` (backtick) | Drop-down scratch terminal |
| 3-finger swipe | Switch workspace |
| PrtSc | Screenshot full screen |
| Shift + PrtSc, Super + Shift + S | Screenshot a region |
| Volume / mute / mic-mute / brightness keys | Work as labelled, with a popup |
| Play/pause, next, previous keys | Control the current media player |

Screenshots are saved to `~/Pictures/Screenshots/` and copied to the clipboard.
In the bar: click the moon for the launcher, hover the clock for a calendar
(click it for the full date), volume for the mixer, Wi-Fi for
`nmtui`, Bluetooth for the Bluetooth manager, and the power icon for the power menu.

## What runs at login

Getty autologins on tty1 and `.bash_profile` starts Hyprland, which then:

- starts hyprpaper, waybar, mako, the clipboard watcher and the polkit agent
- starts `hyprland-session.target`, which activates `graphical-session.target`
  (required by xdg-desktop-portal and hypridle's user service)
- runs hyprlock once — autologin skips the password, and unlocking also unlocks
  the gnome-keyring login keyring (its password must match the login password)

hypridle dims the screen after 4½ minutes idle, locks at 5 minutes (and before sleep), and turns the screen off 30s later.

## How the color scheme works

The palette was sampled from `wallpapers/wall.jpg` and tuned by hand (pywal's
automatic colours came out muddy for this image). It lives in each program's
own format, so changing a colour means editing these files:

| Colour | Hex | Used for |
| --- | --- | --- |
| night | `#071a28` | backgrounds |
| sky / horizon | `#0c2a3d` `#13384e` `#1d4a60` | surfaces, selections |
| city glow | `#3f6e74` | muted accents, inactive items |
| moonlight | `#e3e8e1` | text |
| streetlamp | `#f0e3a8` | main accent: borders, clock, highlights |
| city lights | `#7fc3c6` | second accent |
| denim / shirt / skirt / bushes | `#6d9fd1` `#e0786c` `#e3b35c` `#8fbf9a` | small details, terminal colours |

Files: `config/hypr/colors.conf`, `config/waybar/style.css`, `config/rofi/config.rasi`,
`config/kitty/whisper.conf`, `config/mako/config`, `config/wlogout/style.css`, the GTK
CSS and btop theme in `home.nix`, and `console.colors` in `configuration.nix`.

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
