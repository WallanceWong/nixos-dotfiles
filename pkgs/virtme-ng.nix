# virtme-ng (`vng`): build a kernel and boot it in QEMU in seconds, sharing the
# host's filesystem read-only. Not in nixpkgs yet; packaged from the PyPI wheel.
{ lib, runCommand, python3Packages, fetchPypi, qemu, busybox, virtiofsd, bash }:
let
  # only the busybox binary (for the guest's initramfs) — its applets on PATH
  # would shadow coreutils (ln, cp …) on the host and break vng
  busyboxOnly = runCommand "busybox-binary" { } ''
    mkdir -p $out/bin && ln -s ${busybox}/bin/busybox $out/bin/busybox
  '';
in
python3Packages.buildPythonApplication rec {
  pname = "virtme-ng";
  version = "1.41";
  format = "wheel";
  src = fetchPypi {
    pname = "virtme_ng";
    inherit version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-IDHw8sZ5R4KeAw1msolQrc7zUaF6hFVIO1fSe2JG8tI=";
  };
  dependencies = with python3Packages; [ argcomplete requests setuptools ];
  # NixOS front end: the guest boots the host's / read-only, but NixOS keeps its
  # programs under /run/current-system (a fresh, empty /run in the guest) and
  # virtme's init sets a plain FHS PATH. So map the system in, and give commands
  # run with `vng -- <cmd>` the NixOS PATH.
  postFixup = ''
    mv $out/bin/vng $out/bin/.vng-unwrapped
    cat > $out/bin/vng <<WRAP
    #!${bash}/bin/bash
    sys=\$(readlink -f /run/current-system 2>/dev/null)
    extra=(); [ -n "\$sys" ] && extra=(--rodir="/run/current-system=\$sys")
    path="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/\$USER/bin"
    args=(); cmd=(); seen=0
    for a in "\$@"; do
      if [ \$seen = 1 ]; then cmd+=("\$a"); elif [ "\$a" = -- ]; then seen=1; else args+=("\$a"); fi
    done
    if [ \$seen = 1 ]; then
      exec $out/bin/.vng-unwrapped "\''${extra[@]}" "\''${args[@]}" -- "export PATH=\$path:\\\$PATH; \''${cmd[*]}"
    fi
    exec $out/bin/.vng-unwrapped "\''${extra[@]}" "\$@"
    WRAP
    chmod +x $out/bin/vng
  '';
  makeWrapperArgs = [ "--suffix" "PATH" ":" (lib.makeBinPath [ qemu busyboxOnly virtiofsd ]) ];
  meta = {
    description = "Quickly build and run kernels inside a virtualized snapshot of your live system";
    homepage = "https://github.com/arighi/virtme-ng";
    license = lib.licenses.gpl2Only;
    mainProgram = "vng";
  };
}
