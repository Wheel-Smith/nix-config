{ pkgs, lib, config, isWork, ... }:
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

  # keyFile has no default in the home-manager module, so it must be explicit.
  # pathNotInStore: this is a real path on the machine, never copied to /nix.
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # Personal homelab SSH hosts, beast only — the work machine is deliberately
  # not a recipient of secrets/personal.yaml, so it could not decrypt this even
  # if it were declared.
  #
  # These two Host blocks predate this config and were silently lost when
  # home-manager took ownership of ~/.ssh/config; they survived only in
  # ~/.ssh/config.hm-backup until being migrated here.
  #
  # Kept as one blob rather than templated: adding a host should be `just
  # secrets` and nothing else, and the *shape* of an SSH config was never the
  # part worth hiding.
  sops.secrets = lib.optionalAttrs (!isWork) {
    ssh_config = {
      sopsFile = ../../secrets/personal.yaml;
      # 0400 — ssh refuses to read an over-permissive included file.
      mode = "0400";
    };
  };
}
