{config, pkgs, lib, ...}:

{
	# whisper theme: colours for everything + the Quickshell desktop (theme/whisper.nix)
	imports = [ ./theme/whisper.nix ];

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
		initExtra = ''
			if [[ $TERM == xterm-kitty && $SHLVL -eq 1 ]]; then fastfetch; fi
		'';
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
	home.file.".config/wlogout".source = ./config/wlogout;
	# Firefox theme files are linked by theme/whisper.nix

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
		iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme.override { color = "teal"; }; };
		# colours: gtk3/gtk4 extraCss come from theme/whisper.nix
	};
	dconf.settings."org/gnome/desktop/interface" = {
		color-scheme = "prefer-dark";
		accent-color = "teal";
		icon-theme = "Papirus-Dark";
		cursor-theme = "Bibata-Modern-Ice";
	};

	home.pointerCursor = {
		enable = true;
		name = "Bibata-Modern-Ice";
		package = pkgs.bibata-cursors;
		size = 24;
		gtk.enable = true;
		hyprcursor.enable = true;
	};

	# ── terminal: prompt, fetch, monitor ─────────────────────────────
	programs.starship = {
		enable = true;
		enableBashIntegration = true;
		settings = {
			add_newline = true;
			format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
			palette = "whisper";
			# palettes.whisper comes from theme/whisper.nix
			directory = {
				format = "[󰖔 ](lamp)[$path]($style)[$read_only]($read_only_style) ";
				style = "bold teal";
				truncation_length = 3;
				truncation_symbol = "…/";
			};
			git_branch = { format = "[$symbol$branch]($style) "; symbol = " "; style = "blue"; };
			git_status = { format = "[$all_status$ahead_behind]($style) "; style = "mustard"; };
			nix_shell = { format = "[$symbol$name]($style) "; symbol = " "; style = "blue"; };
			cmd_duration = { format = "[󱎫 $duration]($style) "; style = "subtext"; min_time = 2000; };
			character = { success_symbol = "[❯](bold lamp)"; error_symbol = "[❯](bold red)"; };
		};
	};

	programs.fastfetch = {
		enable = true;
		settings = {
			# Tux: body in muted city-glow (dark but visible on navy), moonlight belly,
			# mustard beak and feet
			logo = {
				source = "Linux";
				color = { "1" = "38;2;227;232;225"; "2" = "38;2;63;110;116"; "3" = "38;2;227;179;92"; };
				padding = { top = 1; left = 2; right = 4; };
			};
			display = {
				separator = "  ";
				color = { keys = "38;2;240;227;168"; title = "38;2;127;195;198"; separator = "38;2;63;110;116"; };
			};
			modules = [
				{ type = "title"; format = "{user-name}@{host-name}"; }
				{ type = "separator"; string = "─"; outputColor = "38;2;63;110;116"; }
				{ type = "os";       key = ""; format = "{name} {version-id}"; }
				{ type = "kernel";   key = "󰒓"; }
				{ type = "packages"; key = "󰏖"; }
				{ type = "wm";       key = ""; }
				{ type = "terminal"; key = ""; }
				{ type = "shell";    key = ""; }
				{ type = "cpu";      key = ""; format = "{name}"; }
				{ type = "gpu";      key = "󰍹"; format = "{name}"; }
				{ type = "memory";   key = "󰍛"; }
				{ type = "disk";     key = "󰋊"; folders = "/"; }
				{ type = "battery";  key = ""; }
				{ type = "uptime";   key = "󰥔"; }
				"break"
				{ type = "colors"; symbol = "circle"; }
			];
		};
	};

	programs.eza = {
		enable = true;
		enableBashIntegration = true;
		icons = "auto";
		git = true;
		extraOptions = [ "--group-directories-first" ];
	};

	programs.btop = {
		enable = true;
		settings = {
			color_theme = "whisper";
			theme_background = false;
			rounded_corners = true;
			vim_keys = true;
		};
		# themes.whisper comes from theme/whisper.nix
	};

	# VS Code starter settings in the whisper palette. Copied only if missing, so
	# VS Code can keep editing them (a home.file link would be read-only).
	home.activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
		if [ ! -e "$HOME/.config/Code/User/settings.json" ]; then
			run mkdir -p "$HOME/.config/Code/User"
			run install -m 644 ${./config/vscode/settings.json} "$HOME/.config/Code/User/settings.json"
		fi
		if [ ! -e "$HOME/.vscode/argv.json" ]; then
			run mkdir -p "$HOME/.vscode"
			run install -m 644 ${./config/vscode/argv.json} "$HOME/.vscode/argv.json"
		fi
	'';

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
