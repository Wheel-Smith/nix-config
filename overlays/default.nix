final: prev: {
  # nixpkgs-unstable trails OmniWM's GitHub releases. Bump the upstream
  # derivation in place rather than reaching for the Homebrew cask: the package
  # already unpacks the signed release zip with bsdtar (plain unzip breaks the
  # Developer ID signature), and the Home Manager module keeps working
  # unchanged because it still reads `pkgs.omniwm`.
  #
  # Pinned unconditionally, even once nixpkgs catches up: every OmniWM version
  # needs its own captured defaults file (modules/home/omniwm), so a version
  # change must be a deliberate edit here followed by `just omniwm-capture`,
  # never a side effect of `nix flake update`.
  omniwm = prev.omniwm.overrideAttrs (finalAttrs: _: {
    version = "0.7.5";
    src = prev.fetchurl {
      url = "https://github.com/OmniNull/OmniWM/releases/download/v${finalAttrs.version}/OmniWM-v${finalAttrs.version}.zip";
      hash = "sha256-oV/KNBGojdBviTUyjChiY9V6RMe8wiVUd+KTA/qUzM4=";
    };
  });
}
