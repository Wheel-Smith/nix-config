{ config, lib, isWork, ... }:
let
  home = config.home.homeDirectory;

  # beast: iCloud Drive -> ~/icloud
  icloudLink = ''
    target="${home}/Library/Mobile Documents/com~apple~CloudDocs"
    link="${home}/icloud"

    if [ -e "$target" ]; then
      if [ ! -e "$link" ] && [ ! -L "$link" ]; then
        ln -s "$target" "$link"
      fi
    fi
  '';

  # work: OneDrive for Business -> ~/onedrive
  #
  # macOS puts business OneDrive at ~/Library/CloudStorage/OneDrive-<Tenant>,
  # so the org name is baked into the path. Glob for it rather than hardcoding
  # it, which keeps the employer name out of this public repo.
  #
  # A personal OneDrive, if ever signed in, lands at OneDrive-Personal and is
  # skipped. If more than one business tenant is present the target is
  # ambiguous, so do nothing rather than link an arbitrary one.
  #
  # No bash arrays and no ${"$"}{...} expansions here: activation scripts run
  # under `set -u`, and this stays readable in a Nix '' string.
  onedriveLink = ''
    link="${home}/onedrive"
    target=""
    count=0

    for candidate in "${home}/Library/CloudStorage/"OneDrive-*; do
      [ -d "$candidate" ] || continue
      case "$(basename "$candidate")" in
        OneDrive-Personal) continue ;;
      esac
      target="$candidate"
      count=$((count + 1))
    done

    if [ "$count" -gt 1 ]; then
      echo "links.nix: multiple OneDrive business folders found, skipping $link" >&2
    elif [ "$count" -eq 1 ]; then
      if [ ! -e "$link" ] && [ ! -L "$link" ]; then
        ln -s "$target" "$link"
      fi
    fi
  '';
in
{
  home.activation.cloudSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    if isWork then onedriveLink else icloudLink
  );
}
