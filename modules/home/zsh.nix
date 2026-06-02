{ lib, ... }:
{
  home.sessionPath = [
    "/opt/homebrew/opt/curl/bin"
      "$HOME/.pnpm-packages/bin"
      "$HOME/.pnpm-packages"
      "$HOME/.npm-packages/bin"
      "$HOME/bin"
      "$HOME/.local/share/bin"
  ];

  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    HISTIGNORE = "pwd:ls:cd";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    FZF_DEFAULT_OPTS = ''
      --preview 'bat -n --color=always --line-range :500 {}'
      --preview-window down:50%
      --bind 'ctrl-/:toggle-preview'
      '';
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

# ~/.zprofile equivalent. Keep imperative app integrations guarded so a
# clean VM still activates even before Homebrew/OrbStack have initialized.
    profileExtra = ''
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
          fi

          source ~/.orbstack/shell/init.zsh 2>/dev/null || :
          '';

    shellAliases = {
# eza / navigation
      ls = "eza -lh --group-directories-first --icons=auto";
      ll = "eza --icons --group-directories-first -la --bytes";
      lsa = "ls -a";
      lt = "eza --tree --level=2 --long --icons --git";
      lta = "lt -a";
      tree = "eza --icons --tree";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

# tools
      grep = "rg";
      ff = "fzf --preview 'bat --style=numbers --color=always {}'";
      d = "docker";
      lzg = "lazygit";
      lzd = "lazydocker";
      lzs = "lazyssh";
      diff = "difft";
    };

    initContent = lib.mkMerge [
# Must happen before compinit for completion directories to be indexed.
      (lib.mkOrder 550 ''
       if [ -d ~/.docker/completions ]; then
       fpath+=(~/.docker/completions)
       fi
       '')

        ''
# n: open current directory in nvim when called with no args, otherwise
# open the provided paths.
        n() {
          if [ "$#" -eq 0 ]; then
            nvim .
          else
            nvim "$@"
              fi
        }

# Custom cd using zoxide. Home Manager's programs.zoxide integration
# provides the z command; this preserves your daily-machine behavior.
    alias cd="zd"
      zd() {
        if [ $# -eq 0 ]; then
          builtin cd ~ && return
            elif [ -d "$1" ]; then
            builtin cd "$1"
        else
          z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
            fi
      }

# Mole shell completion. Guarded because mole is a Homebrew formula.
    if command -v mole >/dev/null 2>&1; then
      if output="$(mole completion zsh 2>/dev/null)"; then
        eval "$output"
          fi
          fi

# Visual startup summary, matching your current daily-machine .zshrc.
          if command -v fastfetch >/dev/null 2>&1; then
            fastfetch
              fi
              ''
              ];
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}

