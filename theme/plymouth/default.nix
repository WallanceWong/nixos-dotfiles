# eva Plymouth theme: the boot splash (and disk-password prompt). Unit-01's
# head is cut from the UNIT-01 wallpaper and pushed into the dark at build
# time; the eye glow, the title line and the sync bar are drawn here too.
{ pkgs }:
let
  # the head in wallpapers/unit01/wall.jpg, and the eye inside that crop
  crop = { x = 1380; y = 80; w = 860; h = 620; };
  eye = { x = 1775 - 1380; y = 390 - 80; };
  barlow = "${pkgs.barlow}/share/fonts/truetype/BarlowCondensed-Bold.ttf";
in
pkgs.runCommand "plymouth-theme-eva" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
  d=$out/share/plymouth/themes/eva
  mkdir -p $d
  # Unit-01 in the dark: desaturated, pushed toward violet, edges faded to black
  magick ${../../wallpapers/unit01/wall.jpg} -crop ${toString crop.w}x${toString crop.h}+${toString crop.x}+${toString crop.y} +repage \
    -modulate 38,35 -fill '#2a1650' -colorize 30 \
    \( -size ${toString crop.w}x${toString crop.h} radial-gradient:white-black -level 0%,58% -evaluate pow 2.6 \) \
    -alpha off -compose CopyOpacity -composite $d/unit01.png
  # the eye: a green glow
  magick -size 160x160 radial-gradient:white-black -evaluate pow 3 -alpha copy -fill '#b6f57a' -colorize 100 \
    \( -size 160x160 radial-gradient:white-black -evaluate pow 14 -alpha copy -fill '#f4ffe8' -colorize 100 \) -compose over -composite $d/eye.png
  magick -size 1000x60 xc:none -font ${barlow} -pointsize 26 -fill '#e8e5e1' -kerning 6 -gravity center \
    -annotate +0+0 'EVANGELION UNIT-01  ·  ACTIVATION' -trim +repage -bordercolor none -border 2 $d/title.png
  magick -size 8x4 xc:'#293a6b' $d/track.png
  magick -size 8x4 gradient:'#9a7fe6'-'#9be34a' -rotate 90 $d/fill.png
  sed -e 's/EYE_X/${toString eye.x}/g' -e 's/EYE_Y/${toString eye.y}/g' ${./eva.script} > $d/eva.script
  cat > $d/eva.plymouth <<PLY
  [Plymouth Theme]
  Name=eva
  Description=Unit-01 activation (boot splash for the eva rice)
  ModuleName=script

  [script]
  ImageDir=$d
  ScriptFile=$d/eva.script
  PLY
''
