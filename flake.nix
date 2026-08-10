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
       inputs.brew-src.url = "github:Homebrew/brew/6.0.13";
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

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
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
    nix-vscode-extensions,
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
          nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
          nixpkgs.config.allowUnfree = true;
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
            trust = {
              formulae = [];
              casks = [ "xykong/tap/flux-markdown" ];
              commands = [];
              taps = [];
            };
          };
        }
        # Align nix-darwin's homebrew.taps with the taps nix-homebrew manages,
        # so `brew bundle` cleanup doesn't try to untap read-only Nix-store taps.
        ({ config, ... }: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })
        ./hosts/${hostName}
      ];
    };
  in {
    darwinConfigurations.beast = mkDarwin "beast";
  };
}
