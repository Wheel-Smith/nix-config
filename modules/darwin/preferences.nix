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
      # Hold Ctrl+Cmd and drag anywhere in a window to move it.
      NSWindowShouldDragOnGesture = true;

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
# External mouse pointer speed, same slider position as the trackpad. Not a
# typed option (only the trackpad one is), so it is written here as a raw key.
        "com.apple.mouse.scaling" = 2.0;
        AppleAccentColor = 1;
        AppleHighlightColor = "1.000000 0.874510 0.701961 Orange";
      };

# Vorssaint (menu bar toolkit, cask on both hosts). A fresh install turns almost
# every one of its ~75 features on, including a window layout manager and an
# app switcher that would fight OmniWM and skhd, and clipboard history and key
# remapping that have no business on a managed Mac. So the feature set is
# declared here: exactly the `enabled` list below is installed, everything else
# is switched off, and a switch re-applies it (changes made in the app's own
# Features page are reset to this list). Add or remove a name to change it.
# Keys are `featureAvailable.<feature>`; the app reads them from its
# preferences domain com.vorssaint.utils, so restart the app after a switch.
#
# Screenshot is bound to Cmd+Shift+2 and screen recording to Cmd+Shift+1.
# Shortcuts are stored as "<modifiers>:<key code>"; key code 19 is the "2" key
# and 18 the "1" key. With the capture menu off, each shortcut starts its
# capture directly instead of offering the screenshot / recording / text /
# colour chooser.
      "com.vorssaint.utils" =
        let
          enabled = [
            "smoothScroll" "mouseAcceleration" "mixer" "keepAwake" "screenshot" "screenRecorder"
            "portManager" "notch" "notchCalendar" "notchNotifications" "notchGestures" "notchTimer"
            "notchAccessories" "notchLyrics" "notchQueue" "notchLiveEqualizer" "notchDownloads"
            "notchWatch" "notchMascot" "monitorCPU" "monitorGPU" "monitorMemory" "monitorNetwork"
            "monitorDisk" "monitorPower"
          ];
          features = [
            "switcher" "dockPreview" "dockClick" "windowMaximizer" "windowLayout" "autoQuit"
            "spacesOrder" "scrollInverter" "scrollHorizontal" "focusFollowsMouse" "smoothScroll"
            "linearScroll" "mouseAcceleration" "mouseNavigation" "mouseButtonShortcuts"
            "middleClick" "mouseClickDebounce" "keyboardDebounce" "textSnippets" "superKey"
            "quitWindowProtection" "clipboardHistory" "pastePlain" "finderCutPaste" "finderRename"
            "shelf" "urlCleaner" "diskImageInstaller" "mixer" "soundOutputSwitcher" "audioPriority"
            "micMute" "musicBlock" "keepAwake" "brightness" "extraBrightness" "bluetoothSleep"
            "quickLauncher" "quickToggles" "colorPicker" "screenOCR" "cleaningMode" "mediaTools"
            "cleaner" "uninstaller" "homebrew" "appUpdates" "screenshot" "cameraPreview"
            "radialMenu" "scratchpad" "commandBar" "screenRecorder" "wallpaper" "killProcess"
            "portManager" "notch" "notchCalendar" "notchNotifications" "notchGestures" "notchTimer"
            "notchAccessories" "notchLyrics" "notchQueue" "notchLiveEqualizer" "notchDownloads"
            "notchAgents" "notchWatch" "notchMascot" "monitorCPU" "monitorGPU" "monitorMemory"
            "monitorNetwork" "monitorDisk" "monitorPower" "connectedDevices" "fanControl"
          ];
        in
        lib.listToAttrs (map
          (f: lib.nameValuePair "featureAvailable.${f}" (lib.elem f enabled))
          features)
        // {
          screenshotShortcutEnabled = true;
          screenshotShortcut = "shift+command:19";
          screenshotShowCaptureMenuOnShortcut = false;
          recorderShortcutEnabled = true;
          recorderShortcut = "shift+command:18";
          recorderShowCaptureMenuOnShortcut = false;
          # Notch mascot: the orange robot.
          notchMascotPalette = "orange";
          notchMascotShape = "squircle";
          notchMascotStyle = "robot";
          # Edge-drag and option-key tiling, separate from the Window Layout
          # feature above. Not set in the app by default, so they are written
          # off here to keep windows floating.
          EnableTilingByEdgeDrag = false;
          EnableTopTilingByEdgeDrag = false;
          EnableTilingOptionAccelerator = false;
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

# Unbind Cmd+Space from Spotlight so Vicinae can use it (both Macs).
# Do NOT disable hotkey 65, because that is Option+Cmd+Space
# for Finder search window.
#
# Also unbind Ctrl+Up (32, Mission Control) and Ctrl+Down (33, App Exposé),
# so tmux gets them for prefix + Ctrl+Up/Down pane resizing. Mission
# Control stays on F3 and the trackpad swipe.
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "64" = { enabled = false; };
          "32" = { enabled = false; };
          "33" = { enabled = false; };
        };
      };
    };
  };
}
