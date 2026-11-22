{config, lib, pkgs, ...}:

let
  # the boot login is always Eva-01: TTY colours and the splash use UNIT-01
  # (theme/setups/unit01.json), whichever setup the desktop is in
  palette = builtins.fromJSON (builtins.readFile ./theme/setups/unit01.json);
  hex = c: lib.removePrefix "#" c;

  # bind the Walnut buggy's serial data interface ($1, e.g. 3-2:1.2) to `option`,
  # stealing it from usbserial_generic if that grabbed it first
  # eva-led normal|battery|alert|record-on|record-off
  evaLed = pkgs.writeShellScriptBin "eva-led" ''
    dot=/sys/class/leds/tpacpi::lid_logo_dot
    mic=/sys/class/leds/platform::micmute
    blink() { echo timer > $dot/trigger; echo "$1" > $dot/delay_on; echo "$2" > $dot/delay_off; }
    case "''${1:-}" in
      normal)     echo none > $dot/trigger; echo 255 > $dot/brightness ;;
      battery)    blink 2200 260 ;;               # a slow heartbeat on internal power
      alert)      blink 110 110 ;;                # emergency
      record-on)  echo none > $mic/trigger; echo 1 > $mic/brightness ;;
      record-off) echo audio-micmute > $mic/trigger ;;
      *) echo "usage: eva-led normal|battery|alert|record-on|record-off" >&2; exit 1 ;;
    esac
  '';

  walnutBuggyBind = pkgs.writeShellScript "walnut-buggy-bind" ''
    echo "2f4e 0112" > /sys/bus/usb-serial/drivers/option1/new_id 2>/dev/null
    d=/sys/bus/usb/devices/$1/driver
    if [ "$(basename "$(readlink "$d")")" != option ]; then
      [ -e "$d" ] && echo "$1" > "$d/unbind"
      echo "$1" > /sys/bus/usb/drivers/option/bind
    fi
    exit 0
  '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./pictoblox.nix
      ./performance.nix
      ./printing.nix
      ./dev.nix
      ./pentest.nix
      ./theme/vscode/module.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  # 1 s menu (was 5): hold Space while booting to stay in it and pick an older generation
  boot.loader.timeout = 1;

  # boot splash: Unit-01's eye comes on green (theme/plymouth), and a quiet
  # boot so no kernel text scrolls past. It will also ask for the disk
  # password after the LUKS reinstall.
  boot.plymouth = {
    enable = true;
    theme = "eva";
    themePackages = [ (import ./theme/plymouth { inherit pkgs; }) ];
  };
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "splash" "loglevel=3" "rd.systemd.show_status=auto" "udev.log_level=3" "vt.global_cursor_default=0" ];
  # only root may read /boot (systemd-boot warns otherwise: its random seed lives there)
  fileSystems."/boot".options = lib.mkForce [ "fmask=0077" "dmask=0077" ];

  networking.hostName = "nixos"; 
  networking.networkmanager.enable = true;
  # look names up with Cloudflare/Quad9 on every network: the phone hotspot's own DNS
  # keeps timing out ("Server Not Found" in Firefox while the internet itself works)
  networking.networkmanager.settings."global-dns-domain-*".servers = "1.1.1.1,9.9.9.9";
  # keep the Wi-Fi card awake: iwlwifi power-saving caused lag spikes and periodic
  # "local choice" disconnects (Roblox dropping). Off = steady latency, low jitter.
  networking.networkmanager.wifi.powersave = false;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  time.timeZone = "Asia/Kuching";

  # UNIT-01 colours for the text consoles (TTYs); colour 0 is the background
  console.colors = [ (hex palette.base) ] ++ map hex (lib.drop 1 palette.terminal);
  services.getty.autologinUser = "Wallance";

  programs.hyprland = {
	enable = true;
	xwayland.enable = true;
  };

  users.users.Wallance = {
     isNormalUser = true;
     extraGroups = [ "wheel" "gamemode" "dialout" "uucp" "ydotool" "libvirtd" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree
     ];
   };

  programs.hyprlock.enable = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  # passwd also changes the keyring password, so the two never drift apart
  security.pam.services.passwd.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  programs.firefox.enable = true;

  # run prebuilt Linux binaries that extensions download (e.g. Claude Code's in VS Code)
  programs.nix-ld.enable = true;

  # fake mouse clicks on Wayland, for the auto clicker (Super+Alt+C, config/hypr/autoclick.sh)
  programs.ydotool.enable = true;

  # virtual machines (Kali etc.): virt-manager on QEMU/KVM
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Android apps (Walnut Education etc.) via Waydroid; first run: `sudo waydroid init`
  # off for now: the Walnut desktop app runs under Wine instead (~/.wine-walnut)
  # virtualisation.waydroid.enable = true;

  # local LLM runtime for OpenClaw (the Halcyon agent) — listens on 127.0.0.1:11434
  services.ollama.enable = true;
  # Ollama defaults to a 4096-token window, too small for OpenClaw's system prompt;
  # raise it so the agent's prompt + tools fit (bigger = more RAM per loaded model)
  services.ollama.environmentVariables.OLLAMA_CONTEXT_LENGTH = "16384";

  # closing the lid turns the screen off but does NOT suspend (keeps downloads,
  # the pentest agent, etc. running); applies on battery and AC
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # ThinkPad lights for the eva rice: the red dot on the lid logo pulses on
  # battery and blinks fast on alerts; the mic-mute light shows a recording.
  # nerv-shell calls `sudo -n eva-led <mode>` — only these fixed modes, no
  # password (see security.sudo below).
  security.sudo.extraRules = [{
    users = [ "Wallance" ];
    # sudo matches the exact path: the store path and the profile link both
    commands = [
      { command = "${evaLed}/bin/eva-led"; options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/eva-led"; options = [ "NOPASSWD" ]; }
    ];
  }];

  # keep the keyboard backlight off at every boot (Fn+Space still turns it on if wanted)
  systemd.services.kbd-backlight-off = {
    description = "Turn off the ThinkPad keyboard backlight";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-backlight@leds:tpacpi::kbd_backlight.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/leds/tpacpi::kbd_backlight/brightness'";
    };
  };

  # the Goodix touchpad sometimes stops sending input; reloading its driver brings it
  # back. Super+Ctrl+T starts this, and polkit lets Wallance do so without a password.
  systemd.services.touchpad-reset = {
    description = "Reload the touchpad driver";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kmod ];
    script = ''
      modprobe -r hid_multitouch i2c_hid_acpi
      sleep 1
      modprobe i2c_hid_acpi
      modprobe hid_multitouch
    '';
  };
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "touchpad-reset.service" &&
          action.lookup("verb") == "start" && subject.user == "Wallance")
        return polkit.Result.YES;
    });
  '';

  environment.systemPackages = with pkgs; [
     evaLed    # ThinkPad lid-dot / mic LED modes for nerv-shell (see above)
     vim
     wget
     foot
     code-cursor   # Cursor, the AI code editor (VS Code based)
     kitty
     waybar
     git
     hyprpaper
     rofi
     thunar
     firefox
     claude-code
     gh
     brightnessctl
     restic
     wlogout
     pavucontrol
     playerctl
     cliphist
     (papirus-icon-theme.override { color = "teal"; })
     grim
     slurp
     wl-clipboard
     mako
     libnotify
     hypridle
     hyprpolkitagent
     # nerv-shell (the desktop) and its tools
     quickshell
     satty          # draw on screenshots
     hyprpicker     # colour picker
   ];

  # screen recording with the GPU encoder, without a permission prompt each time
  programs.gpu-screen-recorder.enable = true;

  # Chinese input: fcitx5 with pinyin (Ctrl+Space switches English / 中文)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [ qt6Packages.fcitx5-chinese-addons fcitx5-gtk ];
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "pinyin";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "pinyin";
      };
      settings.addons = {
        classicui.globalSection = {
          Theme = "eva";
          DarkTheme = "eva";
          Font = "Barlow Semi Condensed 12";
          MenuFont = "Barlow Semi Condensed 11";
          "Vertical Candidate List" = "False";
        };
        pinyin.globalSection = {
          PageSize = 7;
          CloudPinyinEnabled = "False";
        };
      };
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
    "vscode"
    "cursor"
    "PictoBlox-Setup"
  ];

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Feral GameMode; Sober (flatpak) requests it through the portal.
  # Its hooks flip nerv-shell's game mode on and off (if auto game mode is on).
  programs.gamemode = let
    # gamemoded runs hooks without WAYLAND_DISPLAY, which qs needs to find the shell
    hook = what: pkgs.writeShellScript "eva-game${what}" ''
      if [ -z "$WAYLAND_DISPLAY" ]; then
        for s in "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/wayland-*; do
          case "$s" in *.lock) continue ;; esac
          export WAYLAND_DISPLAY="''${s##*/}"; break
        done
      fi
      exec /run/current-system/sw/bin/qs ipc call nerv game${what}
    '';
  in {
    enable = true;
    settings.custom = { start = "${hook "start"}"; end = "${hook "end"}"; };
  };

  # Qt apps follow the setup too (qt5ct/qt6ct; colours in theme/eva.nix)
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  hardware.graphics.enable = true;
  # VA-API video decoding for Intel Arc (Firefox, mpv)
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
  hardware.graphics.enable32Bit = true;
  
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono   # bar numbers, fallback mono
    maple-mono.NF               # terminal (rounded, with Nerd Font icons)
    barlow                      # nerv-shell HUD text (Barlow / Condensed / Semi Condensed)
    material-symbols            # nerv-shell icons (Sharp)
    noto-fonts-cjk-sans         # Chinese / Japanese text
    noto-fonts-cjk-serif        # Eva title cards (heavy Mincho)
  ];

  # needed by home-manager dconf settings (dark mode)
  programs.dconf.enable = true;

  zramSwap.enable = true;
 
  nix.settings.experimental-features = [ "nix-command" "flakes"];

  # Weekly clean-up of old system generations and store dedup
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # hyprpolkitagent installs to libexec; expose it at /run/current-system/sw/libexec
  environment.pathsToLink = [ "/libexec" ];

  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  # realtime scheduling for PipeWire: fewer audio crackles under load (games)
  security.rtkit.enable = true;

  # Stop charging at 90% to extend battery lifespan (start must stay below end)
  systemd.services.battery-charge-threshold = {
    description = "Set battery charge thresholds";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo 85 > /sys/class/power_supply/BAT0/charge_control_start_threshold
      echo 90 > /sys/class/power_supply/BAT0/charge_control_end_threshold
    '';
  };

  system.stateVersion = "26.05"; # Did you read the comment?
 
  # 1. Provide total read/write clearances to the hardware chip
services.udev.extraRules = ''
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", TAG+="uaccess"
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="5523", MODE="0666", TAG+="uaccess"
  KERNEL=="ttyUSB*", MODE="0666", TAG+="uaccess"
  # Walnut Education robot (HETAO_BUGGY 2f4e:0112) for the Walnut app under Wine:
  # its CDC serial descriptors are broken (union points at ifaces 0/1, real ones are 1/2)
  # so cdc_acm refuses it; drive the data iface with the `option` driver instead (it
  # supports DTR/RTS, which the app needs) and give it a fixed name for Wine's COM5
  KERNEL=="hidraw*", ATTRS{idVendor}=="2f4e", MODE="0666", TAG+="uaccess"
  ACTION=="add|bind", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", ATTRS{idVendor}=="2f4e", ATTRS{idProduct}=="0112", ATTR{bInterfaceNumber}=="02", RUN+="${walnutBuggyBind} %k"
  SUBSYSTEM=="tty", ENV{ID_VENDOR_ID}=="2f4e", ENV{ID_MODEL_ID}=="0112", ENV{ID_USB_INTERFACE_NUM}=="02", SYMLINK+="walnut-buggy", MODE="0666"
'';
# Wine's COM5 -> /dev/walnut-buggy (symlink in ~/.wine-walnut/dosdevices)
boot.kernelModules = [ "option" "ledtrig-timer" ];   # ledtrig-timer: eva-led blinks the lid dot

}

