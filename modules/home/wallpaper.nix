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
  # To switch wallpaper, drop an SVG into ../../wallpapers/ and change this one
  # name. Nothing else here needs touching.
  name = "thinknix-dark";

  # Rendered at 4096x4096 — the source SVG's native size, which keeps it crisp
  # on Retina. Square art on a 16:10 display gets cropped top and bottom by
  # macOS; unnoticeable for a tiling pattern with a centred logo.
  size = 4096;

  source = ../../wallpapers + "/${name}.svg";

  wallpaper = pkgs.runCommand "${name}-wallpaper.png"
    { nativeBuildInputs = [ pkgs.resvg ]; }
    ''
      resvg --width ${toString size} --height ${toString size} ${source} "$out"
    '';

  # A stable path outside the store: macOS records whatever path it is given,
  # and this one survives rebuilds even as the store path behind it changes.
  relPath = ".local/share/wallpapers/${name}.png";
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
