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
		# tint Adwaita-dark into the whisper night-sky navy (GTK3 apps like Thunar)
		gtk3.extraCss = ''
			@define-color theme_bg_color #071a28;
			@define-color theme_base_color #0a2233;
			@define-color theme_fg_color #e3e8e1;
			@define-color theme_text_color #e3e8e1;
			@define-color theme_selected_bg_color #3f6e74;
			@define-color theme_selected_fg_color #f0e3a8;
			@define-color borders #13384e;
			@define-color unfocused_borders #0c2a3d;
			window, .background, .sidebar, placessidebar, .view, treeview, iconview, headerbar, .titlebar {
				background-color: #071a28;
				color: #e3e8e1;
			}
			.sidebar, placessidebar, placessidebar list { background-color: #05131e; }
			headerbar, .titlebar, toolbar, .toolbar { background-color: #0c2a3d; background-image: none; border-color: #13384e; }
			.view:selected, iconview:selected, treeview:selected, row:selected { background-color: #13384e; color: #f0e3a8; }
			scale highlight, progressbar progress, levelbar block.filled { background-color: #7fc3c6; border-color: #7fc3c6; }
			scale slider { background-color: #f0e3a8; }
			switch:checked, checkbutton check:checked, radiobutton radio:checked, check:checked, radio:checked { background-color: #3f6e74; border-color: #7fc3c6; color: #f0e3a8; }
			notebook > header tab:checked, stackswitcher button:checked { box-shadow: inset 0 -2px #f0e3a8; }
			entry, combobox button, dropdown button, button.combo { background-color: #0c2a3d; }
			button:not(.flat):not(.suggested-action):not(.destructive-action) { background-color: #0c2a3d; background-image: none; color: #e3e8e1; border-color: #13384e; }
			button:not(.flat):hover { background-color: #13384e; }
		'';
		# same tint for GTK4 / libadwaita apps
		gtk4.extraCss = ''
			@define-color window_bg_color #071a28;
			@define-color view_bg_color #0a2233;
			@define-color headerbar_bg_color #0c2a3d;
			@define-color sidebar_bg_color #05131e;
			@define-color card_bg_color #0c2a3d;
			@define-color popover_bg_color #0c2a3d;
			@define-color dialog_bg_color #0c2a3d;
			@define-color accent_bg_color #3f6e74;
			@define-color accent_color #7fc3c6;
			window, .background, .view, headerbar, .titlebar, popover > contents, list, listview, columnview {
				background-color: #071a28;
				color: #e3e8e1;
			}
			headerbar, .titlebar, notebook > header { background-color: #0c2a3d; background-image: none; border-color: #13384e; }
			.sidebar, .navigation-sidebar { background-color: #05131e; }
			row:selected, .view:selected { background-color: #13384e; color: #f0e3a8; }
			frame, .card, notebook > stack { background-color: #0a2233; border-color: #13384e; }
			scale highlight, progressbar progress, levelbar block.filled { background-color: #7fc3c6; border-color: #7fc3c6; }
			scale slider { background-color: #f0e3a8; }
			switch:checked, checkbutton check:checked, radiobutton radio:checked, check:checked, radio:checked { background-color: #3f6e74; border-color: #7fc3c6; color: #f0e3a8; }
			notebook > header tab:checked, stackswitcher button:checked { box-shadow: inset 0 -2px #f0e3a8; }
			entry, combobox button, dropdown button, button.combo { background-color: #0c2a3d; }
			button:not(.flat):not(.suggested-action):not(.destructive-action) { background-color: #0c2a3d; background-image: none; color: #e3e8e1; border-color: #13384e; }
			button:not(.flat):hover { background-color: #13384e; }
		'';
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
			palettes.whisper = {
				lamp = "#f0e3a8"; teal = "#7fc3c6"; blue = "#6d9fd1";
				subtext = "#9fb5bd"; red = "#e0786c"; mustard = "#e3b35c";
			};
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
			logo = {
				type = "kitty-direct";
				source = "~/nixos-dotfiles/wallpapers/fetch.png";
				width = 26;
				height = 13;
				padding = { top = 1; left = 1; right = 3; };
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
		themes.whisper = ''
			theme[main_bg]="#071a28"
			theme[main_fg]="#e3e8e1"
			theme[title]="#f0e3a8"
			theme[hi_fg]="#7fc3c6"
			theme[selected_bg]="#13384e"
			theme[selected_fg]="#f0e3a8"
			theme[inactive_fg]="#3f6e74"
			theme[graph_text]="#9fb5bd"
			theme[meter_bg]="#0c2a3d"
			theme[proc_misc]="#7fc3c6"
			theme[cpu_box]="#3f6e74"
			theme[mem_box]="#3f6e74"
			theme[net_box]="#3f6e74"
			theme[proc_box]="#3f6e74"
			theme[div_line]="#13384e"
			theme[temp_start]="#7fc3c6"
			theme[temp_mid]="#f0e3a8"
			theme[temp_end]="#e0786c"
			theme[cpu_start]="#7fc3c6"
			theme[cpu_mid]="#f0e3a8"
			theme[cpu_end]="#e0786c"
			theme[free_start]="#8fbf9a"
			theme[free_mid]="#7fc3c6"
			theme[free_end]="#6d9fd1"
			theme[cached_start]="#6d9fd1"
			theme[cached_mid]="#7fc3c6"
			theme[cached_end]="#a6dcdc"
			theme[available_start]="#f0e3a8"
			theme[available_mid]="#e3b35c"
			theme[available_end]="#e0786c"
			theme[used_start]="#7fc3c6"
			theme[used_mid]="#f0e3a8"
			theme[used_end]="#e0786c"
			theme[download_start]="#6d9fd1"
			theme[download_mid]="#7fc3c6"
			theme[download_end]="#f0e3a8"
			theme[upload_start]="#8fbf9a"
			theme[upload_mid]="#f0e3a8"
			theme[upload_end]="#e3b35c"
			theme[process_start]="#7fc3c6"
			theme[process_mid]="#f0e3a8"
			theme[process_end]="#e0786c"
		'';
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
