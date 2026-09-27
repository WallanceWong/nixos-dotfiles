{config, pkgs, ...}:

{
	home.username ="Wallance";
	home.homeDirectory = "/home/Wallance";
	home.stateVersion = "26.05";
	programs.bash = {
		enable = true;
		shellAliases = {
			btw = "echo NixOS better than arch, btw";
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
	home.file.".config/mako".source = ./config/mako;

	# Hyprland is launched from the login shell, not systemd, so bind
	# graphical-session.target to this target and start it from hyprland.conf
	systemd.user.targets.hyprland-session.Unit = {
		Description = "Hyprland compositor session";
		BindsTo = [ "graphical-session.target" ];
		Wants = [ "graphical-session-pre.target" ];
		After = [ "graphical-session-pre.target" ];
	};

	# Dark theme for GTK apps and the portal (Firefox and libadwaita apps follow color-scheme)
	gtk = {
		enable = true;
		theme = { name = "Adwaita-dark"; package = pkgs.gnome-themes-extra; };
	};
	dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

	home.pointerCursor = {
		name = "Adwaita";
		package = pkgs.adwaita-icon-theme;
		size = 24;
		gtk.enable = true;
	};

	home.sessionVariables = {
        XDG_DATA_DIRS = "/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
};
}
