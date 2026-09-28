{ lib, isWork }:
# Letter workspaces: the single source of truth read by BOTH
#   modules/darwin/skhd.nix       — binds Option+<letter> / Option+Shift+<letter>
#   modules/home/omniwm/default.nix — creates the workspaces and app rules
#
# Why two tools: OmniWM's own hotkeys can reach at most nine workspaces (its
# "switch to workspace N" actions exist for 1-9 only) and cannot run shell
# commands. So OmniWM keeps 1-9 natively, and skhd forwards each letter key to
# `omniwmctl`, which can address any workspace.
#
# A plain function returning data (not a module), because a nix-darwin module
# and a home-manager module both import it.
#
# Each letter becomes an OmniWM workspace numbered from 10 upward in list
# order, labelled with the letter. Appending is safe; reordering renumbers
# the workspaces, which only matters for windows already open.
let
  letters = [
    { letter = "C"; apps = [ "com.anthropic.claudefordesktop" "com.microsoft.VSCode" "org.jkiss.dbeaver.core.product" ]; }
    # Slack is a cask on beast but admin-deployed on work, so it is installed on
    # both even though only one host's homebrew list mentions it.
    { letter = "S"; apps = [ "com.tinyspeck.slackmacgap" ]; }
    { letter = "M"; apps = [ "com.spotify.client" ]; }
    { letter = "R"; apps = [ "com.apple.reminders" ]; }
    # OrbStack is beast-only — the work host uses Colima, which has no GUI.
    { letter = "O"; apps = lib.optionals (!isWork) [ "dev.kdrag0n.MacVirt" ]; }
    { letter = "T"; apps = lib.optionals (!isWork) [ "ru.keepcoder.Telegram" ]; }
  ];
in
# A letter with no apps on this host (OrbStack/Telegram on work) is dropped
# entirely, so its key keeps typing its character instead of opening an empty
# workspace. Such letters sit last, so the others keep their numbers.
lib.imap0 (i: ws: ws // {
  number = 10 + i;
  # The same chords in each tool's own notation. The OmniWM module uses
  # `omniwm` to keep its own bindings off these keys.
  skhd = { switch = "alt - ${lib.toLower ws.letter}"; move = "shift + alt - ${lib.toLower ws.letter}"; };
  omniwm = { switch = "Option+${ws.letter}"; move = "Option+Shift+${ws.letter}"; };
}) (lib.filter (ws: ws.apps != [ ]) letters)
