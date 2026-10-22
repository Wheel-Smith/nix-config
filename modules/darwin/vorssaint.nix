{ lib, username, ... }:
# Vorssaint (menu bar toolkit, cask on both hosts): its feature set and
# settings, started at login, and an activation step so a switch actually
# sticks.
#
# A fresh install turns almost every one of its ~75 features on, including a
# window layout manager and an app switcher that would fight OmniWM and skhd,
# and clipboard history and key remapping that have no business on a managed
# Mac. So the feature set is declared here: exactly the `enabled` list below
# is installed, everything else is switched off, and a switch re-applies it
# (changes made in the app's own Features page are reset to this list). Add
# or remove a name to change it. Keys are `featureAvailable.<feature>` in the
# preferences domain com.vorssaint.utils.
#
# Installing a feature is not the same as turning it on: most notch features
# also have their own switch (`notchLyricsEnabled`, ...), which a fresh
# install leaves off. `switches` turns on the one for every enabled feature
# that has one, so the list below is the whole story.
#
# The running app keeps its settings in memory and writes them back over
# whatever a switch wrote (screenshots stayed off after a switch for exactly
# this reason), so activation quits it first and reopens it afterwards.
#
# Other settings worth knowing about (all in the same domain, find more with
# `strings /Applications/Vorssaint.app/Contents/MacOS/Vorssaint | grep ^notch`):
# screenshotDelay, screenshotIncludePointer, screenshotCopyToClipboard,
# screenshotFullScreenShortcut, recorderFrameRate, recorderQuality,
# recorderSystemAudio, recorderMicrophone, recorderCountdown, keepAwake*,
# monitorAlert* (CPU/battery/disk thresholds), notchAgents* (AI usage cards),
# notchSize, notchOpenOnHover. Set one in the app, read it back with
# `defaults read com.vorssaint.utils <key>`, then declare it here.
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

  # Feature -> its on/off key, for the features that have one (names taken
  # from the app binary; the stored plist only lists keys that were changed).
  switchKey = {
    notch = "notchEnabled";
    notchCalendar = "notchCalendarEnabled";
    notchNotifications = "notchNotificationsEnabled";
    notchGestures = "notchGesturesEnabled";
    notchTimer = "notchTimerEnabled";
    notchAccessories = "notchAccessoriesEnabled";
    notchLyrics = "notchLyricsEnabled";
    notchQueue = "notchQueueEnabled";
    notchLiveEqualizer = "notchLiveEqualizer";
    notchDownloads = "notchDownloadsEnabled";
    notchWatch = "notchWatchEnabled";
    notchMascot = "notchMascotEnabled";
    smoothScroll = "smoothScrollEnabled";
  };
  switches = lib.listToAttrs (map (f: lib.nameValuePair switchKey.${f} true)
    (lib.filter (f: switchKey ? ${f}) enabled));

  asUser = cmd: ''launchctl asuser "$(id -u -- ${username})" sudo --user=${username} -- ${cmd}'';
  marker = "/tmp/vorssaint-was-running";
in
{
  system.defaults.CustomUserPreferences."com.vorssaint.utils" =
    lib.listToAttrs (map
      (f: lib.nameValuePair "featureAvailable.${f}" (lib.elem f enabled))
      features)
    // switches
    // {
      # Screenshot is bound to Cmd+Shift+2 and screen recording to
      # Cmd+Shift+1. Shortcuts are stored as "<modifiers>:<key code>"; key
      # code 19 is the "2" key and 18 the "1" key. With the capture menu off,
      # each shortcut starts its capture directly instead of offering the
      # screenshot / recording / text / colour chooser.
      screenshotShortcutEnabled = true;
      screenshotShortcut = "shift+command:19";
      screenshotShowCaptureMenuOnShortcut = false;
      recorderShortcutEnabled = true;
      recorderShortcut = "shift+command:18";
      recorderShowCaptureMenuOnShortcut = false;
      # Where captures land, and the small preview after a screenshot.
      screenshotSaveFolder = "/Users/${username}/Documents/screenshots";
      recorderSaveFolder = "/Users/${username}/Documents/recordings";
      screenshotPreviewEnabled = true;
      # Screenshot and recording controls in the notch panel.
      notchCapture = true;
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
      # Login is the launchd agent below; the app's own login item would be a
      # second launcher (and one that asks for approval in System Settings).
      launchAtLoginWanted = false;
    };

  # Open at login. `open` does nothing if it is already running.
  launchd.user.agents.vorssaint.serviceConfig = {
    ProgramArguments = [ "/usr/bin/open" "-a" "Vorssaint" ];
    RunAtLoad = true;
  };

  # Quit before the user defaults are written, reopen afterwards (only if it
  # was running, so a switch never starts it on its own).
  system.activationScripts.preActivation.text = ''
    rm -f ${marker}
    if pgrep -qx Vorssaint; then
      touch ${marker}
      ${asUser "osascript -e 'tell application id \"com.vorssaint.utils\" to quit'"} || true
      for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -qx Vorssaint || break; sleep 0.5; done
      pkill -x Vorssaint || true
    fi
  '';
  system.activationScripts.postActivation.text = ''
    if [ -e ${marker} ]; then
      rm -f ${marker}
      ${asUser "open -a Vorssaint"} || true
    fi
  '';
}
