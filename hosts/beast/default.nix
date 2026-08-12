{ ... }:
# Personal machine. Owns everything about itself, including the settings the
# work host hands over to the MDM.
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
