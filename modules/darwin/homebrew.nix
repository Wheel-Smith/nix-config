{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };

    brews = [
      "lazyssh"
      "mole"
      "opencode"
    ];

    casks = [
      "brave-browser"
      "caido"
      "crystalfetch"
      "cyberduck"
      "db-browser-for-sqlite"
      "excalidrawz"
      "firefox"
      "xykong/tap/flux-markdown"
      "ghostty"
      "legcord"
      "libreoffice"
      "localsend"
      "nordvpn"
      "obsidian"
      "ollama-app"
      "orbstack"
      "proton-drive"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      "raycast"
      "rustdesk"
      "shottr"
      "slack"
      "spotify"
      "stats"
      "tailscale-app"
      "telegram"
      "utm"
      "vanilla"
      "visual-studio-code"
      "vlc"
      "whatsapp"
      "wireshark-app"
    ];

#    masApps = {
#      "DigiDoc4" = 1370791134;
#      "eduVPN" = 1317704208;
#      "Perplexity" = 6714467650;
#    };
  };
}
