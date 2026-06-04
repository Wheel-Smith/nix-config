{ ... }:
{
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
    blockAllIncoming = false;
    allowSigned = true;
    allowSignedApp = true;
  };

  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 0;
  };

  system.defaults.loginwindow = {
    GuestEnabled = false;
  };
}


