# NixOS + Hyprland Dotfiles

Rice setup for Wallance's ThinkPad E14 Gen 7, running NixOS with Hyprland,
Home Manager, and pywal-generated colors from a wallpaper.

## Structure

- `flake.nix`, `configuration.nix`, `home.nix` — NixOS system config (copy your working versions here)
- `config/hypr/` — Hyprland config + hyprpaper wallpaper config
- `config/waybar/` — Waybar bar config + style (colors pulled from pywal)
- `config/rofi/` — Rofi launcher theme (colors pulled from pywal)
- `config/kitty/` — Kitty terminal config (colors pulled from pywal)
- `wallpapers/wall.jpg` — the wallpaper pywal generates the palette from

## How the color scheme works

On login, `wal -i ~/nixos-dotfiles/wallpapers/wall.jpg -n` generates a color
palette from the wallpaper and writes it to `~/.cache/wal/`. Waybar, Rofi,
Kitty, and Hyprland's borders all read from those generated files, so the
whole desktop's accent colors match the wallpaper.

To change the wallpaper and re-theme everything:

```bash
wal -i ~/nixos-dotfiles/wallpapers/<new-image> -n
hyprctl reload
```

## Applying changes

```bash
cd ~/nixos-dotfiles
git add .
git commit -m "describe the change"
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#hyprland-btw
```

## Setup on a fresh machine

1. Clone this repo to `~/nixos-dotfiles`
2. Copy `hardware-configuration.nix` from `/etc/nixos/` (machine-specific, not tracked here)
3. `sudo nixos-rebuild switch --flake ~/nixos-dotfiles#hyprland-btw`
