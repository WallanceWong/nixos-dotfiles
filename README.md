# NixOS + Hyprland Dotfiles — whisper

Rice for Wallance's ThinkPad E14 Gen 7: NixOS, Hyprland and Home Manager, with
**whisper-shell**, a desktop built in [Quickshell](https://quickshell.org) around
the wallpaper — a starry night over the city lights from *Whisper of the Heart*.
The painting is alive: its own stars twinkle, the city shimmers, the streetlamps
breathe, fireflies drift and a shooting star crosses now and then.

It is also two layers deep: the sky drifts behind the foreground as you change
workspace, carries **tonight's real moon** (its true phase), and is tinted by the
**real time of day** over Kuching (worked out offline from the sun's position).
The city lights and their glow on the haze follow whatever music is playing.
Each of these can be switched off in **whisper settings** (Super + ,).

## Structure

- `flake.nix`, `configuration.nix`, `home.nix` — the NixOS system and the user config
- `hardware-configuration.nix` — hardware scan for this ThinkPad (machine-specific; replace it on other machines)
- `theme/palette.json` — **the one palette**. Every colour on the desktop comes from here
- `theme/whisper.nix` — generates each program's colours from the palette (Hyprland, hyprlock, kitty, GTK, Qt, Firefox, btop, starship, nano, satty, fcitx5, the TTY) and starts whisper-shell
- `theme/scene.json` — where the stars, city lights, lamps and windows are in the painting (for the living wallpaper)
- `wallpapers/layers/` — the painting split into `sky.jpg` and `foreground.png` (for the depth effect); stacked, they are the original
- `config/quickshell/` — **whisper-shell**: `shell.qml`, `modules/` (wallpaper, bar, panels…), `services/` (audio, notifications…), `components/`, `assets/` (glows, sounds)
- `config/hypr/` — Hyprland, hypridle (idle), `lock.sh` (locks with whisper-shell, hyprlock as the fallback), hyprlock, hyprpaper, `screenshot.sh`, `annotate.sh`, `picker.sh`
- `config/kitty/` — terminal settings (colours are generated)
- `config/firefox/` — `userChrome.css` / `userContent.css` + `user.js`, linked into the Firefox profile
- `config/vscode/` — starter VS Code settings; copied only if VS Code has none yet
- `config/waybar/`, `config/mako/`, `config/rofi/`, `config/wlogout/` — the previous setup, kept as a fallback (Super + Ctrl + B)
- `wallpapers/wall.jpg` — the wallpaper
- `docs/encrypted-reinstall.md` — reinstalling with full-disk encryption, then Secure Boot

## Keybindings

| Keys | Action |
| --- | --- |
| Super + Q | Terminal (kitty) |
| Super + Space, Super + R | Launcher — apps; type `=` for a calculator |
| Super + W | Switch to an open window |
| Super + Shift + V | Clipboard history |
| Super + . | Emoji picker (copies the emoji) |
| Super + Tab, 3-finger swipe up | Overview of all workspaces with live window previews (drag windows between them) |
| Super + N | Control centre (Wi-Fi, Bluetooth, volume, brightness, toggles, notifications) |
| Super + Shift + N | Do not disturb on/off |
| Super + D | Dashboard (calendar, music, system) |
| Super + G | Game mode on/off |
| Super + Escape | Power menu (lock, sleep, log out, restart, shut down) |
| Super + L | Lock screen |
| Super + / | Every shortcut, searchable (read live from Hyprland) |
| Super + , | whisper settings: depth, music, moon, sky clock, ambience, corners, automations |
| Super + E | File manager (thunar) |
| Super + C | Close window |
| Super + F | Fullscreen |
| Super + V | Toggle floating |
| Super + J | Flip the split direction |
| Super + ` (backtick) | Drop-down scratch terminal |
| Super + M | Log out (exit Hyprland) |
| Super + arrows / Super + Shift + arrows | Move focus / move window |
| Super + 1–5 / Super + Shift + 1–5 | Switch to / move window to workspace |
| Super + Shift + Tab, Super + scroll | Previous workspace, scroll through workspaces |
| 3-finger swipe left/right | Switch workspace |
| PrtSc | Screenshot full screen |
| Shift + PrtSc, Super + Shift + S | Screenshot a region |
| Super + Shift + A | Screenshot a region and draw on it (Enter copies, Ctrl+S saves) |
| Super + Shift + R / Super + Alt + R | Record a region / the whole screen (same key stops) |
| Super + Shift + C | Colour picker (copies the hex code) |
| Ctrl + Space | Switch typing between English and Chinese (pinyin) |
| Volume / mute / mic-mute / brightness keys | Work as labelled, with a popup |
| Play/pause, next, previous keys | Control the current media player |
| Super + Ctrl + R | Restart whisper-shell |
| Super + Ctrl + B | Rescue: stop whisper-shell and start the old waybar setup |

Screenshots go to `~/Pictures/Screenshots/`, recordings to `~/Videos/Recordings/`.
In the bar: the moon opens the launcher, the stars are your workspaces (the lit
one is where you are), the clock opens the dashboard, and the status pill
(中/EN, Wi-Fi, Bluetooth, volume, battery) opens the control centre. A small lamp
dot on it means unread notifications.

## Typing Chinese

fcitx5 with pinyin starts at login. Press **Ctrl + Space** to switch between
English and Chinese — the bar shows **EN** or **中**. Type pinyin, pick with the
number keys or Space; `-`/`=` page through candidates.

## Game mode

Roblox (Sober) always runs without blur, animations or shadows, and may tear
for lower input lag. Notifications don't pop up over fullscreen games (they wait
in the control centre). **Super + G** turns on full game mode: every effect,
gap and animation off and Do Not Disturb on; press it again to restore.
With **auto game mode** (on by default), a game that asks Feral GameMode for
help — Sober does — switches game mode on by itself, and off when it quits.

## Lock screen

whisper-shell draws the lock screen itself: the same living night, a lamp-lit
clock, tonight's moon, now playing, battery and how many notifications came in.
Just type — each letter is a firefly — and press Enter (Esc clears). It checks
the password with PAM (the `hyprlock` service, so the keyring unlocks too). If
the shell crashes while locked, systemd restarts it and it locks again; if the
shell can't be reached at all, `lock.sh` falls back to hyprlock.

## Automations

- **Battery saver** — below 20% on battery the night goes still (no animation
  or blur, power-saver profile) until you plug in.
- **Boards** — plug in an Arduino or CH340 board and a note shows its port, with
  a button that opens PictoBlox.
- **Night ambience** (off by default) — crickets and the far-off city, very
  quietly, only while the desktop is empty (or locked) and nothing else plays.

## What runs at login

Getty autologins on tty1 and `.bash_profile` starts Hyprland, which then:

- starts the clipboard watcher and fcitx5
- starts `hyprland-session.target`, which activates `graphical-session.target` —
  that starts **whisper-shell** (systemd user service), xdg-desktop-portal and hypridle
- locks once (`lock.sh login`) — autologin skips the password, and unlocking also
  unlocks the gnome-keyring login keyring (its password must match the login password)

hypridle dims the screen after 4½ minutes idle, locks at 5 minutes (and before
sleep), and turns the screen off 30s later. whisper-shell is also the
notification daemon and the polkit (admin password) agent.

## Changing colours and the shell

- Colours: edit `theme/palette.json`. whisper-shell picks it up immediately;
  everything else on the next rebuild.
- The shell: `~/.config/quickshell` links straight to `config/quickshell/`, and
  Quickshell reloads itself when a file is saved — no rebuild needed. Its log:
  `journalctl --user -u whisper-shell -f`.
- Soft UI sounds can be turned off in the control centre (Sounds tile).

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
