{ pkgs, ... }:
{
  # Python workflow starts with uv from home.packages.
  # Orbstack and Ollama app are installed via Homebrew casks.
  # opencode remains a Homebrew brew initially.

  # Developer tooling that VS Code extensions call as external binaries:
  home.packages = with pkgs; [
    nil               # Nix language server (VS Code: nix.serverPath = "nil")
    nixfmt-rfc-style  # Nix formatter; provides the `nixfmt` binary
    shfmt             # shell formatter (backs foxundermoon.shell-format)
    # shellcheck bundles its own binary in the extension, so not required here,
    # but adding it makes the CLI available too:
    shellcheck
  ];
}
