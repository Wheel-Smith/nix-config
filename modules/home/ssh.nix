{ lib, isWork, ... }:
{
  programs.ssh = {
    enable = true;

# Avoid relying on Home Manager's deprecated implicit SSH defaults.
    enableDefaultConfig = false;

# The internal work git host is identifying, so its Host block lives in a
# hand-created file outside this repo. Home Manager writes ~/.ssh/config as a
# read-only symlink into the Nix store and puts Include directives at the top,
# which is what SSH's first-match-wins semantics need.
#
# Create it by hand on the work Mac (chmod 600), e.g.:
#
#   Host <internal-host>
#     HostName <internal-host>
#     User git
#     IdentityFile ~/.ssh/id_ed25519_work
#     IdentitiesOnly yes
#
# Generate FRESH keys there — do not copy id_ed25519 from beast. A key on a
# supervised device can be remotely wiped, inspected, or reclaimed, and a
# separate key is revocable in one click without touching anything personal.
    includes = lib.optionals isWork [ "~/.ssh/config.local" ];

# Manage SSH client behavior, but not private keys. Create/import
# ~/.ssh/id_ed25519 manually or from your password manager.
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
        AddKeysToAgent = "yes";

# macOS OpenSSH option: persist passphrases in Keychain when available.
        UseKeychain = "yes";
      };

      "*" = {
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        ForwardAgent = "no";
      };
    };
  };
}

