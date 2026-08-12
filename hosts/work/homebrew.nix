{ ... }:
# Homebrew on the work Mac.
#
# cleanup = "uninstall" is SAFE here even though the machine is managed: brew
# only ever uninstalls what is in its own registry, and apps the MDM deploys as
# .pkg/.dmg into /Applications are invisible to it.
#
# HARD RULE: never add a cask for an app the MDM deploys — the office suite,
# mail and chat clients, cloud storage, the managed browser, the management
# agent, the endpoint security agent, the VPN client. onActivation.upgrade would
# bump it on every switch, the MDM would revert it on every check-in, and the
# two would fight forever.
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    brews = [
      "lazyssh"
    ];

    casks = [
      "brave-browser"
      "caido"
      "crystalfetch"
      "dbeaver-community"
      "firefox"
      "ghostty"
      "obsidian"
      "postman"
      # "slack"
      "spotify"
      "utm"
      "visual-studio-code"
      "vlc"
    ];
  };
}
