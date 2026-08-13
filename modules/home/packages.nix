{ pkgs, isWork, ... }:
let
  common = with pkgs; [
    curl
    # difftastic + ripgrep back the `diff` and `grep` aliases in zsh.nix. Both
    # were aliased but never declared, so on a clean machine those aliases just
    # errored with "command not found".
    difftastic
    exiftool
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    git
    imagemagick
    jq
    just
    lazydocker
    nil
    nixfmt
    pandoc
    ripgrep
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
