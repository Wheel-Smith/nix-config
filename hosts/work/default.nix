{ ... }:
# Intune-managed, supervised work Mac (user: kristjan).
#
# Compared to beast this host deliberately does NOT import:
#   firewall.nix — application firewall, stealth mode, guest login
#   hostname.nix — Intune owns the machine name
#
# and isWork additionally gates off power.sleep, the screensaver password
# prompt, and the Spotlight hotkey unbind (no Raycast here). See
# docs/work-mac.md.
{
  imports = [
    ../../modules/darwin
    ./dock.nix
    ./homebrew.nix
    ./packages.nix
    ../../modules/home
  ];
}
