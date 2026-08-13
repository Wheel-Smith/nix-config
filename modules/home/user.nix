{ username, ... }:
{
  imports = [
    ./packages.nix
    ./containers.nix
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
    ./wallpaper.nix
    ./secrets.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";

    # Matches beast so both hosts get identical home-manager compatibility
    # behaviour. Do not bump casually.
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
