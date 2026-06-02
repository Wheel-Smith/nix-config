# Bootstrap

## VM-first bootstrap

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Restart shell or reboot if required.

```bash
git clone <repo-url> ~/src/nix-macbook
cd ~/src/nix-macbook
nix flake check
nix run nix-darwin -- switch --flake .#beast
```
