# Bootstrap

## VM-first bootstrap

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Restart shell or reboot if required.

```bash
git clone https://github.com/Wheel-Smith/nix-config.git ~/projects/nix-config
cd ~/projects/nix-config
nix flake check
./scripts/preflight.sh beast
sudo nix run nix-darwin -- switch --flake .#beast
```

`beast` needs its age key in place first (see `secrets/README.md`); the work
Mac follows [`work-mac.md`](work-mac.md) instead.
