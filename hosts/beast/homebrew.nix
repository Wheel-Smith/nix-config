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
      "legcord"
      # "libreoffice"
      "localsend"
      # "nordvpn"
      "obsidian"
      "ollama-app"
      "orbstack"
      "postman"
      "proton-drive"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      "raycast"
      "rustdesk"
      "shottr"
      "slack"
      "spotify"
      # "stats"
      "tailscale-app"
      "telegram"
      "utm"
      "vanilla"
      "visual-studio-code"
      "vlc"
      "whatsapp"
      "wireshark-app"
    ];

    masApps = {
      "DigiDoc4" = 1370791134;
      "eduVPN" = 1317704208;
    };
  };
}
