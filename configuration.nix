{config, lib, pkgs, ...}:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  system.stateVersion = "26.05"; # Did you read the comment?

}

