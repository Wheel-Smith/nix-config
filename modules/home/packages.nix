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
    tectonic # self-contained LaTeX engine, pandoc's --pdf-engine
    wireshark
    yt-dlp
  ];

  # Cloud tenant work from the terminal. Generic on purpose: this repo is
  # public, and these say nothing about the employer that "uses Azure" does
  # not (docs/work-mac.md, anonymization contract).
  workOnly = with pkgs; [
    azure-cli # az: Resource Graph, Entra, `az rest` for any Graph call
    azure-storage-azcopy # bulk copy to/from storage (log exports)
    bicep # read and lint the IaC that deploys cloud resources
    duckdb # SQL over local CSV/JSON/Parquet files
    kubelogin # Entra sign-in for AKS clusters (kubectl credential plugin)
  ];
in
{
  home.packages = common ++ (if isWork then workOnly else personalOnly);
}
