{ isWork, ... }:
# Keybindings, gaps, modes and workspace letters are identical on both hosts.
# Only the app -> workspace rules differ, since the two machines run different
# apps.
let
  # Apps that live on both machines get one rule, not two copies to drift apart.
  # A rule for an app that is not installed is a harmless no-op, so this stays
  # shared even where the app is only on one host.
  sharedWindowRules = [
    { "if"."app-id" = "com.brave.Browser"; run = "move-node-to-workspace 1"; }
    { "if"."app-id" = "md.obsidian"; run = "move-node-to-workspace 2"; }
    { "if"."app-id" = "com.mitchellh.ghostty"; run = "move-node-to-workspace 3"; }
    { "if"."app-id" = "com.spotify.client"; run = "move-node-to-workspace 4"; }
    { "if"."app-id" = "com.microsoft.VSCode"; run = "move-node-to-workspace C"; }
    { "if"."app-id" = "org.jkiss.dbeaver.core.product"; run = "move-node-to-workspace D"; }
    { "if"."app-id" = "com.anthropic.claudefordesktop"; run = "move-node-to-workspace V"; }
  ];

  personalWindowRules = [
    { "if"."app-id" = "ai.perplexity.mac"; run = "move-node-to-workspace 2"; }
    { "if"."app-id" = "com.apple.MobileSMS"; run = "move-node-to-workspace 4"; }
    { "if"."app-id" = "net.whatsapp.WhatsApp"; run = "move-node-to-workspace 4"; }
    { "if"."app-id" = "ch.protonmail.desktop"; run = "move-node-to-workspace 5"; }
    { "if"."app-id" = "com.hnc.Discord"; run = "move-node-to-workspace 6"; }
    { "if"."app-id" = "ru.keepcoder.Telegram"; run = "move-node-to-workspace T"; }
  ];

  # The chat client ships under a new bundle id since its 2023 rewrite; the old
  # id is kept so the rule survives either build. Both corporate apps are
  # MDM-deployed, not in our Homebrew list.
  workWindowRules = [
    { "if"."app-id" = "com.microsoft.teams2"; run = "move-node-to-workspace 4"; }
    { "if"."app-id" = "com.microsoft.teams"; run = "move-node-to-workspace 4"; }
    { "if"."app-id" = "com.microsoft.Outlook"; run = "move-node-to-workspace 5"; }
    { "if"."app-id" = "com.tinyspeck.slackmacgap"; run = "move-node-to-workspace S"; }
  ];
in
{
  services.aerospace = {
    enable = true;
    settings = {
      "after-startup-command" = [ ];

      "enable-normalization-flatten-containers" = true;
      "enable-normalization-opposite-orientation-for-nested-containers" = true;

      "accordion-padding" = 30;
      "default-root-container-layout" = "tiles";
      "default-root-container-orientation" = "auto";

      "on-focused-monitor-changed" = [ "move-mouse monitor-lazy-center" ];
      "on-focus-changed" = [ "move-mouse window-lazy-center" ];

      "automatically-unhide-macos-hidden-apps" = false;

      "key-mapping" = {
        preset = "qwerty";
      };

      gaps = {
        inner = {
          horizontal = 5;
          vertical = 5;
        };
        outer = {
          left = 2;
          bottom = 2;
          top = 2;
          right = 2;
        };
      };

      mode = {
        main = {
          binding = {
            "alt-slash" = "layout tiles horizontal vertical";
            "alt-comma" = "layout accordion horizontal vertical";
            "alt-shift-m" = "fullscreen";

            "alt-h" = "focus left";
            "alt-j" = "focus down";
            "alt-k" = "focus up";
            "alt-l" = "focus right";

            "alt-shift-h" = "move left";
            "alt-shift-j" = "move down";
            "alt-shift-k" = "move up";
            "alt-shift-l" = "move right";

            "alt-minus" = "resize smart -50";
            "alt-equal" = "resize smart +50";

            "alt-1" = "workspace 1";
            "alt-2" = "workspace 2";
            "alt-3" = "workspace 3";
            "alt-4" = "workspace 4";
            "alt-5" = "workspace 5";
            "alt-6" = "workspace 6";
            "alt-7" = "workspace 7";
            "alt-8" = "workspace 8";
            "alt-9" = "workspace 9";

            "alt-a" = "workspace A";
            "alt-b" = "workspace B";
            "alt-c" = "workspace C";
            "alt-d" = "workspace D";
            "alt-e" = "workspace E";
            "alt-f" = "workspace F";
            "alt-g" = "workspace G";
            "alt-i" = "workspace I";
            "alt-n" = "workspace N";
            "alt-o" = "workspace O";
            "alt-p" = "workspace P";
            "alt-q" = "workspace Q";
            "alt-r" = "workspace R";
            "alt-s" = "workspace S";
            "alt-t" = "workspace T";
            "alt-u" = "workspace U";
            "alt-v" = "workspace V";
            "alt-w" = "workspace W";
            "alt-x" = "workspace X";
            "alt-y" = "workspace Y";
            "alt-z" = "workspace Z";

            "alt-shift-1" = "move-node-to-workspace --focus-follows-window 1";
            "alt-shift-2" = "move-node-to-workspace --focus-follows-window 2";
            "alt-shift-3" = "move-node-to-workspace --focus-follows-window 3";
            "alt-shift-4" = "move-node-to-workspace --focus-follows-window 4";
            "alt-shift-5" = "move-node-to-workspace --focus-follows-window 5";
            "alt-shift-6" = "move-node-to-workspace --focus-follows-window 6";
            "alt-shift-7" = "move-node-to-workspace --focus-follows-window 7";
            "alt-shift-8" = "move-node-to-workspace --focus-follows-window 8";
            "alt-shift-9" = "move-node-to-workspace --focus-follows-window 9";

            "alt-shift-a" = "move-node-to-workspace --focus-follows-window A";
            "alt-shift-b" = "move-node-to-workspace B";
            "alt-shift-c" = "move-node-to-workspace --focus-follows-window C";
            "alt-shift-d" = "move-node-to-workspace D";
            "alt-shift-e" = "move-node-to-workspace E";
            "alt-shift-f" = "move-node-to-workspace F";
            "alt-shift-g" = "move-node-to-workspace G";
            "alt-shift-i" = "move-node-to-workspace I";
            "alt-shift-n" = "move-node-to-workspace N";
            "alt-shift-o" = "move-node-to-workspace O";
            "alt-shift-p" = "move-node-to-workspace P";
            "alt-shift-q" = "move-node-to-workspace Q";
            "alt-shift-r" = "move-node-to-workspace R";
            "alt-shift-s" = "move-node-to-workspace S";
            "alt-shift-t" = "move-node-to-workspace T";
            "alt-shift-u" = "move-node-to-workspace U";
            "alt-shift-v" = "move-node-to-workspace V";
            "alt-shift-w" = "move-node-to-workspace W";
            "alt-shift-x" = "move-node-to-workspace X";
            "alt-shift-y" = "move-node-to-workspace Y";
            "alt-shift-z" = "move-node-to-workspace Z";

            "alt-tab" = "workspace-back-and-forth";
            "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";

            "alt-shift-semicolon" = "mode service";
          };
        };

        service = {
          binding = {
            esc = [ "reload-config" "mode main" ];
            r = [ "flatten-workspace-tree" "mode main" ];
            f = [ "layout floating tiling" "mode main" ];
            backspace = [ "close-all-windows-but-current" "mode main" ];

            "alt-shift-h" = [ "join-with left" "mode main" ];
            "alt-shift-j" = [ "join-with down" "mode main" ];
            "alt-shift-k" = [ "join-with up" "mode main" ];
            "alt-shift-l" = [ "join-with right" "mode main" ];

            down = "volume down";
            up = "volume up";
            "shift-down" = [ "volume set 0" "mode main" ];
          };
        };
      };

      "on-window-detected" =
        sharedWindowRules
        ++ (if isWork then workWindowRules else personalWindowRules);
    };
  };
}

