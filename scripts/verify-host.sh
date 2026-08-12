#!/usr/bin/env bash
# Post-switch verification. Asserts that the activation actually produced the
# state the config describes — including, importantly, the things the work host
# is supposed to NOT do.
#
#   ./scripts/verify-host.sh          # detect host from $USER
#   ./scripts/verify-host.sh work     # force a host
#
# Exits non-zero if any check fails.

set -uo pipefail

HOST="${1:-}"
if [ -z "$HOST" ]; then
  case "$(id -un)" in
    rattatui) HOST="beast" ;;
    *) HOST="work" ;;
  esac
fi

pass=0; fail=0; skip=0

ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$1"; pass=$((pass + 1)); }
no()   { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; [ $# -gt 1 ] && printf '        got: %s\n' "$2"; fail=$((fail + 1)); }
sk()   { printf '  \033[33mSKIP\033[0m  %s\n' "$1"; skip=$((skip + 1)); }
info() { printf '  \033[36mINFO\033[0m  %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# expect <description> <expected> <actual>
expect() {
  if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "$3 (want: $2)"; fi
}

# absent <description> <command>
absent() {
  if command -v "$2" >/dev/null 2>&1; then no "$1" "$2 is on PATH"; else ok "$1"; fi
}

present() {
  if command -v "$2" >/dev/null 2>&1; then ok "$1"; else no "$1" "$2 not on PATH"; fi
}

printf '\033[1mVerifying host: %s  (user: %s)\033[0m\n' "$HOST" "$(id -un)"

# ---------------------------------------------------------------------------
head_ "Identity"
# ---------------------------------------------------------------------------
if [ "$HOST" = "work" ]; then
  # Intune owns the name here; nix-darwin issues no scutil --set. Report it
  # rather than asserting, since the expected value is whatever IT chose.
  info "ComputerName:  $(scutil --get ComputerName 2>/dev/null || echo '<unset>')"
  info "LocalHostName: $(scutil --get LocalHostName 2>/dev/null || echo '<unset>')"
  info "HostName:      $(scutil --get HostName 2>/dev/null || echo '<unset — normal, macOS falls back to LocalHostName>')"
else
  expect "ComputerName"  "beast" "$(scutil --get ComputerName 2>/dev/null)"
fi
# Note: users.users.<name>.shell is inert without users.knownUsers, so the login
# shell stays /bin/zsh on both hosts. What actually wires up the environment is
# nix-darwin taking over /etc/zshrc — which it marks by symlinking it into
# /etc/static, not by putting any recognisable string in the file.
if [ -L /etc/zshrc ] && readlink /etc/zshrc | command grep -q '/etc/static/'; then
  ok "nix-darwin manages /etc/zshrc"
else
  no "nix-darwin manages /etc/zshrc" "not a symlink into /etc/static"
fi

# ---------------------------------------------------------------------------
head_ "Things the work host must NOT manage"
# ---------------------------------------------------------------------------
if [ "$HOST" = "work" ]; then
  # We never call socketfilterfw. On a clean VM this reads disabled; on the real
  # managed Mac Intune may well have enabled it, and that is fine and expected —
  # the point is only that WE are not the one setting it.
  info "app firewall: $(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | tail -1)"

  # Our beast values are 30/15. Seeing exactly those on work means the gating
  # leaked.
  sleepv="$(pmset -g custom 2>/dev/null | command awk '/^[[:space:]]*sleep[[:space:]]/ {print $2; exit}')"
  dispv="$(pmset -g custom 2>/dev/null | command awk '/displaysleep/ {print $2; exit}')"
  if [ "$sleepv" = "30" ] && [ "$dispv" = "15" ]; then
    no "power.sleep not applied" "sleep=$sleepv displaysleep=$dispv — matches beast's values"
  else
    ok "power.sleep not applied (sleep=$sleepv displaysleep=$dispv)"
  fi

  # No Raycast here, so Cmd+Space must stay bound to Spotlight.
  if defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null | command grep -qE '^\s+64 =' ; then
    no "Spotlight hotkey untouched" "symbolichotkeys key 64 is present"
  else
    ok "Spotlight hotkey untouched (Cmd+Space still Spotlight)"
  fi

  absent "mas is not installed" mas
  [ -e "$HOME/icloud" ] && no "no ~/icloud on work" "exists" || ok "no ~/icloud on work"
else
  expect "app firewall enabled" "1" \
    "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | command grep -c 'enabled')"
  present "mas is installed" mas
fi

# ---------------------------------------------------------------------------
head_ "Shared ergonomics (should apply on BOTH hosts)"
# ---------------------------------------------------------------------------
expect "accent colour = orange" "1" "$(defaults read -g AppleAccentColor 2>/dev/null)"
expect "tap to click" "1" "$(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null)"
expect "Finder column view" "clmv" "$(defaults read com.apple.finder FXPreferredViewStyle 2>/dev/null)"
expect "screenshot location" "/Users/$(id -un)/Pictures/Screenshots" \
  "$(defaults read com.apple.screencapture location 2>/dev/null)"
# `systemsetup -gettimezone` needs root; the localtime symlink does not.
expect "timezone" "Europe/Tallinn" \
  "$(readlink /etc/localtime 2>/dev/null | command sed 's|.*/zoneinfo/||')"

# fonts.packages is a system-level option, so these land in /Library/Fonts,
# not in home-manager's font directory.
fontcount="$(ls "/Library/Fonts/Nix Fonts" 2>/dev/null | command wc -l | command tr -d ' ')"
[ "${fontcount:-0}" -gt 0 ] && ok "nerd fonts installed ($fontcount entries)" || no "nerd fonts installed" "0 entries"

# The process is called AeroSpace, with a capital S.
if pgrep -qi '^AeroSpace$' 2>/dev/null || pgrep -qi aerospace 2>/dev/null; then
  ok "aerospace is running"
else
  no "aerospace is running" "process not found — check Accessibility permission"
fi

# ---------------------------------------------------------------------------
head_ "Dock"
# ---------------------------------------------------------------------------
# `defaults read` quotes the key too, and emits file:// URLs:
#   "_CFURLString" = "file:///Applications/Ghostty.app";
dockapps="$(defaults read com.apple.dock persistent-apps 2>/dev/null \
  | command grep -o '"_CFURLString" = "[^"]*"' | command sed 's/.*= "\(.*\)"/\1/')"
dockcount="$(printf '%s\n' "$dockapps" | command grep -c '\.app')"
if [ "$HOST" = "work" ]; then
  expect "dock item count" "10" "$dockcount"
  printf '%s' "$dockapps" | command grep -q "Microsoft Teams" \
    && ok "Teams pinned (Intune-installed, referenced not managed)" \
    || no "Teams pinned" "not in dock"
  printf '%s' "$dockapps" | command grep -q "Proton Mail" \
    && no "no personal apps in dock" "Proton Mail present" \
    || ok "no personal apps in dock"
else
  expect "dock item count" "14" "$dockcount"
fi

# ---------------------------------------------------------------------------
head_ "Homebrew"
# ---------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  casks="$(brew list --cask 2>/dev/null | command sort | command tr '\n' ' ')"
  if [ "$HOST" = "work" ]; then
    want="brave-browser caido crystalfetch dbeaver-community firefox ghostty obsidian postman slack spotify utm visual-studio-code vlc "
    expect "cask set matches config" "$want" "$casks"
    for banned in tailscale-app protonvpn rustdesk wireshark-app orbstack raycast claude ollama-app; do
      printf '%s' "$casks" | command grep -qw "$banned" \
        && no "excluded cask absent: $banned" "installed" \
        || ok "excluded cask absent: $banned"
    done
    brew list --formula 2>/dev/null | command grep -qx lazyssh && ok "lazyssh installed" || no "lazyssh installed"
    brew list --formula 2>/dev/null | command grep -qx opencode && no "opencode absent" "installed" || ok "opencode absent"
  else
    info "beast casks: $(printf '%s' "$casks" | command wc -w | command tr -d ' ')"
  fi
else
  sk "brew not on PATH (expected on work-minimal, or open a new shell)"
fi

# ---------------------------------------------------------------------------
head_ "Containers"
# ---------------------------------------------------------------------------
if [ "$HOST" = "work" ]; then
  present "colima installed" colima
  present "docker client installed" docker
  present "docker-compose installed" docker-compose
  plugin="$HOME/.docker/cli-plugins/docker-compose"
  if [ -L "$plugin" ] && readlink "$plugin" | command grep -q '/nix/store'; then
    ok "compose v2 plugin linked"
  else
    no "compose v2 plugin linked" "$plugin is not a /nix/store symlink"
  fi
  if docker compose version >/dev/null 2>&1; then
    ok "\`docker compose\` subcommand resolves"
  else
    no "\`docker compose\` subcommand resolves" "$(docker compose version 2>&1 | head -1)"
  fi
  absent "orbstack absent" orbstack
else
  sk "container checks are work-only"
fi

# ---------------------------------------------------------------------------
head_ "Git identity"
# ---------------------------------------------------------------------------
if [ "$HOST" = "work" ]; then
  expect "useConfigOnly set" "true" "$(git config --get user.useConfigOnly 2>/dev/null)"
  expect "no global email" "" "$(git config --get user.email 2>/dev/null)"

  # A repo outside both trees must refuse to commit.
  t="$(mktemp -d)"; ( cd "$t" && git init -q . && : > f && git add f )
  if ( cd "$t" && git commit -qm test >/dev/null 2>&1 ); then
    no "commit refused outside ~/work and ~/projects" "commit succeeded"
  else
    ok "commit refused outside ~/work and ~/projects"
  fi
  rm -rf "$t"

  # ~/projects must resolve to the personal identity.
  mkdir -p "$HOME/projects/.verify-tmp" && ( cd "$HOME/projects/.verify-tmp" && git init -q . )
  got="$(cd "$HOME/projects/.verify-tmp" && git config --get user.email 2>/dev/null)"
  expect "~/projects uses personal identity" "88578725+Wheel-Smith@users.noreply.github.com" "$got"
  rm -rf "$HOME/projects/.verify-tmp"

  # ~/work needs the hand-created file; absent is a setup step, not a bug.
  if [ -f "$HOME/.config/git/work.inc" ]; then
    mkdir -p "$HOME/work/.verify-tmp" && ( cd "$HOME/work/.verify-tmp" && git init -q . )
    got="$(cd "$HOME/work/.verify-tmp" && git config --get user.email 2>/dev/null)"
    [ -n "$got" ] && ok "~/work uses work identity ($got)" || no "~/work uses work identity" "empty"
    rm -rf "$HOME/work/.verify-tmp"
  else
    sk "~/.config/git/work.inc not created yet (setup step 4)"
  fi
else
  expect "personal identity" "88578725+Wheel-Smith@users.noreply.github.com" "$(git config --get user.email)"
fi

# ---------------------------------------------------------------------------
head_ "SSH and cloud storage"
# ---------------------------------------------------------------------------
if [ "$HOST" = "work" ]; then
  command grep -q 'Include ~/.ssh/config.local' "$HOME/.ssh/config" 2>/dev/null \
    && ok "ssh config includes ~/.ssh/config.local" \
    || no "ssh config includes ~/.ssh/config.local" "Include line missing"
  [ -f "$HOME/.ssh/config.local" ] || sk "~/.ssh/config.local not created yet (setup step 3)"

  if ls -d "$HOME/Library/CloudStorage/"OneDrive-* >/dev/null 2>&1; then
    if [ -L "$HOME/onedrive" ]; then
      ok "~/onedrive -> $(basename "$(readlink "$HOME/onedrive")")"
    else
      no "~/onedrive symlink" "CloudStorage folder exists but no symlink"
    fi
  else
    sk "no OneDrive folder yet — sign in, then re-run \`just switch\`"
  fi
else
  [ -L "$HOME/icloud" ] && ok "~/icloud symlink" || no "~/icloud symlink" "missing"
fi

# ---------------------------------------------------------------------------
head_ "VS Code"
# ---------------------------------------------------------------------------
extdir="$HOME/.vscode/extensions"
if [ "$HOST" = "work" ]; then
  if [ -L "$extdir" ]; then
    no "extensions dir is writable" "it is a symlink (Nix-managed)"
  else
    ok "extensions dir is writable (VS Code manages its own)"
  fi
else
  [ -e "$extdir" ] && ok "extensions dir present" || sk "extensions dir not created yet"
fi
expect "telemetry off" "off" \
  "$(command grep -o '"telemetry.telemetryLevel": *"[^"]*"' "$HOME/Library/Application Support/Code/User/settings.json" 2>/dev/null | command sed 's/.*"\(.*\)"/\1/')"

# ---------------------------------------------------------------------------
printf '\n\033[1m%d passed, %d failed, %d skipped\033[0m\n' "$pass" "$fail" "$skip"
[ "$fail" -eq 0 ]
