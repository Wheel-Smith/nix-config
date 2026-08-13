{ ... }:
# btop, themed to match the rest of the setup.
#
# Managed through programs.btop rather than just dropping the package in
# home.packages, so the theme is declarative — btop otherwise writes its own
# config on first run and then owns it.
#
# gruvbox_material_dark is picked to match ghostty's "Gruvbox Material Dark";
# btop also ships gruvbox_dark, gruvbox_dark_v2 and gruvbox_light if a different
# shade suits better. Theme names are the filenames in
# $out/share/btop/themes/ without the .theme suffix.
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "gruvbox_material_dark";
      theme_background = false;  # keep terminal transparency/blur
      vim_keys = true;
      update_ms = 1000;
    };
  };
}
