{ pkgs, ... }:
{
  # Python workflow starts with uv, installed as a Homebrew formula (see
  # hosts/*/homebrew.nix).
  # Orbstack and Ollama app are installed via Homebrew casks.
  # opencode remains a Homebrew brew initially.

  # Developer tooling that VS Code extensions call as external binaries:
  home.packages = with pkgs; [
    nil               # Nix language server (VS Code: nix.serverPath = "nil")
    nixfmt
    shfmt             # shell formatter (backs foxundermoon.shell-format)
    # shellcheck bundles its own binary in the extension, so not required here,
    # but adding it makes the CLI available too:
    shellcheck
    # A current `python3` ahead of Apple's /usr/bin/python3, which the Command
    # Line Tools freeze at 3.9.6. Follows nixpkgs' default Python (3.14 today).
    # Projects still pin their own version with uv; this is only the default.
    python3
  ];
}
