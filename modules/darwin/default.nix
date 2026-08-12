{ ... }:
# Darwin modules that are safe and wanted on EVERY host, including the
# Intune-managed work Mac.
#
# Deliberately NOT here:
#   ./firewall.nix   — application firewall / stealth mode / guest login are
#                      compliance controls. On a managed Mac these are enforced
#                      by config profile, and socketfilterfw failing against a
#                      locked setting aborts the whole activation. beast-only.
#   ./hostname.nix   — Intune owns the machine name. beast-only.
#   ./dock.nix       — per-host app list, lives in hosts/<host>/.
#   ./homebrew.nix   — per-host cask list, lives in hosts/<host>/.
#   ./packages.nix   — per-host, lives in hosts/<host>/.
{
  imports = [
    ./nix.nix
    ./system.nix
    ./finder.nix
    ./keyboard.nix
    ./trackpad.nix
    ./preferences.nix
    ./screenshots.nix
    ./aerospace.nix
    ./security.nix
    ./fonts.nix
  ];
}
