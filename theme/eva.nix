# eva — the Evangelion rice. Two setups, switchable live with Super+Shift+U:
#   unit01  UNIT-01 / SHINJI  (calm)       theme/setups/unit01.json
#   magi    NERV HQ / MAGI    (full drama) theme/setups/magi.json
# Every app's colours are generated here for BOTH setups into
# ~/.config/eva/<id>/, and each app reads ~/.config/eva/current/…, a link that
# `eva-switch <id>` flips (then reloads what can reload). The Quickshell shell
# reads the setup files live.
{ config, pkgs, lib, ... }:

let
  load = id: builtins.fromJSON (builtins.readFile (./setups + "/${id}.json"));
  ids = [ "unit01" "magi" ];
  setups = map load ids;
  hex = c: lib.removePrefix "#" c;                       # "#ff7a1a" -> "ff7a1a"
  # nano only takes 3-digit colours: keep the first hex digit of each channel
  short = c: "#" + lib.concatMapStrings (i: builtins.substring i 1 c) [ 1 3 5 ];
  rgb = c: let h = hex c; n = s: toString (lib.fromHexString s); in
    "${n (builtins.substring 0 2 h)};${n (builtins.substring 2 2 h)};${n (builtins.substring 4 2 h)}";
  dots = "${config.home.homeDirectory}/nixos-dotfiles";
  home = config.home.homeDirectory;
  cur = "${config.xdg.configHome}/eva/current";
  link = config.lib.file.mkOutOfStoreSymlink;
  ffProfile = ".config/mozilla/firefox/btea7p9y.default";
  evaFirefox = import ./firefox { inherit pkgs lib; };

  # ── Hyprland: colours + the setup's look (borders, motion) ──────────
  hypr = p: ''
    # ${p.name} — generated from theme/setups/${p.id}.json by theme/eva.nix
    $crust    = rgb(${hex p.crust})
    $mantle   = rgb(${hex p.mantle})
    $base     = rgb(${hex p.base})
    $surface0 = rgb(${hex p.surface0})
    $surface1 = rgb(${hex p.surface1})
    $surface2 = rgb(${hex p.surface2})
    $overlay  = rgb(${hex p.overlay})
    $subtext  = rgb(${hex p.subtext})
    $text     = rgb(${hex p.text})
    $accent   = rgb(${hex p.accent})
    $armour   = rgb(${hex p.armour})
    $signal   = rgb(${hex p.signal})
    $info     = rgb(${hex p.info})
    $caution  = rgb(${hex p.caution})
    $alert    = rgb(${hex p.alert})
    $inactiveBorder = rgba(${hex p.surface1}cc)
    $shadow         = rgba(${hex p.crust}cc)

    general {
        col.active_border = ${if p.id == "magi" then "$accent $alert 90deg" else "$armour $accent 45deg"}
        col.inactive_border = $inactiveBorder
    }
    decoration {
        rounding = 0
        shadow {
            color = $shadow
        }
    }
    misc {
        background_color = $crust
    }
    animations {
        enabled = true
  '' + (if p.id == "magi" then ''
        # NERV HQ: fast and mechanical — panels slam in, borders run
        bezier = slam, 0.1, 1, 0.1, 1
        bezier = snap, 0.7, 0, 0.3, 1
        bezier = linear, 0, 0, 1, 1
        animation = windows, 1, 3, slam, popin 92%
        animation = windowsOut, 1, 2, snap, popin 92%
        animation = fade, 1, 2, snap
        animation = border, 1, 4, snap
        animation = borderangle, 1, 30, linear, loop
        animation = layers, 1, 2, slam, slide
        animation = workspaces, 1, 3, slam, slide
        animation = specialWorkspace, 1, 3, slam, slidevert
    }
  '' else ''
        # UNIT-01: slow and smooth, like the evening tide
        bezier = tide, 0.22, 1, 0.36, 1
        bezier = settle, 0.05, 0.9, 0.1, 1.02
        bezier = linear, 0, 0, 1, 1
        animation = windows, 1, 5, settle, popin 88%
        animation = windowsOut, 1, 4, tide, popin 88%
        animation = fade, 1, 5, tide
        animation = border, 1, 8, tide
        animation = borderangle, 1, 120, linear, loop
        animation = layers, 1, 4, tide, fade
        animation = workspaces, 1, 5, tide, slidefade 12%
        animation = specialWorkspace, 1, 5, tide, slidevert
    }
  '');

  kitty = p: ''
    # ${p.name} — generated from theme/setups/${p.id}.json
    foreground              ${p.text}
    background              ${p.base}
    selection_foreground    ${p.base}
    selection_background    ${p.accent}
    cursor                  ${p.accent}
    cursor_text_color       ${p.base}
    url_color               ${p.info}
    active_border_color     ${p.accent}
    inactive_border_color   ${p.surface1}
    bell_border_color       ${p.alert}
    active_tab_foreground   ${p.crust}
    active_tab_background   ${p.accent}
    inactive_tab_foreground ${p.subtext}
    inactive_tab_background ${p.surface0}
    tab_bar_background      ${p.mantle}
    visual_bell_color       ${p.surface2}
  '' + lib.concatImapStrings (i: c: "color${toString (i - 1)} ${c}\n") p.terminal;

  # buttons, sliders, switches — the same for GTK3 and GTK4 (square, accent-lit)
  sharedCss = p: ''
    scale highlight, progressbar progress, levelbar block.filled { background-color: ${p.accent}; border-color: ${p.accent}; }
    scale slider { background-color: ${p.accent}; border-radius: 0; }
    switch:checked, checkbutton check:checked, radiobutton radio:checked, check:checked, radio:checked { background-color: ${p.accent}; border-color: ${p.accent}; color: ${p.crust}; }
    notebook > header tab:checked, stackswitcher button:checked { box-shadow: inset 0 -2px ${p.accent}; }
    entry, combobox button, dropdown button, button.combo { background-color: ${p.surface0}; }
    button:not(.flat):not(.suggested-action):not(.destructive-action) { background-color: ${p.surface0}; background-image: none; color: ${p.text}; border-color: ${p.surface1}; }
    button:not(.flat):hover { background-color: ${p.surface1}; }
    button, entry, popover > contents, menu, .menu, tooltip, check, switch, scale slider, frame, .card { border-radius: 2px; }
  '';
  gtk3 = p: ''
    /* ${p.name} — generated from theme/setups/${p.id}.json */
    @define-color window_bg_color ${p.base};
    @define-color view_bg_color ${p.sunken};
    @define-color headerbar_bg_color ${p.surface0};
    @define-color sidebar_bg_color ${p.mantle};
    @define-color card_bg_color ${p.surface0};
    @define-color popover_bg_color ${p.surface0};
    @define-color dialog_bg_color ${p.surface0};
    @define-color accent_bg_color ${p.accent};
    @define-color accent_fg_color ${p.crust};
    @define-color accent_color ${p.accent};
    @define-color theme_bg_color ${p.base};
    @define-color theme_base_color ${p.sunken};
    @define-color theme_fg_color ${p.text};
    @define-color theme_text_color ${p.text};
    @define-color theme_selected_bg_color ${p.accent};
    @define-color theme_selected_fg_color ${p.crust};
    @define-color borders ${p.surface1};
    @define-color unfocused_borders ${p.surface0};
    window, .background, .sidebar, placessidebar, .view, treeview, iconview, headerbar, .titlebar {
      background-color: ${p.base};
      color: ${p.text};
    }
    .sidebar, placessidebar, placessidebar list { background-color: ${p.mantle}; }
    headerbar, .titlebar, toolbar, .toolbar { background-color: ${p.surface0}; background-image: none; border-color: ${p.surface1}; }
    .view:selected, iconview:selected, treeview:selected, row:selected { background-color: ${p.surface1}; color: ${p.accent}; }
  '' + sharedCss p;
  gtk4 = p: ''
    /* ${p.name} — generated from theme/setups/${p.id}.json */
    @define-color window_bg_color ${p.base};
    @define-color view_bg_color ${p.sunken};
    @define-color headerbar_bg_color ${p.surface0};
    @define-color sidebar_bg_color ${p.mantle};
    @define-color card_bg_color ${p.surface0};
    @define-color popover_bg_color ${p.surface0};
    @define-color dialog_bg_color ${p.surface0};
    @define-color accent_bg_color ${p.accent};
    @define-color accent_fg_color ${p.crust};
    @define-color accent_color ${p.accent};
    window, .background, .view, headerbar, .titlebar, popover > contents, list, listview, columnview {
      background-color: ${p.base};
      color: ${p.text};
    }
    headerbar, .titlebar, notebook > header { background-color: ${p.surface0}; background-image: none; border-color: ${p.surface1}; }
    .sidebar, .navigation-sidebar { background-color: ${p.mantle}; }
    row:selected, .view:selected { background-color: ${p.surface1}; color: ${p.accent}; }
    frame, .card, notebook > stack { background-color: ${p.sunken}; border-color: ${p.surface1}; }
  '' + sharedCss p;

  btop = p: let t = p.terminal; in ''
    # ${p.name} — generated from theme/setups/${p.id}.json
    theme[main_bg]="${p.base}"
    theme[main_fg]="${p.text}"
    theme[title]="${p.accent}"
    theme[hi_fg]="${p.armour}"
    theme[selected_bg]="${p.surface1}"
    theme[selected_fg]="${p.accent}"
    theme[inactive_fg]="${p.overlay}"
    theme[graph_text]="${p.subtext}"
    theme[meter_bg]="${p.surface0}"
    theme[proc_misc]="${p.armour}"
    theme[cpu_box]="${p.accentDim}"
    theme[mem_box]="${p.accentDim}"
    theme[net_box]="${p.accentDim}"
    theme[proc_box]="${p.accentDim}"
    theme[div_line]="${p.surface1}"
    theme[temp_start]="${p.signal}"
    theme[temp_mid]="${p.caution}"
    theme[temp_end]="${p.alert}"
    theme[cpu_start]="${p.accent}"
    theme[cpu_mid]="${p.caution}"
    theme[cpu_end]="${p.alert}"
    theme[free_start]="${p.signal}"
    theme[free_mid]="${p.info}"
    theme[free_end]="${builtins.elemAt t 12}"
    theme[cached_start]="${p.info}"
    theme[cached_mid]="${builtins.elemAt t 12}"
    theme[cached_end]="${builtins.elemAt t 14}"
    theme[available_start]="${p.accent}"
    theme[available_mid]="${p.caution}"
    theme[available_end]="${p.alert}"
    theme[used_start]="${p.armour}"
    theme[used_mid]="${p.caution}"
    theme[used_end]="${p.alert}"
    theme[download_start]="${p.info}"
    theme[download_mid]="${p.armour}"
    theme[download_end]="${p.accent}"
    theme[upload_start]="${p.signal}"
    theme[upload_mid]="${p.accent}"
    theme[upload_end]="${p.caution}"
    theme[process_start]="${p.accent}"
    theme[process_mid]="${p.caution}"
    theme[process_end]="${p.alert}"
  '';

  # prompt:  ◢ UNIT-01 ~/dir  branch  …   /  ▲ MAGI …
  starship = p: ''
    # ${p.name} — generated from theme/setups/${p.id}.json
    add_newline = true
    format = "$custom$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character"
    palette = "eva"

    [palettes.eva]
    accent = "${p.accent}"
    armour = "${p.armour}"
    info = "${p.info}"
    subtext = "${p.subtext}"
    alert = "${p.alert}"
    caution = "${p.caution}"
    overlay = "${p.overlay}"

    [custom.unit]
    command = "true"
    when = "true"
    format = "[${if p.id == "magi" then "▲ MAGI" else "◢ EVA-01"} ](bold accent)"

    [directory]
    format = "[$path]($style)[$read_only]($read_only_style) "
    style = "bold armour"
    truncation_length = 3
    truncation_symbol = "…/"

    [git_branch]
    format = "[$symbol$branch]($style) "
    symbol = " "
    style = "info"

    [git_status]
    format = "[$all_status$ahead_behind]($style) "
    style = "caution"

    [nix_shell]
    format = "[$symbol$name]($style) "
    symbol = " "
    style = "info"

    [cmd_duration]
    format = "[SYNC $duration]($style) "
    style = "subtext"
    min_time = 2000

    [character]
    success_symbol = "[${if p.id == "magi" then "»" else "❯"}](bold accent)"
    error_symbol = "[${if p.id == "magi" then "» 否決" else "❯"}](bold alert)"
  '';

  # fastfetch: the crest in ASCII, keys in the setup's colours
  # (theme/nerv-crest.txt: the crest in quarter blocks, rendered from the
  # shell's nerv.svg)
  crestArt = pkgs.writeText "nerv-crest.txt"
    (lib.concatMapStrings (l: "$1" + l + "\n") (lib.splitString "\n" (lib.removeSuffix "\n" (builtins.readFile ./nerv-crest.txt))));

  fastfetch = p: builtins.toJSON {
    logo = {
      source = "${crestArt}";
      type = "file";
      color = { "1" = "38;2;${rgb (if p.id == "magi" then p.alert else p.armour)}"; "2" = "38;2;${rgb p.text}"; "3" = "38;2;${rgb p.text}"; };
      padding = { top = 1; left = 2; right = 4; };
    };
    display = {
      separator = "  ";
      color = { keys = "38;2;${rgb p.accent}"; title = "38;2;${rgb p.armour}"; separator = "38;2;${rgb p.overlay}"; };
    };
    modules = [
      { type = "title"; format = "{user-name}@{host-name}"; }
      { type = "custom"; format = if p.id == "magi" then "NERV HQ · MAGI SYSTEM" else "EVA-01 · TEST TYPE"; outputColor = "38;2;${rgb p.subtext}"; }
      { type = "separator"; string = "─"; outputColor = "38;2;${rgb p.overlay}"; }
      { type = "os";       key = "OS    "; format = "{name} {version-id}"; }
      { type = "kernel";   key = "KERNEL"; }
      { type = "packages"; key = "PKGS  "; }
      { type = "wm";       key = "WM    "; }
      { type = "terminal"; key = "TERM  "; }
      { type = "cpu";      key = "SYNC  "; format = "{name}"; }
      { type = "gpu";      key = "GPU   "; format = "{name}"; }
      { type = "memory";   key = "LCL   "; }
      { type = "disk";     key = "DISK  "; folders = "/"; }
      { type = "battery";  key = "POWER "; }
      { type = "uptime";   key = "ACTIVE"; }
      "break"
      { type = "colors"; symbol = "block"; }
    ];
  };

  nanorc = p: ''
    # ${p.name} — generated from theme/setups/${p.id}.json
    include "${pkgs.nano}/share/nano/*.nanorc"
    set linenumbers
    set autoindent
    set mouse
    set indicator
    set constantshow
    set tabsize 4
    set titlecolor bold,${short p.crust},${short p.accent}
    set promptcolor ${short p.crust},${short p.accent}
    set statuscolor bold,${short p.crust},${short p.armour}
    set errorcolor bold,${short p.text},${short p.alert}
    set spotlightcolor ${short p.crust},${short p.caution}
    set selectedcolor ${short p.crust},${short p.accent}
    set stripecolor ,${short p.surface0}
    set scrollercolor ${short p.overlay}
    set numbercolor ${short p.overlay}
    set keycolor bold,${short p.accent}
    set functioncolor ${short p.subtext}
    set minicolor ${short p.crust},${short p.armour}
  '';

  satty = p: ''
    [general]
    early-exit = true
    initial-tool = "brush"
    copy-command = "wl-copy"
    corner-roundness = 0
    annotation-size-factor = 2

    [font]
    family = "Barlow Condensed"
    style = "Bold"

    [color-palette]
    palette = ["${p.accent}", "${p.armour}", "${p.alert}", "${p.caution}", "${p.signal}", "${p.info}", "${p.text}"]
  '';

  # Qt palette rows, in qtct order:
  # WindowText Button Light Midlight Dark Mid Text BrightText ButtonText
  # Base Window Shadow Highlight HighlightedText Link LinkVisited AlternateBase
  # NoRole ToolTipBase ToolTipText PlaceholderText Accent
  qtScheme = p: let row = lib.concatStringsSep ", "; act = row [ p.text p.surface0 p.surface2 p.surface1 p.crust p.mantle p.text p.accent p.text
             p.sunken p.base p.crust p.accent p.crust p.info p.armour p.surface0
             p.base p.surface0 p.text p.overlay p.accent ]; in ''
    [ColorScheme]
    active_colors=${act}
    disabled_colors=${row [ p.overlay p.surface0 p.surface1 p.surface0 p.crust p.mantle p.overlay p.overlay p.overlay
               p.sunken p.base p.crust p.surface1 p.subtext p.overlay p.overlay p.surface0
               p.base p.surface0 p.overlay p.surface2 p.overlay ]}
    inactive_colors=${act}
  '';
  qtConf = ct: ''
    [Appearance]
    color_scheme_path=${cur}/qt.conf
    custom_palette=true
    icon_theme=Papirus-Dark
    standard_dialogs=xdgdesktopportal
    style=Fusion

    [Fonts]
    fixed="Maple Mono NF,10"
    general="Barlow Semi Condensed,10"
  '';

  fcitx5 = p: ''
    [Metadata]
    Name=eva
    Version=2
    Author=eva
    Description=${p.name}: square HUD candidate window
    ScaleWithDPI=True

    [InputPanel]
    Font=Barlow Semi Condensed 12
    NormalColor=${p.text}
    HighlightCandidateColor=${p.crust}
    HighlightColor=${p.accent}
    HighlightBackgroundColor=${p.accent}
    Spacing=4

    [InputPanel/TextMargin]
    Left=10
    Right=10
    Top=6
    Bottom=6

    [InputPanel/ContentMargin]
    Left=3
    Right=3
    Top=3
    Bottom=3

    [InputPanel/Background]
    Color=${p.base}
    BorderColor=${p.accent}
    BorderWidth=2

    [InputPanel/Background/Margin]
    Left=3
    Right=3
    Top=3
    Bottom=3

    [InputPanel/Highlight]
    Color=${p.accent}

    [InputPanel/Highlight/Margin]
    Left=10
    Right=10
    Top=6
    Bottom=6

    [Menu]
    NormalColor=${p.text}
    HighlightCandidateColor=${p.crust}
    Spacing=4

    [Menu/Background]
    Color=${p.base}
    BorderColor=${p.surface1}
    BorderWidth=2

    [Menu/Highlight]
    Color=${p.accent}

    [Menu/Separator]
    Color=${p.surface1}

    [Menu/ContentMargin]
    Left=4
    Right=4
    Top=4
    Bottom=4
  '';

  perSetup = p: {
    "eva/${p.id}/hypr.conf".text = hypr p;
    "eva/${p.id}/kitty.conf".text = kitty p;
    "eva/${p.id}/gtk3.css".text = gtk3 p;
    "eva/${p.id}/gtk4.css".text = gtk4 p;
    "eva/${p.id}/btop.theme".text = btop p;
    "eva/${p.id}/starship.toml".text = starship p;
    "eva/${p.id}/fastfetch.jsonc".text = fastfetch p;
    "eva/${p.id}/nanorc".text = nanorc p;
    "eva/${p.id}/satty.toml".text = satty p;
    "eva/${p.id}/qt.conf".text = qtScheme p;
    "eva/${p.id}/fcitx5.conf".text = fcitx5 p;
    "eva/${p.id}/firefox.css".source = "${evaFirefox}/setups/${p.id}.css";
    "eva/${p.id}/firefox.js".source = "${evaFirefox}/setups/${p.id}.js";
    "eva/${p.id}/vscode-theme".text = if p.id == "magi" then "Eva NERV HQ" else "Eva Unit-01";
  };

  # flip the setup: the link, the state file the shell watches, then reload
  # whatever can reload live (Firefox, Qt apps and btop pick it up on restart)
  evaSwitch = pkgs.writeShellApplication {
    name = "eva-switch";
    runtimeInputs = with pkgs; [ coreutils gnused procps glib ];
    text = ''
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}"
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/eva"
      id="''${1:-}"
      if [ "$id" = next ] || [ -z "$id" ]; then
        [ "$(cat "$state/setup" 2>/dev/null)" = magi ] && id=unit01 || id=magi
      fi
      case "$id" in unit01|magi) ;; *) echo "usage: eva-switch [unit01|magi|next]" >&2; exit 1 ;; esac
      [ -d "$cfg/eva/$id" ] || { echo "eva-switch: $cfg/eva/$id is missing (rebuild first)" >&2; exit 1; }

      mkdir -p "$state"
      ln -sfn "$cfg/eva/$id" "$cfg/eva/current"
      printf '%s\n' "$id" > "$state/setup"          # the shell repaints from this

      # Firefox reads copies (its sandbox won't follow links out of the profile)
      ff="$HOME/${ffProfile}"
      if [ -d "$ff/chrome" ]; then
        install -m 644 "$cfg/eva/$id/firefox.css" "$ff/chrome/eva-colors.css"
        install -m 644 "$cfg/eva/$id/firefox.js" "$ff/user.js"
      fi
      # VS Code repaints when its colour theme setting changes
      code="$cfg/Code/User/settings.json"
      if [ -f "$code" ]; then
        sed -i -E "s|(\"workbench.colorTheme\": *)\"[^\"]*\"|\1\"$(cat "$cfg/eva/$id/vscode-theme")\"|" "$code"
      fi

      # live reloads
      command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true
      pkill -USR1 -x kitty 2>/dev/null || true                     # kitty re-reads its config
      # GTK 3/4 apps re-read gtk.css when the theme name changes
      t=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'adw-gtk3-dark'")
      gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" 2>/dev/null || true
      gsettings set org.gnome.desktop.interface gtk-theme "$t" 2>/dev/null || true
      command -v fcitx5-remote >/dev/null && fcitx5-remote -r 2>/dev/null || true
      echo "eva: $id"
    '';
  };
in
{
  home.packages = [ evaSwitch ];

  # ── per-setup files, and the apps pointed at ~/.config/eva/current ──
  xdg.configFile = lib.mkMerge (map perSetup setups ++ [{
    "nano/nanorc".source = link "${cur}/nanorc";
    "satty/config.toml".source = link "${cur}/satty.toml";
    "qt5ct/qt5ct.conf".text = qtConf "qt5ct";
    "qt6ct/qt6ct.conf".text = qtConf "qt6ct";
    # the shell is linked straight to the repo, so editing it applies at once
    # (Quickshell reloads itself on save) without a rebuild
    "quickshell".source = link "${dots}/config/quickshell";
  }]);
  xdg.dataFile."fcitx5/themes/eva/theme.conf".source = link "${cur}/fcitx5.conf";
  gtk.gtk3.extraCss = ''@import url("file://${cur}/gtk3.css");'';
  gtk.gtk4.extraCss = ''@import url("file://${cur}/gtk4.css");'';
  home.sessionVariables.STARSHIP_CONFIG = lib.mkForce "${cur}/starship.toml";

  # first run: pick UNIT-01 and point `current` at it; keep Firefox's copies fresh
  home.activation.evaCurrent = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/eva"
    cfg="${config.xdg.configHome}"
    run mkdir -p "$state"
    id=$(cat "$state/setup" 2>/dev/null || echo unit01)
    case "$id" in unit01|magi) ;; *) id=unit01 ;; esac
    run sh -c 'printf "%s\n" "$1" > "$2"' sh "$id" "$state/setup"
    run ln -sfn "$cfg/eva/$id" "$cfg/eva/current"
    if [ -d "$HOME/${ffProfile}/chrome" ]; then
      run install -m 644 "$cfg/eva/$id/firefox.css" "$HOME/${ffProfile}/chrome/eva-colors.css"
      run install -m 644 "$cfg/eva/$id/firefox.js" "$HOME/${ffProfile}/user.js"
      run rm -f "$HOME/${ffProfile}/chrome/whisper-colors.css"
    fi
  '';

  # ── the shell (its files are linked above) ──────────────────────
  systemd.user.services.nerv-shell = {
    Unit = {
      Description = "nerv-shell: bar, living wallpaper, lock screen, panels (Quickshell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Firefox: chrome/ from theme/firefox (eva-colors.css and user.js are
  # copied in by the activation above / eva-switch) ──
  home.file."${ffProfile}/chrome" = { source = "${evaFirefox}/chrome"; recursive = true; };
}
