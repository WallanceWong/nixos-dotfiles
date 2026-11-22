# eva folder icons: two small overlay themes over Papirus-Dark that only swap
# the folder colour — violet for UNIT-01 ("Eva-Unit01-Icons"), deep orange for
# NERV HQ ("Eva-NERV-Icons"). eva-switch flips the GTK icon theme between them.
{ pkgs, lib ? pkgs.lib }:
let
  overlay = name: color: let
    papirus = pkgs.papirus-icon-theme.override { inherit color; };
  in pkgs.runCommand "eva-icons-${name}" { } ''
    src=${papirus}/share/icons/Papirus
    d=$out/share/icons/${name}
    dirs=""
    for size in 16x16 22x22 24x24 32x32 48x48 64x64; do
      [ -d "$src/$size/places" ] || continue
      mkdir -p "$d/$size/places"
      # every folder icon (and the user-dir ones), resolved to real files
      for f in "$src/$size/places/"*folder* "$src/$size/places/"user-*; do
        [ -e "$f" ] && cp -L "$f" "$d/$size/places/"
      done
      n=''${size%x*}
      dirs="$dirs$size/places,"
      printf '\n[%s/places]\nContext=Places\nSize=%s\nType=Fixed\n' "$size" "$n" >> sections
    done
    {
      printf '[Icon Theme]\nName=${name}\nComment=eva: Papirus-Dark with ${color} folders\nInherits=Papirus-Dark,breeze-dark,hicolor\n'
      printf 'Directories=%s\n' "''${dirs%,}"
      cat sections
    } > "$d/index.theme"
  '';
in
{
  unit01 = overlay "Eva-Unit01-Icons" "violet";
  magi = overlay "Eva-NERV-Icons" "deeporange";
}
