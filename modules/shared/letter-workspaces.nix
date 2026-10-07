{ lib, isWork }:
# Letter workspaces: the single source of truth read by BOTH
#   modules/darwin/skhd.nix       — binds Option+<letter> / Option+Shift+<letter>
#   modules/home/omniwm/default.nix — creates the workspaces and app rules
#
# Why two tools: until 0.7.3, OmniWM's own hotkeys reached only workspaces
# 1-9, so skhd forwards each letter key to `omniwmctl`, which can address any
# workspace. OmniWM 0.7.4+ can bind higher workspaces itself (not in its
# defaults; added by hand), so skhd could be dropped, but it works, so it stays.
#
# A plain function returning data (not a module), because a nix-darwin module
# and a home-manager module both import it.
#
# Each letter is an OmniWM workspace with a FIXED number (10 and up),
# labelled with the letter. OmniWM files open windows under the number, not
# the letter, so numbers must never move: give a new letter the next unused
# number, wherever it sits in the list. (Numbering by list position once
# shifted every later letter when D was inserted, and open windows ended up
# under the wrong letters.) Numbers are checked for clashes below.
let
  letters = [
    { letter = "C"; number = 10; apps = [ "com.anthropic.claudefordesktop" "com.microsoft.VSCode" "org.jkiss.dbeaver.core.product" ]; }
    { letter = "D"; number = 11; apps = [ "com.hnc.Discord" "app.legcord.Legcord" ]; }
    # Slack is a cask on beast but admin-deployed on work, so it is installed on
    # both even though only one host's homebrew list mentions it.
    { letter = "S"; number = 12; apps = [ "com.tinyspeck.slackmacgap" ]; }
    { letter = "M"; number = 13; apps = [ "com.spotify.client" ]; }
    { letter = "R"; number = 14; apps = [ "com.apple.reminders" ]; }
    { letter = "T"; number = 15; apps = lib.optionals (!isWork) [ "ru.keepcoder.Telegram" ]; }
  ];
  numbers = map (ws: ws.number) letters;
in
assert lib.assertMsg (lib.length (lib.unique numbers) == lib.length numbers)
  "letter-workspaces: two letters share a workspace number";
assert lib.assertMsg (lib.all (n: n >= 10) numbers)
  "letter-workspaces: numbers below 10 belong to OmniWM's own workspaces 1-9";
# A letter with no apps on this host (Telegram on work) is dropped
# entirely, so its key keeps typing its character instead of opening an empty
# workspace. The fixed numbers mean dropping one never renumbers the others.
map (ws: ws // {
  # The same chords in each tool's own notation. The OmniWM module uses
  # `omniwm` to keep its own bindings off these keys.
  skhd = { switch = "alt - ${lib.toLower ws.letter}"; move = "shift + alt - ${lib.toLower ws.letter}"; };
  omniwm = { switch = "Option+${ws.letter}"; move = "Option+Shift+${ws.letter}"; };
}) (lib.filter (ws: ws.apps != [ ]) letters)
