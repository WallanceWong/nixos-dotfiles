# whisper for VS Code: the editor joins the rice.
#  • VS Code itself, with whisper's CSS baked into the workbench (UI font,
#    lamp-glow caret, rounded glass widgets, a moon on the empty editor) and
#    its integrity checksum updated so it doesn't call itself corrupt
#  • the Whisper extension (colour theme generated from palette.json, moon +
#    Japanese date in the status bar), reinstalled whenever it changes
{ pkgs, ... }:
let
  whisper = (import ./default.nix { inherit pkgs; }).extension;
  whisperCss = (import ./default.nix { inherit pkgs; }).css;
  vscode = pkgs.vscode.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      app=$out/lib/vscode/resources/app
      css=$app/out/vs/workbench/workbench.desktop.main.css
      chmod u+w "$css" "$app/product.json"
      cat ${whisperCss}/whisper-workbench.css >> "$css"
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
    home.activation.whisperVscode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # marketplace extensions the settings rely on (installed once, if missing)
      have=$(${vscode}/bin/code --list-extensions 2>/dev/null | tr 'A-Z' 'a-z')
      for ext in pkief.material-icon-theme usernamehw.errorlens llvm-vs-code-extensions.vscode-clangd \
                 13xforever.language-x86-64-assembly zixuanwang.linkerscript webfreak.debug jnoortheen.nix-ide; do
        echo "$have" | grep -qx "$ext" || run ${vscode}/bin/code --install-extension "$ext" >/dev/null 2>&1 || true
      done

      stamp="$HOME/.vscode/extensions/.whisper-build"
      if [ "$(cat "$stamp" 2>/dev/null)" != "${whisper}" ]; then
        run ${vscode}/bin/code --install-extension ${whisper}/whisper.vsix --force >"$HOME/.cache/whisper-vscode-install.log" 2>&1 \
          && run sh -c 'echo "${whisper}" > "$1"' sh "$stamp" || true
      fi
    '';
  };
}
