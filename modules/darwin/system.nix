{ pkgs, username, hostName, ... }:
{
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  system = {
    # Keep this stable after first successful install; do not casually bump.
    stateVersion = 6;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
      };

    };
  };
}
