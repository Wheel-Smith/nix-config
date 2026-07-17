host := "beast"

# List available recipes (default when you just run `just`)
default:
    @just --list

# Validate the flake evaluates cleanly
check:
    nix flake check

# Preview what would change without activating
build:
    darwin-rebuild build --flake .#{{host}}

# Apply the configuration
switch:
    sudo darwin-rebuild switch --flake .#{{host}}

# First-ever activation on a fresh machine (darwin-rebuild not on PATH yet)
bootstrap-switch:
    sudo nix run nix-darwin -- switch --flake .#{{host}}

# Roll back to the previous generation
rollback:
    sudo darwin-rebuild rollback

# Update all flake inputs and re-lock
update:
    nix flake update

# Update a single input, e.g. `just update-input nixpkgs`
update-input input:
    nix flake update {{input}}

# Update inputs, then switch
upgrade: update switch

# Format all Nix files (requires nixpkgs-fmt / alejandra in your packages)
fmt:
    nix fmt

# Garbage-collect old generations and unreferenced store paths
clean:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

# Show current system generations
generations:
    darwin-rebuild --list-generations
