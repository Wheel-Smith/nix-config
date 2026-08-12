{ pkgs, lib, isWork, ... }:
# Containers on the work Mac.
#
# OrbStack (beast) and Docker Desktop both require a paid licence for
# commercial use, so neither can go on an employer's machine without one.
# Colima is Apache-2.0 and free, Lima-backed, and drives the same docker CLI —
# so `d`, lazydocker, and the remote-containers / vscode-containers extensions
# all keep working unchanged. Start it with `colima start`.
{
  home.packages = lib.optionals isWork (with pkgs; [
    colima
    docker-client
    docker-compose
  ]);

  # `docker-compose` (the standalone binary) works from PATH, but the
  # `docker compose` subcommand only resolves if the v2 plugin is discoverable
  # in the CLI plugin directory. nixpkgs ships it under libexec; link it in.
  home.file = lib.optionalAttrs isWork {
    ".docker/cli-plugins/docker-compose".source =
      "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";
  };
}
