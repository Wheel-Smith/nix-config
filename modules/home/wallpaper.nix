{ pkgs, lib, config, isWork, ... }:
# Desktop wallpaper, rendered from SVG at build time. beast only.
#
# macOS cannot use an SVG as a desktop picture — it needs a raster format — so
# resvg rasterises it into the Nix store during the build. Change the SVG, and
# the next `just switch` re-renders and re-applies it.
#
# Why desktoppr and not osascript: the usual
#   osascript -e 'tell application "System Events" to set picture of ...'
# requires TCC *Automation* permission for whatever process runs it, and fails
# with "-1743: Not authorized to send Apple events" from an activation script,
# which runs under launchd and cannot show an approval prompt. desktoppr calls
# NSWorkspace.setDesktopImageURL directly, which needs no such permission.
let
  source = ../../thinknix-dark.svg;

  # The SVG is 4096x4096. Rendering at native size keeps it crisp on Retina;
  # the pattern tiles, so cropping to a 16:10 display is unnoticeable.
  wallpaper = pkgs.runCommand "thinknix-dark-wallpaper.png"
    { nativeBuildInputs = [ pkgs.resvg ]; }
    ''
      resvg --width 4096 --height 4096 ${source} "$out"
    '';

  # A stable path outside the store: macOS records whatever path it is given,
  # and this one survives rebuilds even as the store path behind it changes.
  relPath = ".local/share/wallpapers/thinknix-dark.png";
  absPath = "${config.home.homeDirectory}/${relPath}";
in
{
  home.file = lib.optionalAttrs (!isWork) {
    ${relPath}.source = wallpaper;
  };

  home.packages = lib.optionals (!isWork) [ pkgs.desktoppr ];

  # Re-applied on every activation, so the wallpaper is genuinely declarative:
  # change it by hand and the next switch puts it back.
  home.activation = lib.optionalAttrs (!isWork) {
    setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.desktoppr}/bin/desktoppr "${absPath}" || \
        echo "wallpaper: desktoppr failed — is this a GUI login session?" >&2
    '';
  };
}
