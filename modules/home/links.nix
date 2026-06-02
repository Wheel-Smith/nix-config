{ config, lib, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.activation.icloudSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${home}/Library/Mobile Documents/com~apple~CloudDocs"
    link="${home}/icloud"

    if [ -e "$target" ]; then
      if [ ! -e "$link" ] && [ ! -L "$link" ]; then
        ln -s "$target" "$link"
      fi
    fi
  '';
}
