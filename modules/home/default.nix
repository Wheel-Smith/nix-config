{ username, isWork, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    # Home modules need the same host context the darwin modules get.
    extraSpecialArgs = { inherit username isWork; };

    users.${username} = import ./user.nix;
  };
}
