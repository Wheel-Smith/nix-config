{
  description = "rattatui macOS nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

#    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
# Keep Homebrew runtime aligned with pinned homebrew-cask definitions.
# Needed because newer casks such as libreoffice-still use newer
# macOS dependency DSL that older brew runtimes reject.

    nix-homebrew = {
       url = "github:zhaofengli/nix-homebrew";
       inputs.brew-src.url = "github:Homebrew/brew/5.1.14";
     };


    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    xykongTap = {
      url = "github:xykong/homebrew-tap";
      flake = false;
    };

  };

  outputs = inputs@{
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    homebrew-bundle,
    xykongTap,
    ...
  }:
  let
    username = "rattatui";
    system = "aarch64-darwin";
    mkDarwin = hostName: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username hostName; };
      modules = [
        home-manager.darwinModules.home-manager
        nix-homebrew.darwinModules.nix-homebrew
        {
          nixpkgs.hostPlatform = system;
          networking.hostName = hostName;
          networking.localHostName = hostName;
          system.primaryUser = username;

          nix-homebrew = {
            enable = true;
            user = username;
            autoMigrate = true;
            mutableTaps = false;
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
              "xykong/homebrew-tap" = xykongTap;
            };
          };
        }
        ./hosts/${hostName}
      ];
    };
  in {
    darwinConfigurations.beast = mkDarwin "beast";
  };
}
