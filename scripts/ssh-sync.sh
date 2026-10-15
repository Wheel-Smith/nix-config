#!/usr/bin/env bash
# Carry LazySSH's host edits into secrets/personal.yaml before a switch.
#
# On beast, ~/.ssh/config is rendered at activation from the encrypted
# `ssh_config` payload plus fixed defaults (modules/home/secrets.nix). LazySSH
# edits that rendered file in place, so anything it adds, changes or removes
# is overwritten by the next switch. This treats the live file as the truth
# for the Host blocks: it strips the parts the template and Colima add, and if
# what is left differs from the payload, shows the diff and re-encrypts it.
#
# Once the hosts are safely in the payload, it also deletes LazySSH's own
# backups of ~/.ssh/config: they would only duplicate what git now keeps, and
# LazySSH writes a new one on every save.
#
# Run standalone or via `just switch`, which runs it first. It does nothing
# where Home Manager links ~/.ssh/config into the Nix store (the work Mac).

set -euo pipefail

cd "$(dirname "$0")/.."
secret=secrets/personal.yaml
live="$HOME/.ssh/config"

# After a switch the live file is a symlink to the sops-nix rendering, and
# LazySSH may replace it with a regular file or write through it; both count.
case "$(readlink -f "$live" 2>/dev/null)" in
  "" | /nix/store/*) exit 0 ;;
esac
[ -f "$secret" ] || exit 0

# config-<ms>-lazyssh.backup on every save (LazySSH keeps the last 10), plus
# config.original.backup from its first run.
remove_backups() {
  rm -f "$HOME"/.ssh/config-*-lazyssh.backup "$HOME"/.ssh/config.original.backup
}

# One blank line between Host blocks and none at either end, so spacing alone
# (LazySSH appends blocks without a gap) never counts as a change.
normalize() {
  awk 'NF { if (seen && (blank || /^(Host|Match)[[:space:]]/)) print ""
            print; seen = 1; blank = 0; next }
       { blank = 1 }'
}

# Drop what is not part of the payload. Keep these patterns in step with the
# sops template in modules/home/secrets.nix.
host_blocks() {
  awk '
    /^Include .*\/\.colima\/ssh_config$/ { next }  # Colima re-adds it on start
    /^# Git-only host configuration lives in a separate Include so LazySSH$/ { next }
    /^# does not present github\.com as an interactive server\.$/ { next }
    /^Include ~\/\.ssh\/config\.git$/ { next }
    /^Host \*[[:space:]]*$/ { skip = 1; next }
    skip && /^[[:space:]]+[^[:space:]]/ { next }
    { skip = 0; print }
  ' "$live"
}

current="$(sops --decrypt --extract '["ssh_config"]' "$secret" | normalize)"
wanted="$(host_blocks | normalize)"

if [ "$current" = "$wanted" ]; then
  remove_backups
  printf '\033[32m✓ ssh hosts in sync\033[0m  (%s)\n' "$secret"
  exit 0
fi

printf '\033[33m~/.ssh/config has host changes that %s does not:\033[0m\n' "$secret"
diff -u --label "$secret" --label "$live" \
  <(printf '%s\n' "$current") <(printf '%s\n' "$wanted") || true

if [ ! -t 0 ]; then
  printf '\033[31m✗ not a terminal; run `just ssh-sync` to review and save them\033[0m\n' >&2
  exit 1
fi

read -r -p "Save these into $secret? [y/N] " answer
case "$answer" in
  y | Y | yes) ;;
  *)
    printf '\033[31m✗ not saved; a switch now would discard them\033[0m\n' >&2
    exit 1
    ;;
esac

printf '%s\n' "$wanted" | jq -Rs . | sops set --value-stdin "$secret" '["ssh_config"]'
remove_backups
printf '\033[32m✓ saved\033[0m  commit %s to keep it\n' "$secret"
