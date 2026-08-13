{ pkgs, ... }:
# lazygit, themed and wired to difftastic.
#
# PATH TRAP: on Darwin, home-manager writes this config to
# ~/Library/Application Support/lazygit/config.yml UNLESS xdg.enable is set,
# while lazygit itself reads $XDG_CONFIG_HOME/lazygit when that variable exists
# — which it does here. Without xdg.enable = true (set in user.nix) everything
# below would be written to a file lazygit never opens, and would look like the
# settings simply had no effect.
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        nerdFontsVersion = "3";

        # Gruvbox dark, to match ghostty, bat, btop and neovim.
        theme = {
          activeBorderColor = [ "#fabd2f" "bold" ];
          inactiveBorderColor = [ "#928374" ];
          optionsTextColor = [ "#83a598" ];
          selectedLineBgColor = [ "#3c3836" ];
          cherryPickedCommitBgColor = [ "#504945" ];
          cherryPickedCommitFgColor = [ "#fabd2f" ];
          unstagedChangesColor = [ "#fb4934" ];
          defaultFgColor = [ "#ebdbb2" ];
        };
      };

      # lazygit passes --no-ext-diff, so it deliberately bypasses the
      # diff.external set in git.nix. Point it at difftastic explicitly to get
      # the same structural diffs here as in `git diff`.
      #
      # Schema note: this was `git.paging.externalDiffCommand` until lazygit
      # renamed it — paging became the diffRenderers array, and the command
      # gained an explicit type. lazygit normally migrates old configs itself on
      # startup, but it CANNOT here: the file is a read-only symlink into the
      # Nix store, so it fails with "permission denied" and refuses to run.
      #
      # That is the cost of managing an app's config declaratively — upstream
      # schema changes become our problem. To find the new shape, copy the
      # generated config somewhere writable and start lazygit against it with
      # --use-config-file; it rewrites the file in place and shows the diff.
      git.diffRenderers = [
        {
          type = "extDiff";
          command = "${pkgs.difftastic}/bin/difft --color=always --display=inline";
          colorArg = "always";
        }
      ];

      os.editPreset = "nvim";
    };
  };
}
