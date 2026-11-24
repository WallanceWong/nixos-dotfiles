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
  ffProfile = ".config/mozilla/firefox/zqrxnfnx.default-1795397238238";
  evaFirefox = import ./firefox { inherit pkgs lib; };
  evaCursors = import ./cursors { inherit pkgs lib; };
  evaIcons = import ./icons { inherit pkgs lib; };
  iconName = p: if p.id == "magi" then "Eva-NERV-Icons" else "Eva-Unit01-Icons";
  cursorName = p: if p.id == "magi" then "Eva-NERV" else "Eva-Unit01";

  # ── Hyprland ──────────────────────────────────────────────────────
  # hypr.lua: the setup's look for Hyprland (borders, rounding, motion), run by
  # config/hypr/hyprland.lua and again by eva-switch. hypr.conf: the colours as
  # hyprlang variables, for hyprlock (the fallback lock).
  hyprConf = p: ''
    # ${p.name} — generated from theme/setups/${p.id}.json by theme/eva.nix
    $crust    = rgb(${hex p.crust})
    $base     = rgb(${hex p.base})
    $surface0 = rgb(${hex p.surface0})
    $surface1 = rgb(${hex p.surface1})
    $overlay  = rgb(${hex p.overlay})
    $subtext  = rgb(${hex p.subtext})
    $text     = rgb(${hex p.text})
    $accent   = rgb(${hex p.accent})
    $armour   = rgb(${hex p.armour})
    $signal   = rgb(${hex p.signal})
    $info     = rgb(${hex p.info})
    $caution  = rgb(${hex p.caution})
    $alert    = rgb(${hex p.alert})
    $shadow   = rgba(${hex p.crust}cc)
  '';
  hypr = p: let
    magi = p.id == "magi";
    # name, x0 y0 x1 y1
    curves = if magi then [ [ "slam" 0.1 1 0.1 1 ] [ "snap" 0.7 0 0.3 1 ] [ "linear" 0 0 1 1 ] ]
             else [ [ "tide" 0.22 1 0.36 1 ] [ "settle" 0.05 0.9 0.1 1.02 ] [ "linear" 0 0 1 1 ] ];
    # leaf, speed, curve, style
    anims = if magi then [
      [ "windows" 3 "slam" "popin 92%" ] [ "windowsOut" 2 "snap" "popin 92%" ] [ "fade" 2 "snap" "" ]
      [ "border" 4 "snap" "" ] [ "borderangle" 30 "linear" "loop" ] [ "layers" 2 "slam" "slide" ]
      [ "workspaces" 3 "slam" "slide" ] [ "specialWorkspace" 3 "slam" "slidevert" ]
    ] else [
      [ "windows" 5 "settle" "popin 88%" ] [ "windowsOut" 4 "tide" "popin 88%" ] [ "fade" 5 "tide" "" ]
      [ "border" 8 "tide" "" ] [ "borderangle" 100 "linear" "loop" ] [ "layers" 4 "tide" "fade" ]
      [ "workspaces" 5 "tide" "slidefade 12%" ] [ "specialWorkspace" 5 "tide" "slidevert" ]
    ];
    n = x: toString x;
    at = builtins.elemAt;
  in ''
    -- ${p.name} — generated from theme/setups/${p.id}.json by theme/eva.nix
    hl.config({
        general = {
            col = {
                active_border = { colors = { "rgb(${hex (if magi then p.accent else p.armour)})", "rgb(${hex (if magi then p.alert else p.accent)})" }, angle = ${if magi then "90" else "45"} },
                inactive_border = "rgba(${hex p.surface1}cc)",
            },
        },
        decoration = {
            rounding = 0,
            shadow = { color = "rgba(${hex p.crust}cc)" },
        },
        misc = { background_color = "rgb(${hex p.crust})" },
        animations = { enabled = true },
    })
    -- the setup's cursor (theme/cursors), for Hyprland and for GTK apps
    hl.exec_cmd("hyprctl setcursor ${cursorName p} 24; ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/cursor-theme \"'${cursorName p}'\"; ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/icon-theme \"'${iconName p}'\"")
  '' + lib.concatMapStrings (c: ''
    hl.curve("${at c 0}", { type = "bezier", points = { { ${n (at c 1)}, ${n (at c 2)} }, { ${n (at c 3)}, ${n (at c 4)} } } })
  '') curves + lib.concatMapStrings (a: ''
    hl.animation({ leaf = "${at a 0}", enabled = true, speed = ${n (at a 1)}, bezier = "${at a 2}"${if at a 3 != "" then '', style = "${at a 3}"'' else ""} })
  '') anims;

  # the screen filter (Settings → Screen filter; nerv-shell applies it and
  # lifts it for games and fullscreen video). No time uniform: Hyprland only
  # redraws what changed, so it costs a single extra pass per frame drawn.
  screenShader = p: ''
    #version 300 es
    // ${p.name}: ${if p.id == "magi" then "CRT — scanlines, colour fringing toward the edges, vignette" else "film — fine static grain, soft vignette"}
    precision highp float;
    in vec2 v_texcoord;
    uniform sampler2D tex;
    out vec4 fragColor;
    void main() {
        vec2 c = v_texcoord - 0.5;
        float d = dot(c, c);
  '' + (if p.id == "magi" then ''
        float ca = 0.0048 * d;
        vec4 col = texture(tex, v_texcoord);
        col.r = texture(tex, v_texcoord + c * ca).r;
        col.b = texture(tex, v_texcoord - c * ca).b;
        float line = mod(gl_FragCoord.y, 3.0) < 1.0 ? 0.86 : 1.0;
        float vig = 1.0 - smoothstep(0.16, 0.62, d) * 0.38;
        fragColor = vec4(col.rgb * line * vig, col.a);
    }
  '' else ''
        vec4 col = texture(tex, v_texcoord);
        float n = fract(sin(dot(floor(gl_FragCoord.xy), vec2(12.9898, 78.233))) * 43758.5453);
        float vig = 1.0 - smoothstep(0.20, 0.66, d) * 0.28;
        fragColor = vec4((col.rgb + (n - 0.5) * 0.028) * vig, col.a);
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
    /* square HUD plates everywhere */
    button, entry, spinbutton, combobox, dropdown, popover, popover > contents, menu, .menu, menubar,
    tooltip, check, radio, switch, switch slider, scale slider, scale trough, progressbar trough, progressbar progress,
    frame, .frame, .card, notebook, notebook > header tab, list, listview, row, treeview, iconview,
    window.dialog, messagedialog, .osd, scrollbar slider, headerbar, .titlebar, decoration { border-radius: 0; }
    decoration { box-shadow: 0 0 0 1px alpha(${p.accent}, 0.25), 0 8px 24px alpha(${p.crust}, 0.6); }
    headerbar, .titlebar { box-shadow: inset 0 -1px alpha(${p.accent}, 0.45); }
    headerbar .title { font-weight: 700; letter-spacing: 1px; }
    entry:focus, entry:focus-within, spinbutton:focus-within { outline: 1px solid ${p.accent}; outline-offset: -1px; box-shadow: none; }
    scale highlight, levelbar block.filled { background-color: ${p.accent}; border-color: ${p.accent}; }
    progressbar progress {
      background-color: ${p.accent};
      background-image: repeating-linear-gradient(135deg, alpha(${p.crust}, 0.35) 0, alpha(${p.crust}, 0.35) 6px, transparent 6px, transparent 12px);
      border-color: ${p.accent};
    }
    scale slider { background-color: ${p.accent}; }
    switch:checked, checkbutton check:checked, radiobutton radio:checked, check:checked, radio:checked { background-color: ${p.accent}; border-color: ${p.accent}; color: ${p.crust}; }
    notebook > header tab:checked, stackswitcher button:checked { box-shadow: inset 0 -2px ${p.accent}; }
    entry, combobox button, dropdown button, button.combo { background-color: ${p.surface0}; }
    button:not(.flat):not(.suggested-action):not(.destructive-action) { background-color: ${p.surface0}; background-image: none; color: ${p.text}; border-color: ${p.surface1}; }
    button:not(.flat):hover { background-color: ${p.surface1}; border-color: alpha(${p.accent}, 0.5); }
    button.suggested-action { background-color: ${p.accent}; color: ${p.crust}; }
    button.destructive-action { background-color: ${p.alert}; color: ${p.crust}; }
    scrollbar slider { background-color: alpha(${p.accent}, 0.45); min-width: 4px; min-height: 4px; }
    scrollbar slider:hover { background-color: ${p.accent}; }
    selection, *:selected, text selection { background-color: alpha(${p.accent}, 0.35); color: ${p.text}; }
    tooltip, tooltip.background { background-color: ${p.base}; border: 1px solid alpha(${p.accent}, 0.5); }
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
    "eva/${p.id}/hypr.conf".text = hyprConf p;
    "eva/${p.id}/hypr.lua".text = hypr p;
    "eva/${p.id}/screen.frag".text = screenShader p;
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
    runtimeInputs = with pkgs; [ coreutils gnused procps dconf ];
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
      for code in "$cfg/Code/User/settings.json" "$cfg/Cursor/User/settings.json"; do
        [ -f "$code" ] && sed -i -E "s|(\"workbench.colorTheme\": *)\"[^\"]*\"|\1\"$(cat "$cfg/eva/$id/vscode-theme")\"|" "$code"
      done

      # live reloads
      # Hyprland re-runs the setup's hypr.lua (borders, motion) — no full reload
      command -v hyprctl >/dev/null && hyprctl eval 'EvaLoadSetup()' >/dev/null 2>&1 || true
      pkill -USR1 -x .kitty-wrapped 2>/dev/null || pkill -USR1 -x kitty 2>/dev/null || true   # kitty re-reads its config
      # GTK 3/4 apps re-read gtk.css when the theme name changes (dconf: no
      # schemas needed)
      t=$(dconf read /org/gnome/desktop/interface/gtk-theme 2>/dev/null); t=''${t:-"'adw-gtk3-dark'"}
      dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'" 2>/dev/null || true
      sleep 0.2
      dconf write /org/gnome/desktop/interface/gtk-theme "$t" 2>/dev/null || true
      command -v fcitx5-remote >/dev/null && fcitx5-remote -r 2>/dev/null || true
      echo "eva: $id"
    '';
  };
  # `eva`: one command for the rice
  evaCli = pkgs.writeShellApplication {
    name = "eva";
    runtimeInputs = with pkgs; [ coreutils gnugrep systemd ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/eva/setup"
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}"
      case "''${1:-next}" in
        next|unit01|magi) exec eva-switch "''${1:-next}" ;;
        status)
          s=$(cat "$state" 2>/dev/null || echo unit01)
          echo "setup     $s ($( [ "$s" = magi ] && echo "NERV HQ / MAGI" || echo "UNIT-01 / SHINJI"))"
          echo "current   $(readlink "$cfg/eva/current")"
          echo "shell     $(systemctl --user is-active nerv-shell)"
          if [ "$(hyprctl eval 'return 0' 2>/dev/null)" = ok ]; then echo "hyprland  lua config"; else echo "hyprland  legacy .conf (restart Hyprland)"; fi
          echo "errors    $(hyprctl configerrors 2>/dev/null | grep -c . || true)"
          echo "locked    $(qs ipc call nerv locked 2>/dev/null || echo "?")"
          ;;
        lock) exec qs ipc call nerv lock ;;
        test) shift; exec "$HOME/nixos-dotfiles/tools/eva-test" "$@" ;;
        sheet)
          t="$HOME/nixos-dotfiles/tools/eva-test"
          "$t" start >/dev/null && "$t" sheet "''${2:-$HOME/Pictures/eva/sheet.png}"; "$t" stop >/dev/null ;;
        *)
          cat <<USAGE
      eva                  switch to the other setup
      eva unit01|magi      switch to that setup
      eva status           what's running
      eva lock             lock the screen
      eva sheet [file]     every panel in both setups on one image (hidden test desktop)
      eva test …           the hidden test desktop (tools/eva-test)
      USAGE
          ;;
      esac
    '';
  };
in
{
  home.packages = [ evaSwitch evaCli evaCursors.unit01 evaCursors.magi evaIcons.unit01 evaIcons.magi ];

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
      Environment = [
        # glibc re-reads /etc/localtime on every time conversion unless TZ is
        # set — and Quickshell timestamps every log line
        "TZ=:/etc/localtime"
        # the PipeWire loop logs twice per event (hundreds a second while the
        # wallpaper follows music)
        "QT_LOGGING_RULES=quickshell.service.pipewire.loop.debug=false"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Firefox: chrome/ from theme/firefox (eva-colors.css and user.js are
  # copied in by the activation above / eva-switch) ──
  home.file."${ffProfile}/chrome" = { source = "${evaFirefox}/chrome"; recursive = true; };
}
