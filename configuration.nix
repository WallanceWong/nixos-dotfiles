{config, lib, pkgs, ...}:

let
  # the one palette (see theme/palette.json)
  palette = builtins.fromJSON (builtins.readFile ./theme/palette.json);
  hex = c: lib.removePrefix "#" c;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./pictoblox.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.hostName = "nixos"; 
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  time.timeZone = "Asia/Kuching";

  # whisper palette for the text consoles (TTYs); colour 0 is the background
  console.colors = [ (hex palette.base) ] ++ map hex (lib.drop 1 palette.terminal);
  services.getty.autologinUser = "Wallance";

  programs.hyprland = {
	enable = true;
	xwayland.enable = true;
  };

  users.users.Wallance = {
     isNormalUser = true;
     extraGroups = [ "wheel" "gamemode" "dialout" "uucp" ]; # Enable ‘sudo’ for the user.
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

  environment.systemPackages = with pkgs; [
     vim 
     wget
     foot
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
     vscode
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
     # whisper-shell (the desktop) and its tools
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
          Theme = "whisper";
          DarkTheme = "whisper";
          Font = "Nunito 12";
          MenuFont = "Nunito 11";
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
    "PictoBlox-Setup"
  ];

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Feral GameMode; Sober (flatpak) requests it through the portal
  programs.gamemode.enable = true;

  hardware.graphics.enable = true;
  # VA-API video decoding for Intel Arc (Firefox, mpv)
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
  hardware.graphics.enable32Bit = true;
  
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono   # terminal, bar numbers
    nunito                      # whisper-shell text
    material-symbols            # whisper-shell icons
    noto-fonts-cjk-sans         # Chinese / Japanese text
    noto-fonts-cjk-serif        # the vertical Japanese date in the sky
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

  # Stop charging at 80% to extend battery lifespan (start must stay below end)
  systemd.services.battery-charge-threshold = {
    description = "Set battery charge thresholds";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo 75 > /sys/class/power_supply/BAT0/charge_control_start_threshold
      echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold
    '';
  };

  system.stateVersion = "26.05"; # Did you read the comment?
 
  # 1. Provide total read/write clearances to the hardware chip
services.udev.extraRules = ''
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", TAG+="uaccess"
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="5523", MODE="0666", TAG+="uaccess"
  KERNEL=="ttyUSB*", MODE="0666", TAG+="uaccess"
'';

}

