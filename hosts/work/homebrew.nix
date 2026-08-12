{ ... }:
# Homebrew on the work Mac.
#
# cleanup = "uninstall" is SAFE here even though the machine is managed: brew
# only ever uninstalls what is in its own registry, and apps Intune deploys as
# .pkg/.dmg into /Applications are invisible to it.
#
# HARD RULE: never add a cask for an app Intune deploys (Teams, Outlook, Office,
# OneDrive, Edge, Company Portal, Defender, the VPN client). onActivation.upgrade
# would bump it on every switch, Intune would revert it on every check-in, and
# the two would fight forever.
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
