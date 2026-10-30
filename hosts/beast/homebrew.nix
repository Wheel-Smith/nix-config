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
      # "llama.cpp"
      "mole"
      # A formula, not a cask: there is no openconnect cask.
      "openconnect"
      # Kubernetes TUI. The bottle saves a Rust build on every flake update.
      "sofka"
      # uv is a formula, not a nixpkgs package: nixpkgs-unstable is stuck on
      # 0.13.1, and the eMudhra CA incident needs 0.13.4 or newer. Move it back
      # to home.packages once nixpkgs catches up.
      "uv"
      # "opencode"
      # powershell comes from nixpkgs (hosts/beast/packages.nix): the formula
      # drags in a 670 MB dotnet SDK, the nixpkgs build is self-contained.
    ];

    casks = [
      "brave-browser"
      "caido"
      "claude"
      # The @latest channel: new models land there days before the stable
      # `claude-code` cask picks them up.
      "claude-code@latest"
      "codex"
      "crystalfetch"
      "cyberduck"
      "dbeaver-community"
      "excalidrawz"
      "firefox"
      "ghostty"
      # Dropped: unused menu-bar icons are switched off in System Settings →
      # Menu Bar (OmniWM's own Hidden Bar is off, see modules/home/omniwm).
      # "jordanbaird-ice"
      "legcord"
      "libreoffice"
      "localsend"
      "moonlight"
      # Models live in ~/.cache/openwhispr and survive a reinstall.
      "openwhispr"
      # "nordvpn"
      "obsidian"
      "ollama-app"
      "postman"
      "proton-drive"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      # "chang-07/tap/rascal"
      "reminders-menubar"
      "rustdesk"
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
      # Menu bar toolkit; its feature set is declared (see
      # modules/darwin/preferences.nix).
      "vorssaint"
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
