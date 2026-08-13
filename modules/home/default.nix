{ inputs, username, isWork, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    # sops-nix's own config block is wrapped in `mkIf (cfg.secrets != {})`, so
    # importing it costs nothing on a host that declares no secrets — no launchd
    # agent, no activation step. That lets both hosts carry the module and only
    # the ones with secrets actually do any work.
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

    # Home modules need the same host context the darwin modules get.
    extraSpecialArgs = { inherit username isWork; };

    users.${username} = import ./user.nix;
  };
}
