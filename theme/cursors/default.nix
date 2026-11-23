# eva cursor themes: "Eva-Unit01" (indigo body, lime edge) and "Eva-NERV"
# (black body, orange edge) — the angular HUD arrow and friends, drawn by
# gen.py, built as XCursor themes. Anything not drawn falls back to Bibata.
{ pkgs, lib ? pkgs.lib }:
let
  load = id: builtins.fromJSON (builtins.readFile (../setups + "/${id}.json"));
  theme = name: p: body: edge: pkgs.runCommand "eva-cursor-${name}"
    { nativeBuildInputs = [ pkgs.python3 pkgs.librsvg pkgs.xcursorgen ]; } ''
      mkdir work && cd work
      python3 ${./gen.py} '${body}' '${edge}' '${p.alert}' .
      for f in *.svg; do
        for s in 24 32 48 64; do rsvg-convert -w $s -h $s "$f" -o "''${f%.svg}-$s.png"; done
      done
      d=$out/share/icons/${name}
      mkdir -p $d/cursors
      for c in *.in; do xcursorgen "$c" "$d/cursors/''${c%.in}"; done
      while read -r shape names; do
        for n in $names; do [ -e "$d/cursors/$n" ] || ln -s "$shape" "$d/cursors/$n"; done
      done < aliases.txt
      cat > $d/index.theme <<THEME
      [Icon Theme]
      Name=${name}
      Comment=eva HUD cursors (${p.name})
      Inherits=Bibata-Modern-Ice
      THEME
      cat > $d/cursor.theme <<THEME
      [Icon Theme]
      Inherits=${name}
      THEME
    '';
  u = load "unit01";
  m = load "magi";
in
{
  unit01 = theme "Eva-Unit01" u u.surface1 u.accent;
  magi = theme "Eva-NERV" m m.crust m.accent;
}
