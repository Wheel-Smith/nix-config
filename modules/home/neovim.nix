{ ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };

  # Keep your existing LazyVim-style config managed by Home Manager.
  home.file.".config/nvim" = {
    source = ./config/nvim;
    recursive = true;
  };
}
