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
    ./bat.nix
    ./gh.nix
    ./lazygit.nix
    ./btop.nix
    ./wallpaper.nix
    ./secrets.nix
  ];

  # Darwin defaults to ~/Library/Application Support for app configs, and several
  # home-manager modules branch on this flag to decide where to write. lazygit is
  # the one that bites: it reads $XDG_CONFIG_HOME/lazygit when that variable is
  # set, so without this its config would be written somewhere it never looks.
  #
  # This also provides XDG_CONFIG_HOME itself, which is why zsh.nix no longer
  # sets it by hand — two definitions of the same session variable conflict.
  xdg.enable = true;

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";

    # Matches beast so both hosts get identical home-manager compatibility
    # behaviour. Do not bump casually.
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
