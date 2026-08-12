{ ... }:
# Intune-managed, supervised work Mac (user: kristjan).
#
# Compared to beast this host deliberately does NOT import:
#   modules/darwin/firewall.nix — application firewall, stealth mode, guest login
#   modules/darwin/hostname.nix — Intune owns the machine name
#
# and isWork additionally gates off power.sleep, the screensaver password
# prompt, and the Spotlight hotkey unbind (no Raycast here). See
# docs/work-mac.md.
#
# On the name specifically: with networking.* unset, nix-darwin issues no
# `scutil --set` at all, so the machine keeps whatever Intune's enrollment
# profile gave it — and a later IT rename simply sticks, with no drift between
# their inventory and reality. Which host this is gets decided by which flake
# output you build (`just` picks it from `id -un`), not by the machine's name.
{
  imports = [
    ../../modules/darwin
    ./dock.nix
    ./homebrew.nix
    ./packages.nix
    ../../modules/home
  ];
}
