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
    zoxide
  ];

  # Kept off the work Mac:
  #   nmap, wireshark — port scanning and packet capture on a corporate network
  #                     trip IDS and look indefensible in an audit
  #   tailscale       — a mesh tunnel bypassing corporate network controls
  # tailscale: the daemon is the tailscale-app cask, so `tailscale` execs the
  # CLI bundled in it. The nixpkgs CLI lagged the daemon a release behind and
  # warned on every call. A wrapper rather than a zsh alias, so scripts and
  # agents in non-interactive shells get it too.
  tailscaleAppCli = pkgs.writeShellScriptBin "tailscale" ''
    exec /Applications/Tailscale.app/Contents/MacOS/Tailscale "$@"
  '';

  personalOnly = with pkgs; [
    cmatrix
    nmap
    tailscaleAppCli
    wireshark
    yt-dlp
  ];

  # Cloud tenant work from the terminal. Generic on purpose: this repo is
  # public, and these say nothing about the employer that "uses Azure" does
  # not (docs/work-mac.md, anonymization contract).
  workOnly = with pkgs; [
    azure-cli # az: Resource Graph, Entra, `az rest` for any Graph call
  ];
in
{
  home.packages = common ++ (if isWork then workOnly else personalOnly);
}
