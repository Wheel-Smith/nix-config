{ ... }:
# Stage 1 of the work-Mac rollout: home-manager, shell and packages only.
#
# No system.defaults, no Homebrew, no Dock, no Aerospace, no PAM changes — so
# if this activation fails, the cause is Nix or home-manager itself and not an
# interaction with a config profile. Once `just switch host=work-minimal`
# succeeds, move to `just switch` (which resolves to .#work) for the full
# configuration.
#
# Safe to delete this directory, and the work-minimal output in flake.nix,
# after .#work has activated cleanly.
{
  imports = [
    ../../modules/darwin/nix.nix
    ../../modules/darwin/system.nix
    ../../modules/home
  ];
}
