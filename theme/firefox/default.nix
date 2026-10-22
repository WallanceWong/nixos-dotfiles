# whisper for Firefox — the chrome/ folder and user.js for the profile, built
# from theme/palette.json. The stylesheets themselves are plain CSS in
# config/firefox/chrome and only use the --w-* colours generated here.
#   nix build --impure --expr 'import ./theme/firefox { pkgs = import <nixpkgs> {}; }'
{ pkgs, lib ? pkgs.lib }:

let
  p = builtins.fromJSON (builtins.readFile ../palette.json);
  names = [ "crust" "mantle" "base" "sunken" "surface0" "surface1" "surface2" "overlay"
            "subtext" "text" "lamp" "lampDim" "teal" "blue" "red" "mustard" "green" "violet" ];

  colors = ''
    /* generated from theme/palette.json — edit that instead */
    :root {
    ${lib.concatMapStrings (n: "  --w-${n}: ${p.${n}};\n") names}}
  '';

  # tonight's crescent, the same one VS Code shows on its empty editor
  moon = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160">
    <defs><radialGradient id="g" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="${p.lamp}" stop-opacity=".35"/><stop offset="1" stop-color="${p.lamp}" stop-opacity="0"/></radialGradient>
    <mask id="m"><rect width="160" height="160" fill="white"/><circle cx="98" cy="66" r="34" fill="black"/></mask></defs>
    <circle cx="80" cy="80" r="70" fill="url(#g)"/>
    <circle cx="80" cy="80" r="38" fill="${p.lamp}" mask="url(#m)"/>
    <circle cx="80" cy="80" r="38" fill="none" stroke="${p.subtext}" stroke-opacity=".18"/>
    <circle cx="132" cy="34" r="1.6" fill="${p.text}"/><circle cx="26" cy="46" r="1.2" fill="${p.text}" opacity=".7"/>
    <circle cx="120" cy="128" r="1.1" fill="${p.text}" opacity=".6"/><circle cx="38" cy="120" r="1.5" fill="${p.teal}" opacity=".8"/>
    </svg>
  '';

  # prefs that need the palette: reader view and the PDF viewer
  prefs = ''

    // ── generated from theme/palette.json ──
    user_pref("reader.color_scheme", "custom");
    user_pref("reader.custom_colors.background", "${p.base}");
    user_pref("reader.custom_colors.foreground", "${p.text}");
    user_pref("reader.custom_colors.unvisited-links", "${p.teal}");
    user_pref("reader.custom_colors.visited-links", "${p.violet}");
    user_pref("reader.custom_colors.selection-highlight", "${p.surface2}");
  '';
in
pkgs.runCommand "whisper-firefox" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
  mkdir -p $out/chrome
  cp ${../../config/firefox/chrome}/*.css $out/chrome/
  cat > $out/chrome/whisper-colors.css <<'EOF'
  ${colors}
  EOF
  cat > $out/chrome/whisper-moon.svg <<'EOF'
  ${moon}
  EOF
  # the new tab page sits on the wallpaper (a lighter copy: the original is 6400 px)
  magick ${../../wallpapers/wall.jpg} -resize 2560x1440 -strip -quality 88 $out/chrome/whisper-wall.jpg
  cat ${../../config/firefox/user.js} > $out/user.js
  cat >> $out/user.js <<'EOF'
  ${prefs}
  EOF
''
