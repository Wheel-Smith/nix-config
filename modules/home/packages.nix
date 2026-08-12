{ pkgs, isWork, ... }:
let
  common = with pkgs; [
    bat
    btop
    curl
    exiftool
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    gh
    git
    imagemagick
    jq
    just
    lazydocker
    lazygit
    nil
    nixfmt
    pandoc
    starship
    tmux
    tree
    uv
    zoxide
  ];

  # Kept off the work Mac:
  #   nmap, wireshark — port scanning and packet capture on a corporate network
  #                     trip IDS and look indefensible in an audit
  #   tailscale       — a mesh tunnel bypassing corporate network controls
  personalOnly = with pkgs; [
    cmatrix
    nmap
    tailscale
    wireshark
    yt-dlp
  ];
in
{
  home.packages = common ++ (if isWork then [ ] else personalOnly);
}
