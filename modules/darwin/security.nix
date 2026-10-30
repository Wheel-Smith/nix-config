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

    # eMudhra CA compromise (Oct 2026): the three emSign roots were dropped
    # from the system bundle here until nixpkgs shipped cacert 3.131.1 (NSS
    # 3.131.1), which removes them itself. A blacklist for roots that are no
    # longer in the store fails the build ("Certs in blocklist but not in cert
    # store"), so it is gone; do not re-add it.
     }
