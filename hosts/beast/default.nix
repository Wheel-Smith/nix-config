{ ... }:
# Personal machine. Owns everything about itself, including the settings the
# work host hands over to Intune.
{
  imports = [
    ../../modules/darwin
    ../../modules/darwin/firewall.nix
    ../../modules/darwin/hostname.nix
    ./dock.nix
    ./homebrew.nix
    ./packages.nix
    ../../modules/home
  ];
}
