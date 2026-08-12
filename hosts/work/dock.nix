{ ... }:
{
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    launchanim = false;
    orientation = "bottom";
    tilesize = 24;

    persistent-others = [ ];

    # Finder is always pinned by macOS as the first Dock item, so the list
    # below starts with the first app after Finder.
    #
    # The corporate apps below are deployed by the MDM, not by us — we only
    # reference their paths. If one is missing on the machine, macOS silently
    # drops that Dock entry, so an unused entry is harmless.
    # NOTE: no Launchpad. Apple removed /System/Applications/Launchpad.app in
    # macOS 26; listing it leaves a permanent "?" tile that can never resolve.
    persistent-apps = [
      "/Applications/Brave Browser.app"
      "/Applications/Microsoft Outlook.app"
      "/Applications/Microsoft Teams.app"
      "/System/Applications/System Settings.app"
      "/Applications/Obsidian.app"
      "/Applications/Slack.app"
      "/Applications/Ghostty.app"
      "/Applications/Visual Studio Code.app"
      "/Applications/Spotify.app"
    ];
  };
}
