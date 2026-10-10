# whisper for VS Code, built from theme/palette.json by gen.py:
#   extension — the .vsix (colour theme + status bar)
#   css       — whisper-workbench.css, patched into VS Code itself (its inputs
#               are only the palette and the CSS template, so changing the
#               extension doesn't rebuild VS Code)
{ pkgs }:
{
  extension = pkgs.runCommand "whisper-vscode" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${./gen.py} ${../palette.json} ${./.} $out
  '';
  css = pkgs.runCommand "whisper-vscode-css" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    mkdir src && cp ${./workbench.css.in} src/workbench.css.in
    python3 ${./gen.py} ${../palette.json} src $out --css-only
  '';
}
