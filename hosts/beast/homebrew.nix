{ ... }:
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
      "mole"
      # "opencode"
      "powershell"
    ];

    casks = [
      "brave-browser"
      "caido"
      "claude"
      "claude-code"
      "codex"
      "crystalfetch"
      "cyberduck"
      "dbeaver-community"
      "excalidrawz"
      "firefox"
      "xykong/tap/flux-markdown"
      "ghostty"
      # Dropped: unused menu-bar icons are switched off in System Settings →
      # Menu Bar (OmniWM's own Hidden Bar is off, see modules/home/omniwm).
      # "jordanbaird-ice"
      "legcord"
      "libreoffice"
      "localsend"
      "moonlight"
      # "nordvpn"
      "obsidian"
      "ollama-app"
      "orbstack"
      "postman"
      "proton-drive"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      # "chang-07/tap/rascal"
      "reminders-menubar"
      "rustdesk"
      "shottr"
      "slack"
      "spotify"
      # "stats"
      "tailscale-app"
      "telegram"
      "utm"
      # "vanilla"
      "vicinae"
      "visual-studio-code"
      "vlc"
      "whatsapp"
      "wireshark-app"
    ];

    masApps = {
      "DigiDoc4" = 1370791134;
      "eduVPN" = 1317704208;
      # Replaced by OmniWM's "Keep Awake" menu toggle (or `caffeinate -d`).
      # cleanup = "uninstall" removes Mac App Store apps too once dropped here.
      # "Amphetamine" = 937984704;
    };
  };
}
