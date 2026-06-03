{ ... }:
{
  programs.ssh = {
    enable = true;

# Avoid relying on Home Manager's deprecated implicit SSH defaults.
    enableDefaultConfig = false;

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

