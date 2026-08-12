# modules/home/vscode.nix
#
# VS Code: APP comes from the Homebrew cask (working 1.129.1), while
# home-manager manages EXTENSIONS + SETTINGS declaratively.
#
# Why: the nixpkgs `vscode` derivation is currently broken on aarch64-darwin
# for 1.129.x (ripgrep path moved; see NixOS/nixpkgs#543690). Setting
# `package = null` makes home-manager NOT build/install the app, but it still
# writes settings.json and symlinks extensions into ~/.vscode/extensions, which
# the Homebrew-installed VS Code reads.
#
# Requires: keep "visual-studio-code" in modules/darwin/homebrew.nix casks,
# and keep `nixpkgs.config.allowUnfree = true;` (some extensions are unfree).
#
# Some extensions call external binaries that must be on PATH — added in
# modules/home/devtools.nix: nil + nixfmt (nix-ide), shfmt (shell-format).
{ pkgs, isWork, ... }:
let
  # Work host manages no extensions through Nix. Settings below still apply,
  # and the binaries those settings point at (nil, nixfmt, shfmt) still come
  # from devtools.nix.
  nixManagedExtensions = with pkgs.vscode-marketplace; [
    eamodio.gitlens
    georglauterbach.evergruv
    ms-azuretools.vscode-containers
    ms-python.debugpy
    ms-python.python
    ms-python.vscode-pylance
    ms-python.vscode-python-envs
    ms-vscode-remote.remote-containers
    tailscale.vscode-tailscale
    charliermarsh.ruff
    jnoortheen.nix-ide
    redhat.vscode-yaml            # docker-compose, nginx, vault
    tamasfe.even-better-toml      # pyproject.toml, ruff.toml
    timonwong.shellcheck          # bash/zsh linting (binary bundled)
    foxundermoon.shell-format     # sh / Dockerfile / .env formatting (needs shfmt)
  ];
in
{
  programs.vscode = {
    enable = true;

    # Do NOT install the app via Nix — Homebrew owns it. This avoids the broken
    # nixpkgs vscode build. If your home-manager is too old to accept null,
    # use `package = pkgs.emptyDirectory;` instead (same effect).
    package = null;

    # beast: extensions are managed by Nix and VS Code can't add/remove them.
    # work:  Nix manages none, so the directory must stay writable or VS Code
    #        would be left unable to install anything at all.
    mutableExtensionsDir = isWork;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = if isWork then [ ] else nixManagedExtensions;

      userSettings = {
        "editor.formatOnSave" = true;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "telemetry.telemetryLevel" = "off";

        # Ruff as the Python formatter + fix/organise imports on save.
        "[python]" = {
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
            "source.organizeImports" = "explicit";
          };
        };

        # Nix IDE: enable the language server (nil) and formatter (nixfmt).
        # These binaries come from modules/home/devtools.nix.
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixfmt";
      };

      keybindings = [ ];
    };
  };
}
