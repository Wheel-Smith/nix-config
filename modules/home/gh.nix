{ ... }:
# GitHub CLI.
#
# Only `settings` is managed, which becomes $XDG_CONFIG_HOME/gh/config.yml.
# The `hosts` option is deliberately NOT used: that writes gh/hosts.yml, which
# is where authentication lives. On this machine gh already delegates tokens to
# the macOS Keychain — hosts.yml carries no token — and Keychain is a better
# home for one than a public repo would be, even encrypted. `gh auth login`
# keeps working exactly as before.
#
# TRADE-OFF: config.yml becomes a read-only symlink into the store, so
# `gh config set ...` will fail. Change settings here and switch instead.
# Extensions are unaffected — they live in ~/.local/share/gh/extensions.
{
  programs.gh = {
    enable = true;
    settings = {
      # Was https. Everything else here talks to GitHub over ssh — the remote
      # for this repo included — so https meant `gh repo clone` produced remotes
      # that behaved differently from every other clone.
      git_protocol = "ssh";

      editor = "nvim";
      prompt = "enabled";

      aliases = {
        co = "pr checkout";
      };
    };
  };
}
