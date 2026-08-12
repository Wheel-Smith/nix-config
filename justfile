# Which host to build. Detected from the username rather than the hostname,
# because nix-darwin deliberately does not set the hostname on the work Mac
# (Intune owns it), so `scutil --get LocalHostName` would be unpredictable.
#
# Override for the staged rollout: `just host=work-minimal switch`
host := if `id -un` == "rattatui" { "beast" } else { "work" }

# List available recipes (default when you just run `just`)
default:
    @just --list

# Validate the flake evaluates cleanly
check:
    nix flake check

# Preview what would change without activating
build:
    darwin-rebuild build --flake .#{{host}}

# Show what would change (package versions, etc.)
diff:
    nix store diff-closures /run/current-system ./result

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

# Update Homebrew itself and upgrade installed formulae/casks
brew-upgrade:
    brew update
    brew upgrade
    brew upgrade --cask

# Update everything: flake inputs, brew packages, then switch
upgrade: update brew-upgrade switch

# Format all Nix files (requires nixpkgs-fmt / alejandra in your packages)
fmt:
    nix fmt

# Delete generations older than 7 days instead of everything
clean:
    sudo nix-collect-garbage --delete-older-than 7d
    nix-collect-garbage --delete-older-than 7d

# Show current system generations
generations:
    darwin-rebuild --list-generations
