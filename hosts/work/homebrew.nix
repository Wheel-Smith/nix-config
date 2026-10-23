{ ... }:
# Homebrew on the work Mac.
#
# cleanup = "uninstall" is SAFE here even though the machine is managed: brew
# only ever uninstalls what is in its own registry, and apps the MDM deploys as
# .pkg/.dmg into /Applications are invisible to it.
#
# HARD RULE: never add a cask for an app the MDM deploys — the office suite,
# mail and chat clients, cloud storage, the managed browser, the management
# agent, the endpoint security agent, the VPN client. onActivation.upgrade would
# bump it on every switch, the MDM would revert it on every check-in, and the
# two would fight forever.
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    brews = [
      "lazyssh"
      "sofka" # Kubernetes TUI; a formula, not a cask
      # uv is a formula, not a nixpkgs package: nixpkgs-unstable is stuck on
      # 0.13.1, and the eMudhra CA incident needs 0.13.4 or newer. Move it back
      # to home.packages once nixpkgs catches up.
      "uv"
    ];

    casks = [
      "brave-browser"
      "caido"
      "crystalfetch"
      "dbeaver-community"
      "firefox"
      "ghostty"
      # Mac-admin tooling for building and checking configuration profiles:
      # payloads, compliance baselines (mSCP), privacy/TCC (PPPC) grants.
      # Authoring tools only, nothing the MDM deploys or enforces itself.
      "imazing-profile-editor"
      "mace"
      "obsidian"
      "postman"
      "pppc-utility"
      # Read-only Mac inspection: package/app signing, notarization and
      # install scripts before deploying them, persistence and process
      # triage. Nothing here installs a system or network extension, so it
      # cannot collide with the endpoint security agent (which is also why
      # LuLu and BlockBlock are not here).
      "apparency"
      "knockknock"
      "microsoft-remote-help"
      "suspicious-package"
      "taskexplorer"
      # "slack"
      "spotify"
      "utm"
      "vicinae"
      "visual-studio-code"
      "vlc"
      # Menu bar toolkit; its feature set is declared (see
      # modules/darwin/preferences.nix). A plain app: no installer package,
      # helper or system/network extension, signed and notarized.
      "vorssaint"
    ];
  };
}
