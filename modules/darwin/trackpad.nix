{ ... }:
# Sole owner of trackpad settings — preferences.nix used to set some of these
# too, which meant two files could disagree about the same key.
{
  system.defaults.trackpad = {
    Clicking = true;
    TrackpadRightClick = true;

    # OFF deliberately. macOS reassigns EVERY three-finger swipe to four fingers
    # while three-finger drag is enabled — they cannot coexist. With this on,
    # Mission Control silently became a four-finger gesture.
    #
    # Flip to true to get window-dragging back, and expect the swipes to move to
    # four fingers again.
    TrackpadThreeFingerDrag = false;
  };

  # Spelled out rather than left to defaults, so the intent survives the next
  # time someone wonders why Mission Control moved.
  #   2 = enabled, 0 = disabled
  system.defaults.CustomUserPreferences = {
    "com.apple.AppleMultitouchTrackpad" = {
      TrackpadThreeFingerVertSwipeGesture = 2;   # up: Mission Control, down: App Exposé
      TrackpadThreeFingerHorizSwipeGesture = 2;  # left/right: switch spaces
      TrackpadFourFingerVertSwipeGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 0;
    };
    # The Bluetooth Magic Trackpad reads from its own domain.
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadThreeFingerHorizSwipeGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 0;
    };
  };
}
