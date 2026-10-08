# GRUB Legacy (0.97) boot stages — stage2_eltorito for El Torito CD images, as
# used by older OS tutorials (genisoimage -b boot/grub/stage2_eltorito).
# GRUB Legacy left nixpkgs long ago; these are the files from Debian's
# grub-legacy package, unpacked as-is.
{ stdenvNoCC, fetchurl, dpkg }:
stdenvNoCC.mkDerivation {
  pname = "grub-legacy-stage2";
  version = "0.97-80";   # the last Debian build that still ships the stage files
  src = fetchurl {
    url = "https://deb.debian.org/debian/pool/main/g/grub/grub-legacy_0.97-80_i386.deb";
    hash = "sha256-Rv+r3VSYT046kFSShFE68lGoR9HdOSlneZXdZl3DJJY=";
  };
  nativeBuildInputs = [ dpkg ];
  unpackPhase = "dpkg-deb -x $src deb";
  installPhase = ''
    mkdir -p $out/share/grub
    cp -r deb/usr/lib/grub/i386-pc $out/share/grub/
  '';
  meta.description = "GRUB Legacy boot stages (stage1, stage2, stage2_eltorito) from Debian";
}
