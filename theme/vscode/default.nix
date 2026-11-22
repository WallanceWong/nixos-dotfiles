# eva for VS Code, built from theme/setups/*.json by gen.py:
#   extension — the .vsix (a colour theme per setup + the status bar date)
#   css       — eva-workbench.css, patched into VS Code itself (it reads the
#               theme's colours through CSS variables, so it serves both
#               setups; its inputs are only the template and the crest, so
#               changing the extension or a colour doesn't rebuild VS Code)
{ pkgs }:
let
  crest = ../../config/quickshell/assets/eva/nerv.svg;
in
{
  extension = pkgs.runCommand "eva-vscode" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    mkdir src && cp -r ${./.}/. src/ && chmod -R u+w src && cp ${crest} src/nerv.svg
    python3 ${./gen.py} ${../setups} src $out
  '';
  css = pkgs.runCommand "eva-vscode-css" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    mkdir src && cp ${./workbench.css.in} src/workbench.css.in && cp ${crest} src/nerv.svg
    python3 ${./gen.py} ${../setups} src $out --css-only
  '';
}
