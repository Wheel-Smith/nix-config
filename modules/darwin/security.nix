{ ... }:
  # Privacy/TCC permissions, FileVault, Apple ID, iCloud, Touch ID, and sudo Touch ID
  # remain manual for the first VM-safe phase.
  {
#    Allow sudo/root password prompts to be satisfied with Touch ID.
#    On supported Macs this also allows Apple Watch sudo auth when enabled in macOS settings.
    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;

         # Keeps Touch ID sudo working inside tmux/screen sessions.
         reattach = true;
       };
     }

