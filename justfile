# Which host to build. Detected from the username rather than the hostname,
# because nix-darwin deliberately does not set the hostname on the work Mac
# (the MDM owns it), so `scutil --get LocalHostName` would be unpredictable.
#
# Override with `just host=<name> switch` if you ever need to force one.
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

# Apply the configuration, then confirm the activation actually finished.
#
# The drift check is two symlink reads, so it cannot produce a false positive.
# It exists because activation sets the system profile early but updates
# /run/current-system as its very last step: if a step in between fails (most
# likely `brew bundle`), the two disagree and the switch has silently applied
# only part of itself. That state is otherwise invisible until something
# downstream looks stale days later.
switch:
    sudo darwin-rebuild switch --flake .#{{host}}
    @./scripts/switch-applied.sh

# First-ever activation on a fresh machine (darwin-rebuild not on PATH yet)
bootstrap-switch:
    sudo nix run nix-darwin -- switch --flake .#{{host}}

# NOTE: edits take effect only after `just switch` — sops-nix materialises the
# decrypted copy at activation, not when the file is written.
#
# Edit an encrypted secret ($EDITOR opens plaintext, re-encrypted on save)
secrets file="personal":
    sops secrets/{{file}}.yaml

# Show what a secret currently decrypts to, without editing it
secrets-show file="personal":
    @sops --decrypt secrets/{{file}}.yaml

# Show which keys can decrypt a secret
secrets-keys file="personal":
    @grep -A1 'recipient:' secrets/{{file}}.yaml | grep -o 'age1[0-9a-z]*'

# Check for collisions BEFORE the first switch on a machine that isn't fresh
preflight:
    ./scripts/preflight.sh {{host}}

# Assert the activated system matches the config (run after `just switch`)
verify:
    ./scripts/verify-host.sh {{host}}

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
