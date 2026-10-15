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
# Keep the Homebrew RUNTIME at least as new as the homebrew-core and
# homebrew-cask inputs below. Those taps move independently, and formula/cask
# definitions adopt new DSL keywords as they go — an older brew runtime then
# rejects them outright.
#
# This is not theoretical: pinned at 6.0.13 the runtime could not parse
# homebrew-core's `node` ("unknown keyword: :overwrite"), so `opencode`, which
# depends on it, could not be resolved. `brew bundle` exited non-zero, and
# because it runs BEFORE home-manager in the activation script, the whole
# switch aborted — leaving /run/current-system and ~/.zshenv on the previous
# generation while the system profile had already moved forward.
#
# If a `just switch` ever dies in "Homebrew bundle...", check for unreadable
# formulae first and bump this pin before anything else.

    nix-homebrew = {
       url = "github:zhaofengli/nix-homebrew";
       inputs.brew-src.url = "github:Homebrew/brew/6.0.17";
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
