# VM Testing

```bash
nix flake check
sudo darwin-rebuild switch --flake .#beast
sudo darwin-rebuild switch --flake .#beast
darwin-rebuild --list-generations
sudo darwin-rebuild rollback
sudo darwin-rebuild switch --flake .#beast
```
