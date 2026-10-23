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

    # eMudhra CA compromise (Oct 2026): eight intermediate keys under these
    # roots were cracked, so anyone holding them can mint certificates for any
    # site. NSS 3.131.1 removes the three roots below; nixpkgs has that as
    # cacert 3.131.1 on master, but it is a mass rebuild still on its way to
    # nixpkgs-unstable. Dropping them from the system bundle covers everything
    # that reads NIX_SSL_CERT_FILE (/etc/ssl/certs/ca-certificates.crt): Nix's
    # curl and git, nix itself, and Nix's Python certifi. Harmless to keep
    # once the new cacert lands; remove then.
    security.pki.caCertificateBlacklist = [
      "emSign ECC Root CA - G3"
      "emSign Root CA - C1"
      "emSign ECC Root CA - C3"
    ];
     }
