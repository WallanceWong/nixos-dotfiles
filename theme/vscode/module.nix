# eva for VS Code: the editor joins the rice.
#  • VS Code itself, with eva's CSS baked into the workbench (UI font, glowing
#    caret, square glass widgets, the NERV crest on the empty editor — in the
#    active theme's colours) and its integrity checksum updated so it doesn't
#    call itself corrupt
#  • the Eva extension (a colour theme per setup, generated from
#    theme/setups/*.json; the date in the status bar), reinstalled whenever it
#    changes. eva-switch picks the theme to match the setup.
{ pkgs, ... }:
let
  eva = (import ./default.nix { inherit pkgs; }).extension;
  evaCss = (import ./default.nix { inherit pkgs; }).css;
  vscode = pkgs.vscode.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      app=$out/lib/vscode/resources/app
      css=$app/out/vs/workbench/workbench.desktop.main.css
      chmod u+w "$css" "$app/product.json"
      cat ${evaCss}/eva-workbench.css >> "$css"
      sum=$(${pkgs.openssl}/bin/openssl dgst -sha256 -binary "$css" | base64 -w0 | tr -d '=')
      ${pkgs.jq}/bin/jq --arg s "$sum" '.checksums["vs/workbench/workbench.desktop.main.css"] = $s' \
        "$app/product.json" > product.json.new
      mv product.json.new "$app/product.json"
    '';
  });
in
{
  environment.systemPackages = [ vscode ];

  home-manager.users.Wallance = { lib, ... }: {
    home.activation.evaVscode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # marketplace extensions the settings rely on (installed once, if missing)
      have=$(${vscode}/bin/code --list-extensions 2>/dev/null | tr 'A-Z' 'a-z')
      for ext in pkief.material-icon-theme usernamehw.errorlens llvm-vs-code-extensions.vscode-clangd \
                 13xforever.language-x86-64-assembly zixuanwang.linkerscript webfreak.debug jnoortheen.nix-ide; do
        echo "$have" | grep -qx "$ext" || run ${vscode}/bin/code --install-extension "$ext" >/dev/null 2>&1 || true
      done

      # the old whisper theme extension goes
      echo "$have" | grep -qx "whisper.whisper" && run ${vscode}/bin/code --uninstall-extension whisper.whisper >/dev/null 2>&1 || true
      rm -f "$HOME/.vscode/extensions/.whisper-build"

      stamp="$HOME/.vscode/extensions/.eva-build"
      if [ "$(cat "$stamp" 2>/dev/null)" != "${eva}" ]; then
        run ${vscode}/bin/code --install-extension ${eva}/eva.vsix --force >"$HOME/.cache/eva-vscode-install.log" 2>&1 \
          && run sh -c 'echo "${eva}" > "$1"' sh "$stamp" || true
      fi
    '';
  };
}
