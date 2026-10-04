# whisper — everything that takes its colours from theme/palette.json, the one
# palette. Change a colour there and rebuild; the Quickshell shell reads the same
# file live.
{ config, pkgs, lib, ... }:

let
  p = builtins.fromJSON (builtins.readFile ./palette.json);
  t = p.terminal;
  hex = c: lib.removePrefix "#" c;                       # "#f0e3a8" -> "f0e3a8"
  # nano only takes 3-digit colours: keep the first hex digit of each channel
  short = c: "#" + lib.concatMapStrings (i: builtins.substring i 1 c) [ 1 3 5 ];
  dots = "${config.home.homeDirectory}/nixos-dotfiles";
  ffProfile = ".config/mozilla/firefox/btea7p9y.default";

  # buttons, sliders, switches — the same for GTK3 and GTK4
  sharedCss = ''
    scale highlight, progressbar progress, levelbar block.filled { background-color: ${p.teal}; border-color: ${p.teal}; }
    scale slider { background-color: ${p.lamp}; }
    switch:checked, checkbutton check:checked, radiobutton radio:checked, check:checked, radio:checked { background-color: ${p.overlay}; border-color: ${p.teal}; color: ${p.lamp}; }
    notebook > header tab:checked, stackswitcher button:checked { box-shadow: inset 0 -2px ${p.lamp}; }
    entry, combobox button, dropdown button, button.combo { background-color: ${p.surface0}; }
    button:not(.flat):not(.suggested-action):not(.destructive-action) { background-color: ${p.surface0}; background-image: none; color: ${p.text}; border-color: ${p.surface1}; }
    button:not(.flat):hover { background-color: ${p.surface1}; }
  '';
  # Qt palette rows, in qtct order:
  # WindowText Button Light Midlight Dark Mid Text BrightText ButtonText
  # Base Window Shadow Highlight HighlightedText Link LinkVisited AlternateBase
  # NoRole ToolTipBase ToolTipText PlaceholderText Accent
  qtRow = cs: lib.concatStringsSep ", " cs;
  qtActive = [ p.text p.surface0 p.surface2 p.surface1 p.crust p.mantle p.text p.lamp p.text
             p.sunken p.base p.crust p.overlay p.lamp p.teal p.violet p.surface0
             p.base p.surface0 p.text p.overlay p.teal ];
  qtDisabled = [ p.overlay p.surface0 p.surface1 p.surface0 p.crust p.mantle p.overlay p.overlay p.overlay
               p.sunken p.base p.crust p.surface1 p.subtext p.overlay p.overlay p.surface0
               p.base p.surface0 p.overlay p.surface2 p.overlay ];
  qtScheme = ''
    [ColorScheme]
    active_colors=${qtRow qtActive}
    disabled_colors=${qtRow qtDisabled}
    inactive_colors=${qtRow qtActive}
  '';
  qtConf = ct: ''
    [Appearance]
    color_scheme_path=${config.xdg.configHome}/${ct}/colors/whisper.conf
    custom_palette=true
    icon_theme=Papirus-Dark
    standard_dialogs=xdgdesktopportal
    style=Fusion

    [Fonts]
    fixed="Maple Mono NF,10"
    general="Nunito,10"
  '';
in
{
  # ── the shell ───────────────────────────────────────────────────
  # Linked straight to the repo, so editing the shell applies instantly
  # (Quickshell reloads itself on save) without a rebuild.
  xdg.configFile."quickshell".source = config.lib.file.mkOutOfStoreSymlink "${dots}/config/quickshell";

  systemd.user.services.whisper-shell = {
    Unit = {
      Description = "whisper-shell: bar, living wallpaper, notifications, panels (Quickshell)";
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

  # ── Hyprland + hyprlock ─────────────────────────────────────────
  xdg.configFile."whisper/hypr-colors.conf".text = ''
    # generated from theme/palette.json — edit that instead
    $crust    = rgb(${hex p.crust})
    $mantle   = rgb(${hex p.mantle})
    $base     = rgb(${hex p.base})
    $surface0 = rgb(${hex p.surface0})
    $surface1 = rgb(${hex p.surface1})
    $surface2 = rgb(${hex p.surface2})
    $overlay  = rgb(${hex p.overlay})
    $subtext  = rgb(${hex p.subtext})
    $text     = rgb(${hex p.text})
    $lamp     = rgb(${hex p.lamp})
    $lampdim  = rgb(${hex p.lampDim})
    $teal     = rgb(${hex p.teal})
    $blue     = rgb(${hex p.blue})
    $red      = rgb(${hex p.red})
    $mustard  = rgb(${hex p.mustard})
    $green    = rgb(${hex p.green})
    $violet   = rgb(${hex p.violet})

    # with transparency
    $inactiveBorder = rgba(${hex p.surface1}cc)
    $shadow         = rgba(${hex p.crust}bb)
    $glass          = rgba(${hex p.base}cc)
    $crustSoft      = rgba(${hex p.crust}cc)
    $textSoft       = rgba(${hex p.text}99)
  '';

  # ── kitty ───────────────────────────────────────────────────────
  xdg.configFile."whisper/kitty-colors.conf".text = ''
    # generated from theme/palette.json — edit that instead
    foreground              ${p.text}
    background              ${p.base}
    selection_foreground    ${p.base}
    selection_background    ${p.lamp}
    cursor                  ${p.lamp}
    cursor_text_color       ${p.base}
    url_color               ${p.teal}
    active_border_color     ${p.lamp}
    inactive_border_color   ${p.surface1}
    bell_border_color       ${p.mustard}
    active_tab_foreground   ${p.base}
    active_tab_background   ${p.lamp}
    inactive_tab_foreground ${p.subtext}
    inactive_tab_background ${p.surface0}
    tab_bar_background      ${p.mantle}
    visual_bell_color       ${p.surface2}
  '' + lib.concatImapStrings (i: c: "color${toString (i - 1)} ${c}\n") t;

  # ── Firefox ─────────────────────────────────────────────────────
  home.file."${ffProfile}/chrome/userChrome.css".source = ../config/firefox/chrome/userChrome.css;
  home.file."${ffProfile}/chrome/userContent.css".source = ../config/firefox/chrome/userContent.css;
  home.file."${ffProfile}/chrome/whisper-colors.css".text = ''
    /* generated from theme/palette.json — edit that instead */
    :root {
      --w-crust: ${p.crust}; --w-mantle: ${p.mantle}; --w-base: ${p.base}; --w-sunken: ${p.sunken};
      --w-surface0: ${p.surface0}; --w-surface1: ${p.surface1}; --w-surface2: ${p.surface2};
      --w-overlay: ${p.overlay}; --w-subtext: ${p.subtext}; --w-text: ${p.text};
      --w-lamp: ${p.lamp}; --w-teal: ${p.teal}; --w-blue: ${p.blue}; --w-red: ${p.red};
    }
  '';
  home.file."${ffProfile}/user.js".source = ../config/firefox/user.js;

  # ── GTK (Adwaita-dark, tinted into the night sky) ───────────────
  gtk.gtk3.extraCss = ''
    @define-color window_bg_color ${p.base};
    @define-color view_bg_color ${p.sunken};
    @define-color headerbar_bg_color ${p.surface0};
    @define-color sidebar_bg_color ${p.mantle};
    @define-color card_bg_color ${p.surface0};
    @define-color popover_bg_color ${p.surface0};
    @define-color dialog_bg_color ${p.surface0};
    @define-color accent_bg_color ${p.overlay};
    @define-color accent_color ${p.teal};
    @define-color theme_bg_color ${p.base};
    @define-color theme_base_color ${p.sunken};
    @define-color theme_fg_color ${p.text};
    @define-color theme_text_color ${p.text};
    @define-color theme_selected_bg_color ${p.overlay};
    @define-color theme_selected_fg_color ${p.lamp};
    @define-color borders ${p.surface1};
    @define-color unfocused_borders ${p.surface0};
    window, .background, .sidebar, placessidebar, .view, treeview, iconview, headerbar, .titlebar {
      background-color: ${p.base};
      color: ${p.text};
    }
    .sidebar, placessidebar, placessidebar list { background-color: ${p.mantle}; }
    headerbar, .titlebar, toolbar, .toolbar { background-color: ${p.surface0}; background-image: none; border-color: ${p.surface1}; }
    .view:selected, iconview:selected, treeview:selected, row:selected { background-color: ${p.surface1}; color: ${p.lamp}; }
  '' + sharedCss;
  gtk.gtk4.extraCss = ''
    @define-color window_bg_color ${p.base};
    @define-color view_bg_color ${p.sunken};
    @define-color headerbar_bg_color ${p.surface0};
    @define-color sidebar_bg_color ${p.mantle};
    @define-color card_bg_color ${p.surface0};
    @define-color popover_bg_color ${p.surface0};
    @define-color dialog_bg_color ${p.surface0};
    @define-color accent_bg_color ${p.overlay};
    @define-color accent_color ${p.teal};
    window, .background, .view, headerbar, .titlebar, popover > contents, list, listview, columnview {
      background-color: ${p.base};
      color: ${p.text};
    }
    headerbar, .titlebar, notebook > header { background-color: ${p.surface0}; background-image: none; border-color: ${p.surface1}; }
    .sidebar, .navigation-sidebar { background-color: ${p.mantle}; }
    row:selected, .view:selected { background-color: ${p.surface1}; color: ${p.lamp}; }
    frame, .card, notebook > stack { background-color: ${p.sunken}; border-color: ${p.surface1}; }
  '' + sharedCss;

  # ── btop ────────────────────────────────────────────────────────
  programs.btop.themes.whisper = ''
    theme[main_bg]="${p.base}"
    theme[main_fg]="${p.text}"
    theme[title]="${p.lamp}"
    theme[hi_fg]="${p.teal}"
    theme[selected_bg]="${p.surface1}"
    theme[selected_fg]="${p.lamp}"
    theme[inactive_fg]="${p.overlay}"
    theme[graph_text]="${p.subtext}"
    theme[meter_bg]="${p.surface0}"
    theme[proc_misc]="${p.teal}"
    theme[cpu_box]="${p.overlay}"
    theme[mem_box]="${p.overlay}"
    theme[net_box]="${p.overlay}"
    theme[proc_box]="${p.overlay}"
    theme[div_line]="${p.surface1}"
    theme[temp_start]="${p.teal}"
    theme[temp_mid]="${p.lamp}"
    theme[temp_end]="${p.red}"
    theme[cpu_start]="${p.teal}"
    theme[cpu_mid]="${p.lamp}"
    theme[cpu_end]="${p.red}"
    theme[free_start]="${p.green}"
    theme[free_mid]="${p.teal}"
    theme[free_end]="${p.blue}"
    theme[cached_start]="${p.blue}"
    theme[cached_mid]="${p.teal}"
    theme[cached_end]="${builtins.elemAt t 14}"
    theme[available_start]="${p.lamp}"
    theme[available_mid]="${p.mustard}"
    theme[available_end]="${p.red}"
    theme[used_start]="${p.teal}"
    theme[used_mid]="${p.lamp}"
    theme[used_end]="${p.red}"
    theme[download_start]="${p.blue}"
    theme[download_mid]="${p.teal}"
    theme[download_end]="${p.lamp}"
    theme[upload_start]="${p.green}"
    theme[upload_mid]="${p.lamp}"
    theme[upload_end]="${p.mustard}"
    theme[process_start]="${p.teal}"
    theme[process_mid]="${p.lamp}"
    theme[process_end]="${p.red}"
  '';

  # ── starship prompt colours ─────────────────────────────────────
  programs.starship.settings.palettes.whisper = {
    lamp = p.lamp; teal = p.teal; blue = p.blue;
    subtext = p.subtext; red = p.red; mustard = p.mustard;
  };

  # ── nano (used a lot here): syntax colours, line numbers, palette ──
  xdg.configFile."nano/nanorc".text = ''
    # generated from theme/whisper.nix
    include "${pkgs.nano}/share/nano/*.nanorc"
    set linenumbers
    set autoindent
    set mouse
    set indicator
    set constantshow
    set tabsize 4
    set titlecolor bold,${short p.base},${short p.lamp}
    set promptcolor ${short p.base},${short p.lamp}
    set statuscolor bold,${short p.base},${short p.teal}
    set errorcolor bold,${short p.text},${short p.red}
    set spotlightcolor ${short p.base},${short p.mustard}
    set selectedcolor ${short p.base},${short p.lamp}
    set stripecolor ,${short p.surface0}
    set scrollercolor ${short p.overlay}
    set numbercolor ${short p.overlay}
    set keycolor bold,${short p.lamp}
    set functioncolor ${short p.subtext}
    set minicolor ${short p.base},${short p.teal}
  '';

  # ── satty (draw on screenshots): palette colours ────────────────
  xdg.configFile."satty/config.toml".text = ''
    [general]
    early-exit = true
    initial-tool = "brush"
    copy-command = "wl-copy"
    corner-roundness = 12
    annotation-size-factor = 2

    [font]
    family = "Nunito"
    style = "Bold"

    [color-palette]
    palette = ["${p.lamp}", "${p.teal}", "${p.red}", "${p.mustard}", "${p.green}", "${p.blue}", "${p.text}"]
  '';

  # ── Qt (qt5ct / qt6ct, Fusion tinted into the night) ────────────
  xdg.configFile."qt5ct/colors/whisper.conf".text = qtScheme;
  xdg.configFile."qt6ct/colors/whisper.conf".text = qtScheme;
  xdg.configFile."qt5ct/qt5ct.conf".text = qtConf "qt5ct";
  xdg.configFile."qt6ct/qt6ct.conf".text = qtConf "qt6ct";

  # ── fcitx5 (Chinese input) candidate window ─────────────────────
  xdg.dataFile."fcitx5/themes/whisper/theme.conf".text = ''
    [Metadata]
    Name=whisper
    Version=1
    Author=whisper
    Description=night sky with a streetlamp highlight
    ScaleWithDPI=True

    [InputPanel]
    Font=Nunito 12
    NormalColor=${p.text}
    HighlightCandidateColor=${p.base}
    HighlightColor=${p.lamp}
    HighlightBackgroundColor=${p.lamp}
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
    BorderColor=${p.lamp}
    BorderWidth=2

    [InputPanel/Background/Margin]
    Left=3
    Right=3
    Top=3
    Bottom=3

    [InputPanel/Highlight]
    Color=${p.lamp}

    [InputPanel/Highlight/Margin]
    Left=10
    Right=10
    Top=6
    Bottom=6

    [Menu]
    NormalColor=${p.text}
    HighlightCandidateColor=${p.base}
    Spacing=4

    [Menu/Background]
    Color=${p.base}
    BorderColor=${p.surface1}
    BorderWidth=2

    [Menu/Highlight]
    Color=${p.lamp}

    [Menu/Separator]
    Color=${p.surface1}

    [Menu/ContentMargin]
    Left=4
    Right=4
    Top=4
    Bottom=4
  '';
}
