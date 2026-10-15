{ config, lib, pkgs, ... }:
# Containers on both Macs: Colima, driven by the plain docker CLI.
#
# OrbStack and Docker Desktop both require a paid licence for commercial
# use, so the work Mac could not have either; beast dropped OrbStack too so
# both hosts behave the same. Colima is Apache-2.0, Lima-backed, and exposes
# an ordinary Docker socket, so `d`, lazydocker, the Dev Containers
# extension and the devcontainer CLI all work unchanged.
#
# On demand: `colima start` before using Docker, `colima stop` after. The
# VM keeps every page of RAM it has touched until it stops (unlike OrbStack,
# which hands unused memory back to macOS), so it does not run at login.
# Its config is the read-only ~/.colima/default/colima.yaml below; after
# changing it, restart (cpu/memory/mounts apply on start; vmType/mountType/
# disk only on a fresh VM, `colima delete` first).
{
  services.colima = {
    enable = true;
    # `colima start` writes its flags back into colima.yaml, which is a
    # read-only Nix file here, so a plain start dies with "permission
    # denied". The wrapper makes every start pass --save-config=false;
    # everything else (completions included) is the stock package.
    package = pkgs.symlinkJoin {
      name = "colima-nix-config";
      paths = [ pkgs.colima ];
      meta.mainProgram = "colima";
      postBuild = ''
        rm $out/bin/colima
        cat > $out/bin/colima <<EOF
        #!${pkgs.runtimeShell}
        if [ "\$1" = start ]; then
          shift
          exec ${lib.getExe pkgs.colima} start --save-config=false "\$@"
        fi
        exec ${lib.getExe pkgs.colima} "\$@"
        EOF
        chmod +x $out/bin/colima
      '';
    };
    profiles.default = {
      isActive = true; # `docker context use colima` on start
      isService = false;
      # Every key of `colima template`, because a missing key is read as its
      # zero value rather than colima's default.
      settings = {
        cpu = 4;
        memory = 4; # GiB: a ceiling the VM grows into and keeps until stopped
        disk = 100; # GiB, sparse
        arch = "host";
        runtime = "docker";
        modelRunner = "docker";
        hostname = "";
        kubernetes = {
          enabled = false; # `colima start --kubernetes` for a k3s cluster
          version = "v1.35.0+k3s1";
          k3sArgs = [ "--disable=traefik" ];
          port = 0;
        };
        autoActivate = true;
        network = {
          address = false;
          mode = "shared";
          interface = "en0";
          preferredRoute = false;
          dns = [ ];
          dnsHosts."host.docker.internal" = "host.lima.internal";
          hostAddresses = false;
          gatewayAddress = "192.168.5.2";
        };
        # Keep the host's SSH agent out of the VM, and so out of every
        # container: dev containers used as AI-agent sandboxes must not be
        # able to sign with your keys.
        forwardAgent = false;
        docker = { };
        # Apple's Virtualization.framework with virtiofs: far faster bind
        # mounts than qemu + sshfs.
        vmType = "vz";
        mountType = "virtiofs";
        # File watchers (dev servers, test runners) see host-side edits.
        mountInotify = true;
        portForwarder = "ssh";
        rosetta = false;
        binfmt = true;
        nestedVirtualization = false;
        cpuType = "host";
        provision = [ ];
        sshConfig = true;
        sshPort = 0;
        # Only ~/projects is shared with the VM, instead of Colima's default
        # of all of ~. A container can bind-mount nothing outside it, so even
        # a compromised container cannot reach ~/.ssh, ~/.config/sops or the
        # keychain. Anything you want to mount must live under ~/projects.
        mounts = [
          { location = "~/projects"; writable = true; }
        ];
        diskImage = "";
        forceDiskImage = false;
        rootDisk = 20;
        env = { };
      };
    };
  };

  home.packages = with pkgs; [
    docker-client
    docker-compose
    docker-buildx
    # ~/.docker/config.json says `credsStore = osxkeychain`; without this
    # helper every `docker pull` fails with "error getting credentials".
    docker-credential-helpers
    # `devcontainer up/exec` without VS Code (e.g. for AI-agent sandboxes).
    devcontainer
  ];

  # The `docker compose` / `docker buildx` subcommands only resolve if the v2
  # plugins are in the CLI plugin directory; nixpkgs ships them under
  # libexec. `force` replaces the symlinks OrbStack left there.
  home.file = {
    # Colima tells Lima to forward every guest port bound to 0.0.0.0
    # (k3s's 6443 and 10250, any `docker run -p`) to 0.0.0.0 on the Mac, so
    # they are reachable from the LAN; the firewall cannot stop it because
    # the listener is Apple-signed /usr/bin/ssh. Lima puts rules from
    # $LIMA_HOME/_config/override.yaml before the instance's own and uses
    # the first match, so this one wins for every profile. It catches only
    # wildcard binds (guestIP 0.0.0.0 implies guestIPMustBeZero; `::` counts
    # too), for TCP and UDP (proto defaults to any); the Docker socket and
    # 127.0.0.1 rules still come from Colima. Applies on the next start.
    # (The *:53 listener from limactl is Lima's "pseudoloopback" forwarder
    # for guest port 53 on 127.0.0.1: it binds 0.0.0.0 because 127.0.0.1:53
    # needs root on macOS, but drops any connection not from loopback.)
    "${config.services.colima.colimaHomeDir}/_lima/_config/override.yaml".text = ''
      portForwards:
        - guestIP: 0.0.0.0
          hostIP: 127.0.0.1
    '';
    ".docker/cli-plugins/docker-compose" = {
      source = "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";
      force = true;
    };
    ".docker/cli-plugins/docker-buildx" = {
      source = "${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx";
      force = true;
    };
  };
}
