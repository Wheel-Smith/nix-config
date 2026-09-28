{ lib, pkgs, isWork, ... }:
# OmniWM, the successor to modules/darwin/aerospace.nix (kept, commented out of
# modules/darwin/default.nix, so rolling back is one line).
#
# Why this is shaped the way it is: OmniWM REJECTS a partial settings.toml.
# Every section, every key and every hotkey action id must be present, and a
# rejected file silently falls back to built-in defaults. So instead of
# hand-writing the whole schema, we vendor the canonical defaults that OmniWM
# itself writes on first launch (defaults-<version>.toml, captured with
# `just omniwm-capture`) and layer our overrides on top. Overrides are checked
# against that file at eval time, so a typo or a key removed upstream fails
# the build instead of producing a file OmniWM throws away.
#
# Bootstrap / version bump: when there is no defaults file for the running
# OmniWM version, no settings.toml is written at all. OmniWM then writes its
# own defaults on launch; run `just omniwm-capture` and switch again. The
# version only changes when overlays/default.nix is edited, never on a plain
# `nix flake update`, so this state is always one you asked for.
let
  omniwm = pkgs.omniwm;
  defaultsFile = ./defaults-${omniwm.version}.toml;
  haveDefaults = builtins.pathExists defaultsFile;
  defaults = lib.importTOML defaultsFile;

  # Letter workspaces (C, S, M, ...) are defined in
  # modules/shared/letter-workspaces.nix, shared with modules/darwin/skhd.nix:
  # OmniWM's own hotkeys stop at nine workspaces, so skhd binds the letters and
  # OmniWM only has to create the workspaces and route apps to them.
  letterWorkspaces = import ../../shared/letter-workspaces.nix { inherit lib isWork; };
  skhdChords = lib.concatMap (ws: [ ws.omniwm.switch ws.omniwm.move ]) letterWorkspaces;

  # OmniWM stores workspaces by UUID. Derive stable ones from the letter so a
  # switch never churns them.
  uuidFor = seed:
    let h = lib.toUpper (builtins.hashString "sha256" "omniwm-workspace-${seed}"); in
    "${lib.substring 0 8 h}-${lib.substring 8 4 h}-${lib.substring 12 4 h}-${lib.substring 16 4 h}-${lib.substring 20 12 h}";

  rule = bundleId: workspace: { inherit bundleId; assignToWorkspace = workspace; };

  sharedWindowRules = [
    (rule "com.brave.Browser" "1")
    (rule "md.obsidian" "2")
    (rule "com.mitchellh.ghostty" "3")
  ];

  letterWindowRules = lib.concatMap (ws:
    map (app: rule app (toString ws.number)) ws.apps) letterWorkspaces;

  personalWindowRules = [
    (rule "com.apple.MobileSMS" "4")
    (rule "net.whatsapp.WhatsApp" "4")
    (rule "ch.protonmail.desktop" "5")
    (rule "com.hnc.Discord" "6")
    (rule "app.legcord.Legcord" "6")
  ];

  # Both corporate apps are MDM-deployed, not in our Homebrew list. The old
  # Teams bundle id is kept so the rule survives either build.
  workWindowRules = [
    (rule "com.microsoft.teams2" "4")
    (rule "com.microsoft.teams" "4")
    (rule "com.microsoft.Outlook" "5")
  ];

  # Action id -> chord. Anything not listed keeps OmniWM's default binding,
  # unless its default chord is claimed here, in which case it is unassigned.
  # Some of these equal today's defaults; they are listed anyway so a
  # re-captured defaults file from a newer OmniWM cannot move keys we rely on.
  hotkeys = {
    "focus.left" = "Option+H";
    "focus.down" = "Option+J";
    "focus.up" = "Option+K";
    "focus.right" = "Option+L";

    "move.left" = "Option+Shift+H";
    "move.down" = "Option+Shift+J";
    "move.up" = "Option+Shift+K";
    "move.right" = "Option+Shift+L";

    # Closest analogues of AeroSpace's `layout tiles` / `layout accordion`.
    "toggleWorkspaceLayout" = "Option+Slash";
    "toggleColumnTabbed" = "Option+Comma";
    "toggleFocusedWindowFloating" = "Option+Shift+Space";
    # Fills the workspace; does not create a native macOS fullscreen Space.
    "toggleFullscreen" = "Option+F";

    "resizeFocusedWindow.shrink" = "Option+Minus";
    "resizeFocusedWindow.grow" = "Option+Equal";

    # Its default Option+Shift+O belongs to the O workspace now (skhd).
    "toggleOverview" = "Option+Shift+W";

    "workspaceBackAndForth" = "Option+Tab";
    "moveWorkspaceToMonitor.right" = "Option+Shift+Tab";

    # Dwindle. Every tile is a split of its parent, horizontal or vertical.
    # toggleSplit flips the direction of the focused window's split, swapSplit
    # exchanges the two halves. Preselect chooses the side of the focused
    # window where the NEXT window opens (or lands when moved), instead of
    # Dwindle's automatic longest-side choice. Escape cancels it.
    "toggleSplit" = "Option+E";
    "swapSplit" = "Option+Shift+E";
    "preselect.left" = "Control+Option+H";
    "preselect.down" = "Control+Option+J";
    "preselect.up" = "Control+Option+K";
    "preselect.right" = "Control+Option+L";
    "preselectClear" = "Control+Option+Escape";

    # Vicinae is the launcher. The palette's default Control+Option+Space also
    # steals macOS's "select next input source" shortcut.
    "openCommandPalette" = "Unassigned";
    "openMenuAnywhere" = "Unassigned";
  }
  // lib.listToAttrs (lib.concatMap (i: [
    (lib.nameValuePair "switchWorkspace.${toString i}" "Option+${toString (i + 1)}")
    (lib.nameValuePair "moveToWorkspace.${toString i}" "Option+Shift+${toString (i + 1)}")
  ]) (lib.range 0 8));

  orange = { red = 1.0; green = 0.584; blue = 0.0; alpha = 1.0; };

  overrides = {
    general = {
      # Hyprland-style BSP everywhere; Option+/ flips a workspace to Niri.
      defaultLayoutType = "dwindle";
      # Nix owns upgrades (overlays/default.nix); the in-app updater would
      # only nag about a version the store path can never become.
      updateChecksEnabled = false;
      # `omniwmctl` needs this. Local socket only; AeroSpace's CLI was always on.
      ipcEnabled = true;
    };

    gaps = {
      size = 5.0;
      outer = { left = 2.0; right = 2.0; top = 2.0; bottom = 2.0; };
    };

    # Built in, replacing JankyBorders. Orange matches the macOS accent set in
    # preferences.nix (0xffff9500).
    borders = { enabled = true; width = 2.0; color = orange; darkColor = orange; };

    focus.moveMouseToFocusedWindow = true;

    # On a notched display the bar is pushed below the menu bar, where it
    # floats over the top of the focused window. Keep it out of the way:
    # hidden until Control+Command is held (Option would collide with every
    # Option+ hotkey), with the active workspace always named in OmniWM's
    # menu-bar icon instead.
    workspaceBar = {
      revealModifier = "controlCommand";
      hideEmptyWorkspaces = true;
      deduplicateAppIcons = true;
      accentColor = orange;
      inactiveIconOpacity = 0.5;
    };
    statusBar.showWorkspaceName = true;
  };

  # Keys OmniWM accepts but leaves out of its defaults while unset (optional
  # in its schema). Add to this when setting another optional key.
  optionalKeys = [
    "borders.darkColor" "workspaceBar.inactiveIconOpacity" "workspaceBar.accentColor"
  ];

  # Every override path must already exist in OmniWM's own defaults.
  checkKeys = path: base: over:
    lib.mapAttrs (name: value:
      let where = lib.concatStringsSep "." (path ++ [ name ]); in
      if !(base ? ${name}) && lib.elem where optionalKeys then
        value
      else if !(base ? ${name}) then
        throw "omniwm: `${where}` is not a key in ${baseNameOf defaultsFile}"
      else if lib.isAttrs value && lib.isAttrs base.${name} then
        checkKeys (path ++ [ name ]) base.${name} value
      else
        value) over;

  knownHotkeyIds = map (h: h.id) defaults.hotkeys;
  # skhd sees keys before OmniWM does, so an OmniWM binding on a letter chord
  # would silently never fire. Defaults there are unassigned; our own
  # bindings there are an error.
  claimedChords = lib.remove "Unassigned" (lib.attrValues hotkeys) ++ skhdChords;

  mergedHotkeys =
    assert lib.all (id:
      if !(lib.elem id knownHotkeyIds) then
        throw "omniwm: hotkey action `${id}` does not exist in OmniWM ${omniwm.version}"
      else if lib.elem hotkeys.${id} skhdChords then
        throw "omniwm: `${id}` is bound to ${hotkeys.${id}}, which skhd owns for a letter workspace"
      else true
    ) (lib.attrNames hotkeys);
    map (h:
      if hotkeys ? ${h.id} then h // { binding = hotkeys.${h.id}; }
      else if lib.elem (h.binding or "") claimedChords then h // { binding = "Unassigned"; }
      else h) defaults.hotkeys;

  # Upstream pins 6 and 7 to a secondary monitor with emoji labels. Keep every
  # workspace on the main display like AeroSpace did and let each follow
  # defaultLayoutType. Letter workspaces are appended as 10, 11, ...
  onMainFollowingDefaultLayout = {
    layoutType = "default";
    monitorAssignment = { type = "main"; };
  };
  mergedWorkspaces =
    map (ws: removeAttrs ws [ "displayName" ] // onMainFollowingDefaultLayout) defaults.workspaces
    ++ map (ws: onMainFollowingDefaultLayout // {
      id = uuidFor ws.letter;
      name = toString ws.number;
      displayName = ws.letter;
    }) letterWorkspaces;

  settings =
    lib.recursiveUpdate defaults (checkKeys [ ] defaults overrides)
    // {
      hotkeys = mergedHotkeys;
      workspaces = mergedWorkspaces;
      # Upstream's defaults carry compatibility rules (minimum sizes for apps
      # that misbehave when tiled small); keep them and append ours.
      appRules =
        defaults.appRules
        ++ sharedWindowRules
        ++ letterWindowRules
        ++ (if isWork then workWindowRules else personalWindowRules);
    };
in
{
  warnings = lib.optional (!haveDefaults) ''
    omniwm: no ${baseNameOf defaultsFile} captured yet, so no settings.toml is
    written and OmniWM runs on its built-in defaults. Launch it once, then run
    `just omniwm-capture` and switch again to apply this repo's config.
  '';

  programs.omniwm = {
    enable = true;
    package = omniwm;
    settings = if haveDefaults then settings else { };
  };
}
