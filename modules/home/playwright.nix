{ pkgs, ... }:
# Chromium for Playwright browser tests (e.g. phishops' tests/test_*_browser.py),
# from nixpkgs instead of `playwright install chromium`: the build is
# hash-pinned and comes from the Nix binary cache rather than an unpinned
# download from Playwright's CDN, and it moves with `nix flake update`.
#
# Each Playwright release looks only for its own Chromium build, so the Python
# package must be the version nixpkgs packages, not whatever is newest on PyPI:
#
#   uv run --with playwright==$PLAYWRIGHT_NIX_VERSION pytest tests/test_ui_js_browser.py
#
# A version mismatch fails with "Executable doesn't exist at ...". Firefox,
# WebKit and ffmpeg (video recording) are left out; nothing here uses them.
let
  driver = pkgs.playwright-driver;
  browsers = driver.browsers.override {
    withFirefox = false;
    withWebkit = false;
    withFfmpeg = false;
  };
in
{
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${browsers}";
    # Not read by Playwright; tells you which version to pin (see above).
    PLAYWRIGHT_NIX_VERSION = driver.version;
  };
}
