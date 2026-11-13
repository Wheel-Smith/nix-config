{ config, lib, ... }:
# Isolated CTF lab: its own Colima VM, the `ctf` profile.
#
# The dev container itself (Kali, VPN gateway sidecar, firewall, approval
# daemon) lives in containers/ctf (compose.yaml + devcontainer.json).
# This file only provides the VM boundary it runs inside:
#
#   colima start -p ctf     start the lab VM
#   colima stop -p ctf      stop it
#
# Isolation: unlike `default`/`k8s`, which share ~/projects, this VM sees
# exactly one host directory, ~/ctf/work (read-write). Nothing else on the
# Mac (no ~/projects, ~/.ssh, keychain or sops keys) is reachable from the VM
# or any container in it. The SSH agent is not forwarded (inherited
# forwardAgent = false) and wildcard port forwards are rebound to 127.0.0.1
# by the shared Lima override in containers.nix.
#
# Starting the profile points the docker CLI at it (the colima wrapper in
# containers.nix); `colima stop -p ctf` points docker back at the everyday
# VM. Rebuild from scratch with `colima delete -p ctf --data`, `just switch`,
# then start.
let
  ctfSettings = lib.recursiveUpdate config.services.colima.profiles.default.settings {
    cpu = 4;
    memory = 6; # GiB: Kali tools plus the gateway sidecar
    disk = 60; # GiB, sparse
    # Replaces the inherited ~/projects mount (lists are not merged).
    mounts = [
      { location = "~/ctf/work"; writable = true; }
    ];
  };
in
{
  services.colima.profiles.ctf = {
    isService = false; # on demand
    settings = ctfSettings;
  };

  # The mount point must exist before the VM starts.
  home.file."ctf/work/.keep".text = "";
}
