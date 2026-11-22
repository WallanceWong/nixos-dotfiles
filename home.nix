{config, pkgs, lib, ...}:

{
	# eva theme: two setups (UNIT-01 / NERV HQ) for everything + the Quickshell
	# desktop (theme/eva.nix)
	imports = [ ./theme/eva.nix ];

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
			# the prompt and fetch follow the active setup (theme/eva.nix)
			export STARSHIP_CONFIG="$HOME/.config/eva/current/starship.toml"
			if [[ $TERM == xterm-kitty && $SHLVL -eq 1 ]]; then fastfetch -c "$HOME/.config/eva/current/fastfetch.jsonc"; fi
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
	# Firefox theme files are linked by theme/eva.nix

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
		theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
		# folder colours follow the setup (theme/icons overlays on Papirus-Dark)
		iconTheme = { name = "Eva-Unit01-Icons"; package = (import ./theme/icons { inherit pkgs lib; }).unit01; };
		# colours: gtk3/gtk4 extraCss (an @import of the active setup) come from theme/eva.nix
	};
	dconf.settings."org/gnome/desktop/interface" = {
		color-scheme = "prefer-dark";
		accent-color = "purple";
		icon-theme = "Eva-Unit01-Icons";
		cursor-theme = "Eva-Unit01";
	};

	# the eva HUD cursor (theme/cursors); each setup's hypr.lua switches it live.
	# Bibata stays installed: the eva themes inherit the shapes they don't draw
	home.pointerCursor = {
		enable = true;
		name = "Eva-Unit01";
		package = (import ./theme/cursors { inherit pkgs lib; }).unit01;
		size = 24;
		gtk.enable = true;
		hyprcursor.enable = true;
	};

	# ── terminal: prompt, fetch, monitor ─────────────────────────────
	# prompt and fetch: their configs are per setup (theme/eva.nix), picked up
	# through STARSHIP_CONFIG and `fastfetch -c` above
	programs.starship = {
		enable = true;
		enableBashIntegration = true;
	};
	programs.fastfetch.enable = true;

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
			color_theme = "${config.xdg.configHome}/eva/current/btop.theme";   # per setup, theme/eva.nix
			theme_background = false;
			rounded_corners = false;
			vim_keys = true;
		};
	};

	# VS Code starter settings (Eva theme). Copied only if missing, so
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

	# mpv with hardware decoding (intel-media-driver). Audio goes through
	# pipewire-pulse: with rtkit on, mpv's native PipeWire output gets a realtime
	# thread that overruns its time limit and the kernel kills mpv.
	programs.mpv = {
		enable = true;
		config = { hwdec = "auto-safe"; ao = "pulse"; };
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

	# modern CLI helpers
	programs.fzf.enable = true;
	programs.zoxide.enable = true;
	programs.bat.enable = true;
	programs.zellij.enable = true;
	home.packages = with pkgs; [ ripgrep fd bibata-cursors papirus-icon-theme ];
}
