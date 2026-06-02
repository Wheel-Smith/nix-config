host := "beast"

check:
    nix flake check

build:
    darwin-rebuild build --flake .#{{host}}

switch:
    sudo darwin-rebuild switch --flake .#{{host}}

bootstrap-switch:
    nix run nix-darwin -- switch --flake .#{{host}}

rollback:
    sudo darwin-rebuild rollback

update:
    nix flake update

clean:
    nix-collect-garbage -d
