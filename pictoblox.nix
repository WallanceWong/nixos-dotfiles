{ pkgs, ... }:

let
  version = "9.2.1";

  # The .deb was added to the store manually with:
  #   nix-store --add-fixed sha256 ~/Downloads/PictoBlox-Setup-9.2.1.deb
  src = pkgs.requireFile {
    name = "PictoBlox-Setup-${version}.deb";
    url = "https://thestempedia.com/product/pictoblox/download-pictoblox/";
    hash = "sha256-ve1X8v6zf/C5bDhvJAHpTu2oo3omuIZXoH+NCYl9Bsw=";
  };

  unpacked = pkgs.stdenvNoCC.mkDerivation {
    pname = "pictoblox-unpacked";
    inherit version src;
    nativeBuildInputs = [ pkgs.dpkg ];
    dontUnpack = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p $out
      dpkg-deb --fsys-tarfile $src | tar -x -C $out --no-same-owner --no-same-permissions
      chmod -R u+w $out
    '';
  };

  fhs = pkgs.buildFHSEnv {
    name = "pictoblox";
    targetPkgs = p: with p; [
      gtk3 glib nss nspr dbus at-spi2-atk at-spi2-core atk cups libdrm mesa
      libgbm expat libxkbcommon alsa-lib pango cairo libnotify libsecret
      libuuid libappindicator-gtk3 xdg-utils systemd udev libGL vulkan-loader
      xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext xorg.libXfixes
      xorg.libXrandr xorg.libxcb xorg.libxshmfence xorg.libXScrnSaver xorg.libXtst
      xorg.libXi xorg.libXrender xorg.libXcursor
      gdk-pixbuf fontconfig freetype harfbuzz libpulseaudio pipewire
      zlib stdenv.cc.cc.lib python3 libusb1
    ];
    runScript = "${unpacked}/opt/PictoBlox/pictoblox --no-sandbox --ozone-platform-hint=auto";
  };
in
{
  environment.systemPackages = [
    fhs
    (pkgs.makeDesktopItem {
      name = "pictoblox";
      desktopName = "PictoBlox";
      exec = "pictoblox %U";
      icon = "${unpacked}/usr/share/icons/hicolor/512x512/apps/pictoblox.png";
      startupWMClass = "PictoBlox";
      categories = [ "Education" ];
    })
  ];

  # Serial access to Arduino / ESP32 boards
  users.users.Wallance.extraGroups = [ "dialout" ];
}
