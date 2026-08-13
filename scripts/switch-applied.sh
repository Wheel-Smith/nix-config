#!/usr/bin/env bash
# Did the switch that just ran actually finish?
#
# nix-darwin sets the system profile early in activation but only repoints
# /run/current-system as its final step, after Homebrew and home-manager. A
# failure in between therefore leaves the profile advanced while the running
# system does not change — and nothing announces it. You find out later, when a
# newly added session variable, dotfile or package appears to have been ignored.
#
# Two symlink reads, so there is no false-positive case.
#
# Run standalone or via `just switch`, which appends it automatically.

set -uo pipefail

current="$(readlink /run/current-system 2>/dev/null)"
profile="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null)"

if [ -z "$current" ] || [ -z "$profile" ]; then
  printf '\033[31m✗ could not read /run/current-system or the system profile\033[0m\n' >&2
  exit 1
fi

if [ "$current" = "$profile" ]; then
  printf '\033[32m✓ switch fully applied\033[0m  %s\n' "$(basename "$current")"
  exit 0
fi

printf '\033[31m✗ PART-APPLIED SWITCH — activation aborted partway\033[0m\n' >&2
printf '  system profile:  %s\n' "$profile" >&2
printf '  current-system:  %s\n' "$current" >&2
printf '\n' >&2
printf '  The profile advanced but activation did not finish, so home-manager\n' >&2
printf '  and your dotfiles are still on the previous generation.\n' >&2
printf '  Scroll up to the "Homebrew bundle..." step — that is the usual culprit.\n' >&2
printf '  `just verify` will tell you more.\n' >&2
exit 1
