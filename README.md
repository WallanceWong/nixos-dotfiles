# NixOS + Hyprland Dotfiles — eva

Rice for Wallance's ThinkPad E14 Gen 7: NixOS, Hyprland and Home Manager, with
**nerv-shell**, a desktop built in [Quickshell](https://quickshell.org) in the
look of *Neon Genesis Evangelion*: HUD plates with 45° cut corners, condensed
capitals, seven-segment readouts, heavy Mincho title cards.

There are **two setups**, switched live with **Super + Shift + U** (or the
setup buttons in the control centre and settings, or `eva-switch` in a terminal):

| | **UNIT-01 / SHINJI** (calm) | **NERV HQ / MAGI** (full drama) |
| --- | --- | --- |
| Colours | indigo night, Unit-01 lime and purple, ember orange | command-room black, NERV orange, emergency red, amber |
| Wallpaper | the painting of Shinji at the railing as Unit-01 rises from the sea — embers drift up, Unit-01's eye breathes (and flares with your music), sea haze rolls past, a vertical Mincho date | the MAGI command display, all live: CASPER/BALTHASAR/MELCHIOR vote on your machine's state, SYNC RATIO (CPU) with its trace, LCL density (memory), core temperature, the power panel with the internal-power countdown, angel radar, AT-field hex grid, a signal trace that follows music, a status ticker |
| Lock screen | Unit-01 in the dark, eye lit green, title card (逃げちゃダメだ), pilot sync code | the MAGI vote: three 承認 open the doors, 否決 turns the room red |
| Sounds | quiet clicks, tape-deck clunks, optional cicadas | square-wave beeps, buzzer, klaxon for critical alerts |
| Motion | slow tide | fast and mechanical |

The **boot login is always Eva-01**, whichever setup is active: the Plymouth
splash (Unit-01's eye coming on), the TTY colours and the first lock after
autologin.

## Structure

- `flake.nix`, `configuration.nix`, `home.nix` — the NixOS system and the user config
- `hardware-configuration.nix` — hardware scan for this ThinkPad (machine-specific; replace it on other machines)
- `theme/setups/unit01.json`, `theme/setups/magi.json` — **the two setups**: colours, fonts, shape, motion, drama. Every colour on the desktop comes from these
- `theme/eva.nix` — generates each program's config for both setups into `~/.config/eva/<id>/` (Hyprland, kitty, GTK, Qt, Firefox, VS Code, btop, starship, fastfetch, nano, satty, fcitx5), points the apps at `~/.config/eva/current`, installs `eva-switch` and starts nerv-shell
- `theme/plymouth/` — the boot splash; `theme/nerv-crest.txt` — the crest for fastfetch
- `wallpapers/unit01/wall.jpg` — the UNIT-01 wallpaper (the NERV HQ one is drawn live by the shell)
- `config/quickshell/` — **nerv-shell**: `shell.qml`, `modules/` (wallpaper, bar, panels…), `services/` (theme, setups, stats, audio, notifications…), `components/` (HUD frames, seven-segment digits, the two scenes, the two lock screens), `assets/` (NERV crest, glows, sounds per setup)
- `config/hypr/` — Hyprland (`hyprland.lua`; the setup's look comes from `~/.config/eva/current/hypr.lua`), hypridle (idle), `lock.sh` (locks with nerv-shell, hyprlock as the fallback), hyprlock, `screenshot.sh`, `annotate.sh`, `picker.sh`
- `config/kitty/` — terminal settings (colours are generated)
- `config/firefox/` — the Firefox stylesheets and `user.js`; `theme/firefox/` builds them with each setup's colours and new tab
- `config/vscode/` — starter VS Code settings; copied only if VS Code has none yet
- `config/waybar/`, `config/mako/`, `config/rofi/`, `config/wlogout/` — a rescue desktop (Super + Ctrl + B)
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
| Super + Escape | Power menu: AT FIELD (lock), STANDBY, EJECT PLUG (log out), REACTIVATE, SHUTDOWN / SELF-DESTRUCT |
| Super + L | Lock screen |
| Super + / | Every shortcut, searchable (read live from Hyprland) |
| Super + , | Settings: setup, depth, music, embers, date, sounds, klaxon, cicadas, corners, automations |
| Super + Shift + U | Switch setup: UNIT-01 ⇄ NERV HQ |
| Super + E | File manager (thunar) |
| Super + Shift + E | VS Code (Eva theme, follows the setup) |
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
| Super + Ctrl + R | Restart nerv-shell |
| Super + Ctrl + B | Rescue: stop nerv-shell and start the waybar setup |

Screenshots go to `~/Pictures/Screenshots/`, recordings to `~/Videos/Recordings/`.
In the bar: the NERV badge opens the launcher, the hex cells 01–05 are your
workspaces (the filled one is where you are), the segment clock opens the
dashboard, the status plate (中/EN, Wi-Fi, Bluetooth, volume) and the power plate
open the control centre. The power plate says **EXT** on the charger and
**INT** with a countdown of the battery time left on battery; below 15% it
turns red (and in NERV HQ the whole bar raises the alarm). A small lit square
on the status plate means unread messages.

## Extras

- **MAGI log** — real events (power, Wi-Fi, Bluetooth, USB devices, messages,
  locks, setup switches, game mode, rebuilds) scroll along the NERV HQ
  wallpaper and appear in the dashboard.
- **NERV operations** — the dashboard's bottom row: system generation, how old
  the flake inputs are, unpushed commits, disk, last backup, Hyprland version.
- **Screen filter** — CRT scanlines and edge fringing in NERV HQ, fine film grain
  in UNIT-01 (a Hyprland screen shader, `~/.config/eva/current/screen.frag`); off
  for games, fullscreen video and the lock; switch in Settings.
- **ThinkPad lights** — the red dot on the lid logo beats slowly on battery and
  blinks fast on alerts; the mic-mute light stays on while recording
  (`eva-led`, a root helper with fixed modes; switch in Settings).
- **Cursors and icons** — angular HUD cursors (`theme/cursors`: Eva-Unit01 /
  Eva-NERV) and folder colours (`theme/icons`: violet / deep orange over
  Papirus-Dark) follow the setup.
- **Sounds** — the real Pattern Blue klaxon and the AT field slamming shut
  (NERV HQ), Misato's 「おかえりなさい」 on unlock (UNIT-01), the umbilical cable
  disconnecting when you unplug the charger (both).
- **`eva`** — `eva` switches setup, `eva status`, `eva lock`, `eva sheet` (every
  panel in both setups on one image, from a hidden test desktop),
  `eva test …` (`tools/eva-test`: a nested Hyprland for trying changes without
  touching the real session).

## Typing Chinese

fcitx5 with pinyin starts at login. Press **Ctrl + Space** to switch between
English and Chinese — the bar shows **EN** or **中**. Type pinyin, pick with the
number keys or Space; `-`/`=` page through candidates.

WeChat is the Flathub app (`flatpak install flathub com.tencent.WeChat`), with
`flatpak override --env=XMODIFIERS=@im=fcitx com.tencent.WeChat` so pinyin works
in it (it's an X11 app and talks to fcitx5 over XIM).

## Game mode

Roblox (Sober) always runs without blur, animations or shadows, and may tear
for lower input lag. Notifications don't pop up over fullscreen games (they wait
in the control centre). **Super + G** turns on full game mode: every effect,
gap and animation off and Do Not Disturb on; press it again to restore.
With **auto game mode** (on by default), a game that asks Feral GameMode for
help — Sober does — switches game mode on by itself, and off when it quits.

## Lock screen

nerv-shell draws the lock screen itself. At boot, and in UNIT-01, it is the
Eva-01 screen: Unit-01 in the dark with its eye lit green, a title card with the
clock in heavy Mincho and 逃げちゃダメだ, and the pilot authentication field
(one block per letter). In NERV HQ it is the MAGI vote: type the code, press
Enter, and CASPER, BALTHASAR and MELCHIOR deliberate (審議中) and vote one after
another — 承認 opens it, 否決 turns the room red. Esc clears. It checks the
password with PAM (the `hyprlock` service, so the keyring unlocks too). If the
shell crashes while locked, systemd restarts it and it locks again; if the shell
can't be reached at all, `lock.sh` falls back to hyprlock.

## Automations

- **Battery saver** — below 20% on battery the wallpaper goes still (no
  animation or blur, power-saver profile) until you plug in.
- **Boards** — plug in an Arduino or CH340 board and a note shows its port, with
  a button that opens PictoBlox.
- **Cicadas** (off by default) — Tokyo-3's summer, very quietly, only while the
  desktop is empty (or locked) and nothing else plays.

## What runs at login

Getty autologins on tty1 and `.bash_profile` starts Hyprland, which then:

- starts the clipboard watcher and fcitx5
- starts `hyprland-session.target`, which activates `graphical-session.target` —
  that starts **nerv-shell** (systemd user service), xdg-desktop-portal and hypridle
- locks once with the Eva-01 boot lock (`lock.sh login`) — autologin skips the
  password, and unlocking also unlocks the gnome-keyring login keyring (its
  password must match the login password)

After 2 minutes idle the **screensaver** fills the screen with the setup's scene —
a slow drift across the painting with a wandering Mincho clock (UNIT-01) or the
full MAGI display (NERV HQ); any key, click or real mouse move ends it (switch it
off in Super + ,).
hypridle dims the screen after 4½ minutes idle, locks at 5 minutes (and before
sleep), and turns the screen off 30s later. nerv-shell is also the
notification daemon and the polkit (admin password) agent.

## Performance

`performance.nix` — every change here was measured on this laptop (Core Ultra 5
225H, 16 GB, single RAM stick) before it was kept:

- **More room in memory:** zram swap up to all of RAM (zstd), and the kernel is
  told swapping to it is cheap — many more apps stay open before anything slows.
- **No freezes when memory runs out:** earlyoom ends the single biggest process
  (browser tabs first; never Hyprland, the shell, kitty or audio).
- **Wi-Fi:** power saving is off on the charger (router round trip 7.2 → 2.2 ms,
  jitter 3.8 → 0.3 ms) and on with battery; BBR for steadier transfers.
- **Charger-aware:** nerv-shell switches Performance ↔ Balanced with the
  charger, and rests the shimmering border on battery (it redraws every frame).
- **Smaller things:** `noatime`, Firefox GPU video decoding and WebRender,
  1 s boot menu, launcher apps in their own systemd scopes.

Tried and dropped: sched_ext schedulers (the kernel's own was as good or better
overall), thermald (refuses to run on ThinkPads with Lenovo's DYTC), capping the
fast cores under load (+17% synthetic, nothing in real work).

The real bottleneck is memory bandwidth: one 16 GB stick runs single-channel.
**A second 16 GB DDR5-5600 SO-DIMM** (the second slot is empty) is the upgrade
that would make the biggest difference — to everything, games included.

## Printing

CUPS finds printers on the network (Avahi) and over USB (ipp-usb). Add one in
**Print Settings**, and pick the **driverless / IPP Everywhere** model — not
Gutenprint — for any recent printer, or jobs "complete" without printing. The
home printer (HP DeskJet 2800, on Wi-Fi) was set up with:

    sudo lpadmin -p HP-DeskJet-2800-series -E -m everywhere \
      -v ipp://HP2C58B91CB072.local:631/ipp/print && sudo lpadmin -d HP-DeskJet-2800-series

(Kept out of the Nix config on purpose: declaring it makes every boot fail
when the printer is switched off.)

## VS Code — Eva

`theme/vscode/` (`module.nix`, `gen.py`, `workbench.css.in`, `extension.js`,
`snippets/`). Everything is generated from `theme/setups/*.json`.

- **Two themes** — "Eva Unit-01" and "Eva NERV HQ", ~560 interface colours and
  syntax for C, assembly, Nix, Make, linker scripts and markup. `eva-switch`
  sets the matching one in your settings, and VS Code repaints at once. Built as
  a real `.vsix` and reinstalled automatically when it changes.
- **Inside VS Code** — it's installed patched: the interface is in Barlow, the
  caret glows in the accent, popups and the command palette are square glass,
  the NERV crest replaces the VS Code logo and sits on the empty editor. The
  patch reads the active theme's colours, so it follows the setup too. (Its
  integrity checksum is updated, so no "corrupt" warning.)
- **Status bar** — the date in Japanese numerals (`◢ 十一月二十二日`).
- **Entry plug mode** — `Ctrl+K Ctrl+N`: fullscreen, centred, nothing but the code.
- **OS-dev snippets** — in C: `kmain`, `portio`, `serial`, `gdt`, `idt`,
  `panic`, `packed`; in assembly: `multiboot`, `isr`, `lgdt`, `portio`; in
  linker scripts: `kernel-ld`.

The marketplace extensions it relies on (Material icons, Error Lens, clangd,
x86 assembly, linker scripts, Native Debug, Nix IDE) are installed on rebuild
if missing. Settings live in `~/.config/Code/User/settings.json` (a starter
copy is in `config/vscode/`).

## Firefox — Eva

`config/firefox/chrome/` (stylesheets) and `theme/firefox/` (builds the
profile's `chrome/` folder, plus a colours file and `user.js` per setup).

- **One colour map** — `eva-tokens.css` maps Firefox's own design tokens onto
  the setup's colours, so toolbars, menus, settings, add-ons and about: pages
  follow it. Websites keep their own look.
- **The window** — square tabs and plates, the accent on the selected tab and
  the focused address bar, Barlow for the interface.
- **New tab** — the Unit-01 painting (UNIT-01) or a command-room grid (NERV HQ),
  the NERV crest and "EVANGELION" in title-card Mincho.
- **Switching** — `eva-switch` copies the setup's `eva-colors.css` and `user.js`
  into the profile; restart Firefox to see the other setup.

## OS and kernel development

`dev.nix` (system) + `devshells.nix` (toolchains) + `pkgs/virtme-ng.nix`.

**Always available:** gcc/make, gdb (all architectures), QEMU (all
architectures, KVM), `vng`, clangd, bear, ccache (25 GB), cscope/ctags, nasm,
strace/ltrace, perf (no sudo for your own processes), bpftrace, trace-cmd,
xorriso/mtools, and man pages for syscalls/libc/POSIX (`man 2 mmap`).

**Linux kernel** — `nix develop ~/nixos-dotfiles#kernel`:

    git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git ~/src/linux
    cd ~/src/linux && nix develop ~/nixos-dotfiles#kernel
    vng --kconfig                 # small config that boots in QEMU
    make -j$(nproc) CC="ccache gcc"     # or LLVM=1 (clang); Rust: make LLVM=1 rustavailable
    vng                           # boot it: your files, your shell, the new kernel
    vng -- uname -r               # or just run one command in it
    make compile_commands.json    # (scripts/clang-tools) so clangd in VS Code understands the tree

Measured here: a `vng --kconfig` build of Linux 7.2.7 takes about 5 minutes and
boots in under half a second. GDB: start it with `vng --debug`, then run
`vng --gdb` in a second terminal (the kernel's vmlinux-gdb.py helpers load for
anything under ~/src).

**Your own OS** — `nix develop ~/nixos-dotfiles#osdev`: `x86_64-elf-gcc`,
`i686-elf-gcc`, `riscv64-none-elf-gcc`, `aarch64-none-elf-gcc`, clang/lld
(`--target=x86_64-elf`), nasm, Limine, GRUB (`grub-mkrescue`), and UEFI firmware
for QEMU (`qemu-system-x86_64 -bios $OVMF`).
For tutorials that use **GRUB Legacy**: `$STAGE2_ELTORITO` (GRUB 0.97 from
Debian, `pkgs/grub-legacy-stage2.nix`) and `genisoimage`. Copy it writable — the
Nix store is read-only and `-boot-info-table` writes into it:

    install -m 644 $STAGE2_ELTORITO iso/boot/grub/stage2_eltorito
    genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 \
      -A os -input-charset utf8 -quiet -boot-info-table -o os.iso iso
    qemu-system-i386 -cdrom os.iso -serial stdio

**Per project:** `echo "use flake ~/nixos-dotfiles#kernel" > .envrc && direnv allow`
— the shell loads whenever you `cd` in.

**VS Code:** clangd, x86 assembly, linker scripts, Native Debug (GDB → QEMU),
Nix IDE; C files use kernel style (tabs, 8 wide, rulers at 80/100).

## Changing colours and the shell

- Switch setups: **Super + Shift + U**, the control centre, settings, or
  `eva-switch unit01|magi|next` (`eva` for short). Firefox, Qt apps and btop
  follow on their next start; everything else at once.
- Colours: edit `theme/setups/<id>.json`. nerv-shell picks it up immediately;
  everything else on the next rebuild.
- The shell: `~/.config/quickshell` links straight to `config/quickshell/`, and
  Quickshell reloads itself when a file is saved — no rebuild needed. Its log:
  `journalctl --user -u nerv-shell -f`.
- UI sounds can be turned off in the control centre (Sounds tile); the klaxon
  separately in settings.

## Power and maintenance

- Battery charging stops at 80% (resumes below 75%). To charge to 100% until the next reboot:
  `echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold`
- Power profiles: `powerprofilesctl set power-saver|balanced|performance`
- Firmware updates: `fwupdmgr refresh && fwupdmgr get-updates`, then `fwupdmgr update`
- Old generations older than 14 days are garbage-collected weekly; the boot menu keeps 10.

## Hyprland config (Lua)

Hyprland 0.57 dropped the old `.conf` format; `config/hypr/hyprland.lua` is the
config (API: `<hyprland>/share/hypr/stubs/hl.meta.lua`). Options change at runtime
with `hyprctl eval 'hl.config({ … })'` (`hyprctl keyword` is gone), dispatchers are
Lua (`hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`). After a rebuild run
`hyprctl reload` (Hyprland doesn't notice the new config link by itself).

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
