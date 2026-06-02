{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    ignores = [
      ".DS_Store"
        ".direnv/"
        ".env"
        ".env."
        ".venv/"
        "node_modules/"
        "pycache/"
        ".pyc"
        ".swp"
        "result"
        "result-"
    ];

    settings = {
      user = {
        name = "rattatui";
        email = "88578725+Wheel-Smith@users.noreply.github.com";
      };

      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      rebase = {
        autoStash = true;
      };

      core = {
        editor = "nvim";
      };
    };
  };
}

