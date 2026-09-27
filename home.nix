{config, pkgs, ...}:

{
	home.username ="Wallance";
	home.homeDirectory = "/home/Wallance";
	home.stateVersion = "26.05";
	programs.bash = {
		enable = true;
		shellAliases = {
			btw = "echo NixOS better than arch, btw";
			# Encrypted home backup in ~/restic-thinkpad (upload that folder to Google Drive by hand)
			restic-home = "restic --cache-dir ~/.cache/restic --password-file ~/.config/restic/password -r ~/restic-thinkpad";
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
		enable = true;
		name = "Adwaita";
		package = pkgs.adwaita-icon-theme;
		size = 24;
		gtk.enable = true;
	};

	# mpv with hardware decoding (intel-media-driver)
	programs.mpv = {
		enable = true;
		config.hwdec = "auto-safe";
	};

	xdg.mimeApps = {
		enable = true;
		defaultApplications =
			let
				for = app: types: builtins.listToAttrs (map (t: { name = t; value = app; }) types);
			in
			for "firefox.desktop" [
				"image/png" "image/jpeg" "image/gif" "image/webp" "image/svg+xml" "image/avif" "image/bmp"
				"application/pdf"
			]
			// for "mpv.desktop" [
				"video/mp4" "video/x-matroska" "video/webm" "video/quicktime" "video/x-msvideo" "video/mpeg" "video/ogg"
			]
			// {
				"text/plain" = "code.desktop";
				"inode/directory" = "thunar.desktop";
				# written by Claude Code before home-manager managed this file
				"x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
			};
	};

	home.sessionVariables = {
        XDG_DATA_DIRS = "/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
};
}
