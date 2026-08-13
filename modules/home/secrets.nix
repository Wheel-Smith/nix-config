{ pkgs, ... }:
# Secrets tooling. The sops-nix home-manager module itself is wired in
# modules/home/default.nix; this file owns the CLI side and, later, the secret
# declarations.
#
# Stage 2A (now): tools only. Nothing is declared, so the sops-nix module stays
# inert on both hosts and this changes nothing but $PATH.
#
# Key model, for whoever reads this next:
#   - One age identity PER MACHINE at ~/.config/sops/age/keys.txt, created there
#     with `age-keygen` and never copied anywhere. Adding a machine means adding
#     its PUBLIC key to .sops.yaml and running `sops updatekeys` — no private
#     material ever moves between machines.
#   - Plus one offline recovery identity kept in the password manager and on no
#     machine at all, so losing a laptop never means losing the secrets.
#
# Not derived from the SSH key via ssh-to-age, deliberately: ~/.ssh/id_ed25519
# is passphrase-protected, so nothing could decrypt unattended at activation.
# A dedicated age key also survives SSH key rotation.
{
  home.packages = with pkgs; [
    sops        # edit/re-key encrypted files
    age         # age-keygen, and the backend sops uses here
    ssh-to-age  # not used by the key model above, but the usual first thing
                # reached for when debugging why a recipient cannot decrypt
  ];
}
