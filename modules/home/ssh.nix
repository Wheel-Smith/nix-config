{ lib, config, isWork, ... }:
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
#
# On beast the equivalent is sops-managed rather than hand-created: the personal
# homelab hosts live encrypted in secrets/personal.yaml and are decrypted to a
# path under ~/.config/sops-nix at activation. Same reasoning — the hostnames
# are not something to publish — but with no manual file to forget.
    includes =
      lib.optionals isWork [ "~/.ssh/config.local" ]
      ++ lib.optionals (!isWork) [ config.sops.secrets.ssh_config.path ];

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

