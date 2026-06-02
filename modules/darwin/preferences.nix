{ ... }:
{
  system.defaults = {
    NSGlobalDomain = {
# Faster-feeling input defaults.
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;

# Reduce some window/app animations.
      NSAutomaticWindowAnimationsEnabled = false;
      NSScrollAnimationEnabled = false;

# Disable automatic text substitutions/corrections.
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

# Trackpad pointer speed. This is the closest declarative equivalent
# to increasing the macOS tracking speed slider by a couple of bars.
      "com.apple.trackpad.scaling" = 2.5;
    };

    dock = {
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

# Menu bar clock: show seconds.
    menuExtraClock = {
      ShowSeconds = true;
    };

# Control Center / menu bar battery percentage.
    controlcenter = {
      BatteryShowPercentage = true;
    };

    CustomUserPreferences = {
# Unbind Cmd+Space from Spotlight so Raycast can use it.
# Do NOT disable hotkey 65, because that is Option+Cmd+Space
# for Finder search window.
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "64" = { enabled = false; };
        };
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
    };
  };
}

