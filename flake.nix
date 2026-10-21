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
# The Homebrew RUNTIME must stay at least as new as the homebrew-core and
# homebrew-cask inputs below: formula/cask definitions adopt new DSL keywords
# as they go, and an older brew rejects them outright. A fixed version tag here
# drifted behind twice (6.0.13 could not parse `node`, 6.0.17 not `dotnet`),
# and since `brew bundle` runs BEFORE home-manager in the activation script, an
# unreadable formula can abort the whole switch halfway.
#
# So it tracks brew's master branch: every `nix flake update` moves the runtime
# together with the taps, and homebrew-core's CI tests against master. The
# exact commit is still locked in flake.lock. If a new brew ever breaks the
# switch, pin a release tag here (`github:Homebrew/brew/7.0.9`) until it is
# fixed.

    nix-homebrew = {
       url = "github:zhaofengli/nix-homebrew";
       inputs.brew-src.url = "github:Homebrew/brew";
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

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Kubernetes TUI (a Rust rewrite of k9s), not in nixpkgs. Its own flake
    # ships the package and a home-manager module; beast only, wired in
    # modules/home/default.nix. Built from source against our nixpkgs.
    sofka = {
      url = "github:nklmilojevic/sofka";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # azure-cli depends on python fabric, which nixpkgs marks broken since the
    # invoke 3 bump (https://github.com/fabric/fabric/issues/2376, 2026-10-20), so
    # evaluating the whole system fails. Only azure-cli comes from this pinned
    # revision (the last one where fabric was fine); the rest of nixpkgs keeps
    # upgrading. The rev is in the URL so `nix flake update` never moves it.
    # REMOVE this input and the azure-cli overlay below once nixpkgs builds
    # fabric again (check with `just update-input nixpkgs`, then build).
    nixpkgs-azure.url = "github:NixOS/nixpkgs/f20cd90e28fe0403873f473b29e42662cd86e8c4";
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
    nix-vscode-extensions,
    sops-nix,
    ...
  }:

  let
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
          nixpkgs.overlays = [
            nix-vscode-extensions.overlays.default
            (import ./overlays)
            # See the nixpkgs-azure input: azure-cli from the pinned revision.
            (_final: _prev: {
              azure-cli = inputs.nixpkgs-azure.legacyPackages.${system}.azure-cli;
            })
          ];
          nixpkgs.config.allowUnfree = true;
          system.primaryUser = username;

          nix-homebrew = {
            enable = true;
            user = username;
            autoMigrate = true;
            mutableTaps = false;
            # Homebrew 6.0+ requires this variable during startup, but the
            # nix-homebrew launcher does not export it yet. Keep it pointed at
            # the managed Apple Silicon launcher so activation and `brew`
            # agree on the executable path.
            extraEnv = {
              HOMEBREW_ORIGINAL_BREW_FILE = "/opt/homebrew/bin/brew";
            };
            # No third-party taps. If one is ever added, gate it (and its
            # trust entry) behind `!isWork` unless the work Mac needs it:
            # trust entries are add-only, so removing one later does not
            # revoke it, you would need `brew untrust`.
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };
            trust = {
              formulae = [];
              casks = [];
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
