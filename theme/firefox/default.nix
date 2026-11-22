# eva for Firefox — the profile's chrome/ folder, plus one colours file and one
# user.js per setup (setups/<id>.css, setups/<id>.js). The stylesheets in
# config/firefox/chrome are plain CSS using the --eva-* colours; eva-switch
# copies the active setup's files into the profile as chrome/eva-colors.css and
# user.js (copies, not links: Firefox's content sandbox won't follow links out
# of the profile).
#   nix build --impure --expr 'import ./theme/firefox { pkgs = import <nixpkgs> {}; }'
{ pkgs, lib ? pkgs.lib }:

let
  load = id: builtins.fromJSON (builtins.readFile (../setups + "/${id}.json"));
  setups = map load [ "unit01" "magi" ];
  names = [ "crust" "mantle" "base" "sunken" "surface0" "surface1" "surface2" "overlay"
            "subtext" "text" "accent" "accentDim" "armour" "signal" "info" "caution" "alert" ];

  # the new tab page: the painting (UNIT-01) or a command-room grid (NERV HQ)
  newtab = p: if p.id == "magi" then ''
    html {
      background-image:
        radial-gradient(ellipse at 50% 38%, rgba(255,122,26,.10), transparent 60%),
        repeating-linear-gradient(0deg, rgba(255,122,26,.07) 0 1px, transparent 1px 48px),
        repeating-linear-gradient(90deg, rgba(255,122,26,.07) 0 1px, transparent 1px 48px) !important;
      background-size: cover, auto, auto !important;
    }
  '' else ''
    html { background-image: url("eva-newtab-unit01.jpg") !important; }
  '';

  colors = p: ''
    /* ${p.name} — generated from theme/setups/${p.id}.json by theme/firefox */
    :root {
    ${lib.concatMapStrings (n: "  --eva-${n}: ${p.${n}};\n") names}}
    @-moz-document url("about:newtab"), url("about:home"), url("about:privatebrowsing") {
    ${newtab p}
      .logo-and-wordmark .logo, .logo-and-wordmark-wrapper .logo { background-image: url("eva-crest-${p.id}.svg") !important; }
    }
  '';

  # reader view and the PDF viewer follow the setup too
  prefs = p: ''

    // ── ${p.name}: generated from theme/setups/${p.id}.json ──
    user_pref("reader.color_scheme", "custom");
    user_pref("reader.custom_colors.background", "${p.base}");
    user_pref("reader.custom_colors.foreground", "${p.text}");
    user_pref("reader.custom_colors.unvisited-links", "${p.accent}");
    user_pref("reader.custom_colors.visited-links", "${p.armour}");
    user_pref("reader.custom_colors.selection-highlight", "${p.surface2}");
  '';

  crest = p: builtins.replaceStrings [ ''fill="#ffffff"'' ] [ ''fill="${if p.id == "magi" then p.alert else p.accent}"'' ]
    (builtins.readFile ../../config/quickshell/assets/eva/nerv.svg);
in
pkgs.runCommand "eva-firefox" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
  mkdir -p $out/chrome $out/setups
  cp ${../../config/firefox/chrome}/*.css $out/chrome/
  magick ${../../wallpapers/unit01/wall.jpg} -resize 2240x -strip -quality 88 $out/chrome/eva-newtab-unit01.jpg
  ${lib.concatMapStrings (p: ''
    cat > $out/chrome/eva-crest-${p.id}.svg <<'EOF'
    ${crest p}
    EOF
    cat > $out/setups/${p.id}.css <<'EOF'
    ${colors p}
    EOF
    { cat ${../../config/firefox/user.js}; cat <<'EOF'
    ${prefs p}
    EOF
    } > $out/setups/${p.id}.js
  '') setups}
''
