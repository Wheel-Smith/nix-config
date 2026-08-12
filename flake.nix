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
    system = "aarch64-darwin";

    # isWork gates everything that differs on an Intune-managed, supervised Mac.
    # The rule: nix-darwin owns ergonomics, MDM owns compliance controls. See
    # docs/work-mac.md for the full boundary and the reasoning behind it.
    #
    # Note that hostName here only names the flake output and hosts/ directory —
    # it is deliberately NOT written to networking.*, because on the work Mac
    # Intune owns the machine name and would fight us over it every check-in.
    #
    # minimal = true also disables nix-homebrew, so a stage-1 activation really
    # is "Nix and home-manager only" — otherwise Homebrew would still be
    # installed and /opt/homebrew taken over, which is exactly the layer the
    # staged rollout is trying to defer.
    mkDarwin = { hostName, username, isWork ? false, minimal ? false }: nix-darwin.lib.darwinSystem {
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
            enable = !minimal;
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
    darwinConfigurations.beast = mkDarwin {
      hostName = "beast";
      username = "rattatui";
    };

    # Intune-managed work Mac. The machine keeps whatever name Intune gave it;
    # "work" is only a flake label.
    darwinConfigurations.work = mkDarwin {
      hostName = "work";
      username = "kristjan";
      isWork = true;
    };

    # Staged-rollout scaffold: home-manager and packages only, zero
    # system.defaults, no Homebrew. Activate this FIRST on the work Mac so a
    # failure is attributable to one layer instead of fifteen modules. Safe to
    # delete once .#work has activated cleanly.
    darwinConfigurations.work-minimal = mkDarwin {
      hostName = "work-minimal";
      username = "kristjan";
      isWork = true;
      minimal = true;
    };
  };
}
