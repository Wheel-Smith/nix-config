{ ... }:
{
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    launchanim = false;
    orientation = "bottom";
    tilesize = 24;

# Remove default folders/items on the right side of the Dock separator
# such as Downloads, recent apps/documents stacks, etc.
    persistent-others = [ ];


# Finder is always pinned by macOS as the first Dock item, so the list
# below starts with the first app after Finder.
    # NOTE: no Launchpad. Apple removed /System/Applications/Launchpad.app in
    # macOS 26; listing it leaves a permanent "?" tile that can never resolve.
    # The bottom-left hot corner (wvous-bl-corner = 11) covers the same need.
    persistent-apps = [
        "/Applications/Brave Browser.app"
        "/System/Applications/Messages.app"
        "/System/Applications/Reminders.app"
        "/System/Applications/System Settings.app"
        "/Applications/Obsidian.app"
        "/Applications/Telegram.app"
        "/Applications/Slack.app"
        "/Applications/WhatsApp.app"
        "/Applications/Ghostty.app"
        "/Applications/Legcord.app"
        "/Applications/Spotify.app"
        "/Applications/Proton Mail.app"
        "/Applications/Tailscale.app"
    ];
  };
}

