# nix-macbook

macOS-only nix-darwin configuration for rattatui.

Targets:

- Apple Silicon macOS UTM VM first
- Apple Silicon MacBook later
- Hostname target: beast
- User: rattatui
- Shell: zsh + starship
- Terminal: Ghostty
- Editors: Neovim and VS Code
- GUI apps via Homebrew casks
- CLI tools mostly via Nix/Home Manager
- Secrets intentionally deferred

## First VM bootstrap

Install Nix first, preferably with Determinate Nix Installer:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Restart the shell or reboot if instructed, then:

```bash
cd ~/src/nix-macbook
nix flake check
nix run nix-darwin -- switch --flake .#beast
```

## Common commands

```bash
just check
just build
just switch
just rollback
just update
```

## Notes

- Homebrew cleanup starts as `none` for safety.
- MAS apps require being signed into the App Store.
- Aerospace, Neovim, and Ghostty configs are placeholder modules until user-provided configs are pasted.
