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

  time.timeZone = "Asia/Malaysia";
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
   ];
 
  nix.settings.experimental-features = [ "nix-command" "flakes"];











 





























  system.stateVersion = "26.05"; # Did you read the comment?

}

