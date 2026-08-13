{ lib, isWork, ... }:
{
# ---------------------------------------------------------------------------
# TOP-LEVEL options (NOT under system.defaults) — NEW
# ---------------------------------------------------------------------------

# List choices: sudo systemsetup -listtimezones
  time.timeZone = "Europe/Tallinn";

# Power / sleep timers (backed by `pmset`, values in MINUTES; "never" disables).
# Skipped on the work Mac: idle/display sleep is a compliance control that
# the MDM enforces by profile, and a laxer local value would flag as drift.
  power.sleep = lib.mkIf (!isWork) {
    computer = 30;   # system sleep after 30 min idle
    display = 15;    # display sleep after 15 min idle
    harddisk = 30;   # spin down disks after 30 min
  };

  system.defaults = {
    NSGlobalDomain = {
# Faster-feeling input defaults.
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;

# Reduce some window/app animations.
      NSAutomaticWindowAnimationsEnabled = false;
      NSScrollAnimationEnabled = false;
      NSWindowResizeTime = 1.0e-3; # NEW: near-instant window resize

# Disable automatic text substitutions/corrections.
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

# Trackpad pointer speed. This is the closest declarative equivalent
# to increasing the macOS tracking speed slider by a couple of bars.
      "com.apple.trackpad.scaling" = 2.0;
    };

# Trackpad settings live in trackpad.nix, which owns them outright. They were
# duplicated here, so the two files could disagree about the same key.

    dock = {
# NEW: kill Dock animations.
      autohide-time-modifier = 0.0;
      autohide-delay = 0.0;
      launchanim = false;
      expose-animation-duration = 0.0;
      mineffect = "scale"; # faster than the default "genie"
      showMissionControlGestureEnabled = true;

# Hot corners:
# 1 = disabled, 2 = Mission Control, 3 = Application Windows, 4 = Desktop,
# 5 = Start Screen Saver, 10 = Put Display to Sleep, 11 = Launchpad,
# 12 = Notification Center, 13 = Lock Screen, 14 = Quick Note.
      wvous-tl-corner = 13; # top-left: lock screen
        wvous-tr-corner = 12; # top-right: notification center
        wvous-bl-corner = 11; # bottom-left: launchpad
        wvous-br-corner = 1;  # bottom-right: disabled

# Mission Control: group windows by application.
        expose-group-apps = true;
    };

# NEW: Screen lock — require password immediately after sleep/screensaver.
# Skipped on the work Mac: the MDM profile sets this and always wins, so
# managing it here would be silently dead configuration.
    screensaver = lib.mkIf (!isWork) {
      askForPassword = true;
      askForPasswordDelay = 0; # seconds
    };

# Menu bar clock: show seconds.
    menuExtraClock = {
      ShowSeconds = true;
    };

# Control Center / menu bar battery percentage.
    controlcenter = {
      BatteryShowPercentage = true;
    };

    CustomUserPreferences = {
# NEW: Accent + highlight colour = Orange.
# These are NOT typed nix-darwin options, so they must be written as raw
# keys against the global domain via CustomUserPreferences.
# AppleAccentColor: -1 multicolour, 0 red, 1 orange, 2 yellow,
#                    3 green, 4 blue, 5 purple, 6 pink, 7 graphite.
      "NSGlobalDomain" = {
        AppleAccentColor = 1;
        AppleHighlightColor = "1.000000 0.874510 0.701961 Orange";
      };

# NEW: Keyboard input sources = U.S. + Estonian ONLY (plus the standard
# character-palette input method macOS keeps). IDs captured from this machine
# via: defaults read com.apple.HIToolbox AppleEnabledInputSources
# NOTE: this is a per-user domain; log out/in (or `killall SystemUIServer`)
# for the input menu to refresh after switching.
      "com.apple.HIToolbox" = {
        AppleEnabledInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 0;
            "KeyboardLayout Name" = "U.S.";
          }
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 30764;
            "KeyboardLayout Name" = "Estonian";
          }
          {
            "Bundle ID" = "com.apple.CharacterPaletteIM";
            InputSourceKind = "Non Keyboard Input Method";
          }
        ];
      };

      "com.apple.ActivityMonitor" = {
        OpenMainWindow = true;
        IconType = 5;
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };

      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };

      "com.apple.TimeMachine" = {
        DoNotOfferNewDisksForBackup = true;
      };

      "com.apple.ImageCapture" = {
# Prevent Photos/Image Capture from opening automatically when devices are plugged in.
        disableHotPlug = true;
      };
    }
# CustomUserPreferences is a freeform attrset, not a set of typed options, so
# lib.mkIf inside it would never be evaluated by the module system. Merge with
# optionalAttrs instead.
    // lib.optionalAttrs (!isWork) {
# Unbind Cmd+Space from Spotlight so Raycast can use it.
# Do NOT disable hotkey 65, because that is Option+Cmd+Space
# for Finder search window.
#
# beast-only: the work Mac has no Raycast, so unbinding Cmd+Space there would
# leave the shortcut doing nothing at all.
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "64" = { enabled = false; };
        };
      };
    };
  };
}
