{ pkgs, lib, ... }:
{
  imports = [
    ./packages.nix
    ./zsh.nix
    ./starship.nix
    ./git.nix
    ./ssh.nix
    ./direnv.nix
    ./tmux.nix
    ./neovim.nix
    ./vscode.nix
    ./ghostty.nix
    ./devtools.nix
    ./files.nix
    ./links.nix
  ];

  home = {
    username = "rattatui";
    homeDirectory = "/Users/rattatui";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
