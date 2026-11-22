# theme/vscode — Eva for VS Code

The VS Code part of the **eva** rice (see the main README).

- `gen.py` builds the extension from `theme/setups/*.json`: a colour theme per
  setup ("Eva Unit-01", "Eva NERV HQ"), the status-bar date, snippets — and
  `eva-workbench.css` from `workbench.css.in`, which `module.nix` appends to
  VS Code's own workbench CSS. That CSS uses `var(--vscode-eva-*)` colours
  (contributed by the extension, set by each theme), so it follows the setup.
- `module.nix` installs the patched VS Code and (re)installs the extension when
  it changes; `eva-switch` sets `workbench.colorTheme` to match the setup.

Build by hand: `nix build --impure --expr '(import ./theme/vscode/default.nix { pkgs = import <nixpkgs> {}; }).extension'`
