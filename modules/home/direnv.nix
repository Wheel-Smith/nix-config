{ config, ... }:
{
  programs.direnv = {
    enable = true;
    # The stock integration runs `${pkgs.direnv}/bin/direnv hook zsh`, and the
    # hook it prints calls direnv by that store path. Shells opened before a
    # switch keep the old path, and once GC deletes it every prompt fails with
    # "_direnv_hook:2: no such file or directory". Running direnv from the
    # per-user profile makes the hook embed that stable path instead.
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };

  programs.zsh.initContent = ''
    eval "$(/etc/profiles/per-user/${config.home.username}/bin/direnv hook zsh)"
  '';
}
