{config, lib, pkgs, ...}:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
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
  services.getty.autologinUser = "Wallance";

  programs.hyprland = {
	enable = true;
	xwayland.enable = true;
  };

  users.users.Wallance = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree
     ];
   };

  programs.hyprlock.enable = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
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
     python3Packages.pywal
     firefox
     claude-code
     gh
     brightnessctl
     grim
     slurp
     wl-clipboard
     mako
     libnotify
     hypridle
     hyprpolkitagent
   ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  hardware.graphics.enable = true;

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

}

