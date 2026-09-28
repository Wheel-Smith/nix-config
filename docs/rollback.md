# Rollback

```bash
darwin-rebuild --list-generations
sudo darwin-rebuild rollback
```

If a Home Manager-managed file conflicts, check `*.backup` files.

## Window manager: back to AeroSpace

OmniWM (`modules/home/omniwm`) replaced AeroSpace, which is kept commented out.
OmniWM refuses to start while AeroSpace runs, so exactly one can be enabled.

1. In `modules/darwin/default.nix`, uncomment `./aerospace.nix` and comment out
   `./skhd.nix` (skhd only exists to give OmniWM letter workspaces; AeroSpace
   binds those itself).
2. In `modules/home/user.nix`, remove `./omniwm`.
3. `just switch`, then grant AeroSpace Accessibility.

Switching back to OmniWM later: nix-darwin only generates its stale-user-agent
cleanup while at least one user agent is still declared. With skhd enabled that
is always true; if AeroSpace's agent ever survives a switch anyway, remove it
by hand, or OmniWM will keep refusing to start:

```bash
launchctl bootout gui/$(id -u)/org.nixos.aerospace
rm ~/Library/LaunchAgents/org.nixos.aerospace.plist
```
