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
    inherit (nixpkgs) lib;
    system = "aarch64-darwin";

    # isWork gates everything that differs on an MDM-managed, supervised Mac.
    # The rule: nix-darwin owns ergonomics, MDM owns compliance controls. See
    # docs/work-mac.md for the full boundary and the reasoning behind it.
    #
    # Note that hostName here only names the flake output and hosts/ directory —
    # it is deliberately NOT written to networking.*, because on the work Mac
    # the MDM owns the machine name and would fight us over it every check-in.
    mkDarwin = { hostName, username, isWork ? false }: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username hostName isWork; };
      modules = [
        home-manager.darwinModules.home-manager
        nix-homebrew.darwinModules.nix-homebrew
        {
          nixpkgs.hostPlatform = system;
          nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
          nixpkgs.config.allowUnfree = true;
          system.primaryUser = username;

          nix-homebrew = {
            enable = true;
            user = username;
            autoMigrate = true;
            mutableTaps = false;
            # The xykong tap exists solely for flux-markdown, which is a beast
            # cask. Tapping and trusting a third-party tap on the work Mac for
            # a package it never installs is pure downside: an extra
            # third-party source in Homebrew's trust store, on a corporate
            # device, for zero benefit.
            #
            # Getting this right BEFORE the first work activation matters,
            # because trust entries are add-only — dropping one from this list
            # later does not revoke it, you would need `brew untrust`.
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            } // lib.optionalAttrs (!isWork) {
              "xykong/homebrew-tap" = xykongTap;
            };
            trust = {
              formulae = [];
              casks = lib.optionals (!isWork) [ "xykong/tap/flux-markdown" ];
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
    darwinConfigurations.beast = mkDarwin {
      hostName = "beast";
      username = "rattatui";
    };

    # MDM-managed work Mac. The machine keeps whatever name the MDM gave it;
    # "work" is only a flake label.
    darwinConfigurations.work = mkDarwin {
      hostName = "work";
      username = "kristjan";
      isWork = true;
    };
  };
}
