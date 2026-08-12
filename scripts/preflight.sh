#!/usr/bin/env bash
# Run BEFORE the first `darwin-rebuild switch` on a machine that is not fresh.
#
# Reports what will collide, and prints the exact commands to clear each one.
# Read-only: it changes nothing.
#
#   ./scripts/preflight.sh          # detect host from $USER
#   ./scripts/preflight.sh work

set -uo pipefail

HOST="${1:-}"
if [ -z "$HOST" ]; then
  case "$(id -un)" in
    rattatui) HOST="beast" ;;
    *) HOST="work" ;;
  esac
fi

blockers=0; conflicts=0

head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()    { printf '  \033[32mOK\033[0m      %s\n' "$1"; }
warn()  { printf '  \033[33mCONFLICT\033[0m %s\n' "$1"; conflicts=$((conflicts + 1)); }
stop()  { printf '  \033[31mBLOCKER\033[0m  %s\n' "$1"; blockers=$((blockers + 1)); }
fix()   { printf '            \033[36m→ %s\033[0m\n' "$1"; }
note()  { printf '  \033[36mNOTE\033[0m    %s\n' "$1"; }

printf '\033[1mPre-flight for host: %s  (user: %s)\033[0m\n' "$HOST" "$(id -un)"

# This script is meant to run on a machine that has never been activated. On one
# that already has, /nix, Homebrew and the /etc backups are all expected, so
# report them as normal rather than as findings.
MANAGED=0
if [ -L /run/current-system ]; then
  MANAGED=1
  printf '\033[36mThis machine is already nix-darwin managed — findings below are\n'
  printf 'reported as expected state rather than as conflicts.\033[0m\n'
fi

# ---------------------------------------------------------------------------
head_ "1. Hard blockers"
# ---------------------------------------------------------------------------
if id -Gn | command grep -qw admin; then
  ok "you are a local admin"
else
  stop "not a local admin — nix-darwin cannot run at all"
fi

# Binary allowlisting is fundamentally incompatible with Nix: every binary in
# /nix/store is unsigned, and there are tens of thousands of them.
if command -v santactl >/dev/null 2>&1 || [ -d /Applications/Santa.app ]; then
  stop "Santa (binary allowlisting) is present — Nix cannot work under lockdown mode"
  fix "santactl status   # if mode is LOCKDOWN, stop here"
else
  ok "no Santa / binary allowlisting detected"
fi

gk="$(spctl --status 2>&1)"
case "$gk" in
  *"assessments enabled"*) ok "Gatekeeper: standard ($gk)" ;;
  *) note "Gatekeeper: $gk" ;;
esac

if [ -e /nix ]; then
  if [ "$MANAGED" = "1" ]; then
    ok "/nix present (expected — machine already managed)"
  else
    warn "/nix already exists — a previous Nix install is present"
    fix "verify it is healthy (nix --version) or uninstall before reinstalling"
  fi
else
  ok "/nix does not exist yet"
fi

# ---------------------------------------------------------------------------
head_ "2. Existing Homebrew"
# ---------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  ninst="$(brew list --formula 2>/dev/null | command wc -l | command tr -d ' ')"
  ncask="$(brew list --cask 2>/dev/null | command wc -l | command tr -d ' ')"
  if [ "$MANAGED" = "1" ]; then
    ok "Homebrew present and Nix-managed ($ninst formulae, $ncask casks)"
  else
    warn "Homebrew is already installed ($ninst formulae, $ncask casks)"
    fix "onActivation.cleanup = \"uninstall\" will REMOVE everything not in the config"
    fix "review first:  brew list --formula && brew list --cask"
    fix "nix-homebrew autoMigrate takes ownership of /opt/homebrew — that part is fine"
  fi
else
  ok "Homebrew not installed — nix-homebrew will install it cleanly"
fi

# ---------------------------------------------------------------------------
head_ "3. Apps that collide with the cask list"
# ---------------------------------------------------------------------------
# `brew install --cask X` aborts if the .app already exists and brew did not
# put it there, which fails brew bundle and therefore the whole switch.
# "cask token|Application bundle name". The token cannot be derived from the app
# name (dbeaver-community ships DBeaver.app), so pair them explicitly. Keep this
# in sync with hosts/<host>/homebrew.nix.
read_pairs() {
  if [ "$HOST" = "work" ]; then
    command cat <<'PAIRS'
brave-browser|Brave Browser
caido|Caido
crystalfetch|CrystalFetch
dbeaver-community|DBeaver
firefox|Firefox
ghostty|Ghostty
obsidian|Obsidian
postman|Postman
spotify|Spotify
utm|UTM
visual-studio-code|Visual Studio Code
vlc|VLC
PAIRS
  else
    command cat <<'PAIRS'
brave-browser|Brave Browser
dbeaver-community|DBeaver
firefox|Firefox
ghostty|Ghostty
obsidian|Obsidian
slack|Slack
spotify|Spotify
visual-studio-code|Visual Studio Code
vlc|VLC
PAIRS
  fi
}

found=0
while IFS='|' read -r token app; do
  [ -z "${app:-}" ] && continue
  [ -e "/Applications/$app.app" ] || continue
  # Anything brew already owns is fine — brew just keeps managing it.
  [ -d "/opt/homebrew/Caskroom/$token" ] && continue
  warn "/Applications/$app.app exists and was not installed by brew (cask: $token)"
  found=$((found + 1))
done <<EOF
$(read_pairs)
EOF

if [ "$found" -eq 0 ]; then
  ok "no app collisions"
else
  fix "delete them before the first switch — brew reinstalls them and takes ownership"
  fix "settings in ~/Library survive, so you lose nothing:"
  fix "  sudo rm -rf '/Applications/<Name>.app'"
fi

# ---------------------------------------------------------------------------
head_ "4. Dotfiles home-manager will take over"
# ---------------------------------------------------------------------------
# backupFileExtension = "hm-backup" moves these aside automatically, so they are
# informational — EXCEPT that an existing .hm-backup makes activation fail.
# Note: home-manager writes ~/.ssh/config as a real 600-mode file rather than a
# store symlink, because SSH refuses a world-readable config. So on an already
# managed machine a plain file here is expected, not a leftover.
for f in .zshrc .zshenv .zprofile .tmux.conf .config/starship.toml \
         .config/ghostty/config .config/git/config .ssh/config; do
  if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && [ "$MANAGED" = "0" ]; then
    note "$f exists — will be moved to $f.hm-backup"
  fi
  if [ -e "$HOME/$f.hm-backup" ]; then
    warn "$f.hm-backup already exists — activation will FAIL"
    fix "rm '$HOME/$f.hm-backup'"
  fi
done

if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && [ "$MANAGED" = "0" ]; then
  note ".config/nvim exists — home-manager will replace it with the repo's config"
fi

# The trap: home-manager writes ~/.config/git/config, but git reads ~/.gitconfig
# LAST, so a leftover ~/.gitconfig silently overrides it — including defeating
# user.useConfigOnly on the work host.
if [ -e "$HOME/.gitconfig" ]; then
  warn "~/.gitconfig exists — git reads it AFTER ~/.config/git/config, so it WINS"
  fix "home-manager does not manage this path, so it will not warn you"
  if [ "$HOST" = "work" ]; then
    fix "a [user] email in it defeats useConfigOnly, the whole point of the design"
  fi
  fix "mv ~/.gitconfig ~/.gitconfig.pre-nix"
else
  ok "no ~/.gitconfig shadowing ~/.config/git/config"
fi

if [ -e "$HOME/.ssh/config" ] && [ "$MANAGED" = "0" ]; then
  note "~/.ssh/config will be replaced by home-manager"
  fix "copy any Host blocks you still need into ~/.ssh/config.local FIRST —"
  fix "otherwise they survive only inside ~/.ssh/config.hm-backup"
fi

# ---------------------------------------------------------------------------
head_ "5. Files nix-darwin takes over"
# ---------------------------------------------------------------------------
# A .before-nix-darwin backup is only a problem when the live file is NOT yet
# nix-darwin's own symlink: that means activation still has to create a backup,
# and it refuses to clobber an existing one. Once /etc/zshrc points into
# /etc/static the leftover is permanent, harmless residue.
for f in /etc/zshrc /etc/bashrc /etc/shells /etc/pam.d/sudo_local; do
  [ -e "$f.before-nix-darwin" ] || continue
  if [ -L "$f" ] && readlink "$f" | command grep -q '/etc/static/'; then
    ok "$(basename "$f") already nix-darwin managed (backup is harmless residue)"
  else
    warn "$f.before-nix-darwin exists but $f is not yet managed — activation will fail"
    fix "sudo rm '$f.before-nix-darwin'   # only if you are sure"
  fi
done

if [ -e /etc/pam.d/sudo_local ] && [ ! -L /etc/pam.d/sudo_local ]; then
  warn "/etc/pam.d/sudo_local exists — IT may manage PAM on this machine"
  fix "inspect it: cat /etc/pam.d/sudo_local"
  fix "if IT put it there, drop security.nix rather than overwrite a security control"
else
  ok "no pre-existing /etc/pam.d/sudo_local"
fi

# ---------------------------------------------------------------------------
head_ "6. Containers"
# ---------------------------------------------------------------------------
if [ -d /Applications/Docker.app ]; then
  warn "Docker Desktop is installed — conflicts with Colima over the docker CLI and socket"
  fix "it also needs a paid licence for commercial use; uninstall it"
elif [ -d /Applications/OrbStack.app ] && [ "$HOST" = "work" ]; then
  warn "OrbStack is installed — commercial use requires a paid licence"
else
  ok "no conflicting container runtime"
fi

if [ -e "$HOME/.docker/cli-plugins/docker-compose" ] && [ ! -L "$HOME/.docker/cli-plugins/docker-compose" ]; then
  note "~/.docker/cli-plugins/docker-compose exists — will be backed up as .hm-backup"
fi

# ---------------------------------------------------------------------------
head_ "7. MDM surface (informational)"
# ---------------------------------------------------------------------------
if [ -d "/Library/Managed Preferences" ]; then
  n="$(ls "/Library/Managed Preferences" 2>/dev/null | command wc -l | command tr -d ' ')"
  note "$n managed preference domains present:"
  ls "/Library/Managed Preferences" 2>/dev/null | command sed 's/^/            /'
  note "any system.defaults we write for these domains will lose silently"
else
  ok "no managed preferences"
fi

if [ -d /Applications/Santa.app ] || [ -d "/Applications/Microsoft Defender.app" ]; then
  note "endpoint agent present — expect slow builds until /nix is excluded"
fi

# ---------------------------------------------------------------------------
printf '\n\033[1m%d blockers, %d conflicts to clear\033[0m\n' "$blockers" "$conflicts"
if [ "$blockers" -gt 0 ]; then
  printf '\033[31mDo not proceed until blockers are resolved.\033[0m\n'
elif [ "$conflicts" -gt 0 ]; then
  printf '\033[33mClear the conflicts above, re-run, then switch.\033[0m\n'
else
  printf '\033[32mClear to proceed.\033[0m\n'
fi
[ "$blockers" -eq 0 ]
