{ config, lib, pkgs, ... }:
# Kubernetes learning setup, beast only (imported from user.nix).
#
# Clusters live in their own Colima VM, the `k8s` profile, so experiments
# never compete with the everyday Docker VM (`default`, containers.nix):
#
#   colima start -p k8s     k3s single-node cluster; kubectl context `colima-k8s`
#   kind create cluster     throwaway (multi-node) clusters, as Docker
#                           containers inside the same VM; context `kind-kind`
#   colima stop -p k8s      hands the RAM back
#
# Rebuilding the VM (k3s version, disk size): `colima delete -p k8s --data`,
# then `just switch`, then start. Without --data the old cluster state survives
# into the new VM. Delete also removes all of ~/.colima/k8s, including the
# Nix-managed colima.yaml; starting without it silently creates a plain
# 2 CPU / 2 GiB Docker VM with no Kubernetes.
#
# Starting the k8s profile also points the docker CLI at it (autoActivate),
# which is what kind needs: it creates its "nodes" through `docker`, and
# images you `docker build` there can go straight into kind with
# `kind load docker-image`. Back to the everyday VM: `docker context use
# colima` (or just stop k8s and `colima start`).
#
# ~/.kube/config is written by Colima and kind and is deliberately NOT
# managed here: contexts come and go with every cluster you create.
let
  # Same keys as the default profile (every key must be present, see
  # containers.nix), with only the differences spelled out.
  k8sSettings = lib.recursiveUpdate config.services.colima.profiles.default.settings {
    cpu = 6;
    memory = 8; # GiB: k3s plus a few kind nodes
    disk = 60; # GiB, sparse
    kubernetes = {
      enabled = true;
      version = "v1.37.1+k3s1"; # match kubectl's minor version (±1 skew)
      # Fixed API port. The default (0) picks a random one on every start,
      # but k3s keeps the old port in its internal kubeconfigs, so the second
      # start crash-loops with "connection refused".
      port = 6443;
    };
  };
in
{
  services.colima.profiles.k8s = {
    isService = false; # on demand, like the default profile
    settings = k8sSettings;
  };

  programs.sofka.enable = true; # k9s-style TUI; package from the sofka flake input

  home.packages = with pkgs; [
    # Core: talk to and inspect clusters.
    kubectl
    kubernetes-helm
    kubectx # kubectx / kubens: switch context and namespace
    stern # tail logs across many pods at once
    kind

    # DevSecOps: scan, lint and enforce. All plain CLIs, no cluster agents.
    kubeconform # validate manifests against the API schemas, offline
    kube-linter # best-practice checks on manifests and Helm charts
    trivy # vulnerabilities and misconfig in images, manifests, clusters
    kubescape # cluster posture against NSA/CISA and CIS benchmarks
    popeye # live cluster hygiene report
    kyverno # policy-as-code CLI (test policies before installing Kyverno)
    cosign # sign and verify images
    syft # SBOMs
    grype # vulnerability scan from an SBOM

    # GitOps, for later: a controller in the cluster syncs it to a Git repo.
    # argocd
    # fluxcd
  ];

  programs.zsh.shellAliases.k = "kubectl";

  # Always show the current context/namespace in the prompt, so a command is
  # never aimed at the wrong cluster. Only appears when a context is set.
  programs.starship.settings.kubernetes.disabled = false;

  programs.vscode.profiles.default.extensions = [
    pkgs.vscode-marketplace.ms-kubernetes-tools.vscode-kubernetes-tools
  ];
}
