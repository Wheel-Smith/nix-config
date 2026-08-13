{ ... }:
# bat, themed to match everything else.
#
# Managed through programs.bat rather than a bare package so the theme is
# declarative. This matters more than it looks: bat is the MANPAGER (see
# zsh.nix), so it renders every man page — it was the one tool still on stock
# colours while ghostty, btop and neovim were all gruvbox.
#
# `bat --list-themes` for the full set; gruvbox-dark and gruvbox-light are the
# two built-ins.
{
  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
      style = "numbers,changes,header";
    };
  };
}
