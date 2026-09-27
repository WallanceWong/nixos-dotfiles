{config, pkgs, ...}:

{
	home.username ="Wallance";
	home.homeDirectory = "/home/Wallance";
	home.stateVersion = "26.05";
	programs.bash = {
		enable = true;
		shellAliases = {
			btw = "NixOS better than arch, btw";
		};
		profileExtra =''
			if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
				exec hyprland
			fi
		'';
		};
	
	home.file.".config/hypr".source = ./config/hypr;
	home.file.".config/waybar".source = ./config/waybar;
	home.file.".config/rofi".source = ./config/rofi;
	home.file.".config/kitty".source = ./config/kitty;

	home.sessionVariables = {
        XDG_DATA_DIRS = "/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
};
}
