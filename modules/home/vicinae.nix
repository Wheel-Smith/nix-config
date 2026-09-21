{ config, isWork, lib, ... }:

# Vicinae's useful macOS features (launcher, clipboard history, emoji picker,
# calculator, and window switching) are enabled out of the box.  Keep the
# mutable settings file under Vicinae's control so its GUI can write settings,
# while providing a Nix-managed import for future defaults/customisation.
{
  home.file = lib.optionalAttrs (!isWork) {
    ".config/vicinae/nix-base.json".text = ''
      {
        // Nix-managed Vicinae defaults live here.
        // Add documented settings to this file as the setup is customised.
        "global_shortcuts": {
          // Vicinae calls the macOS Command modifier "control" here.
          "toggle": "control+space"
        }
      }
    '';
  };

  home.activation = lib.optionalAttrs (!isWork) {
    initialiseVicinaeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      vicinae_dir="${config.home.homeDirectory}/.config/vicinae"
      vicinae_settings="$vicinae_dir/settings.json"
      mkdir -p "$vicinae_dir"

      # Do not overwrite settings made in Vicinae's GUI.  The import points at
      # the read-only Nix-managed file above; Vicinae's own settings remain
      # writable and survive future nix-darwin switches.
      if [ ! -e "$vicinae_settings" ] && [ ! -L "$vicinae_settings" ]; then
        printf '%s\n' '{"imports":["nix-base.json"]}' > "$vicinae_settings"
        chmod 600 "$vicinae_settings"
      fi
    '';
  };
}
