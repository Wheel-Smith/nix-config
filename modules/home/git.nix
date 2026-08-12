{ lib, isWork, ... }:
let
  personalIdentity = {
    name = "rattatui";
    email = "88578725+Wheel-Smith@users.noreply.github.com";
  };
in
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
    ];

# The work Mac carries two identities, because this repo is itself a personal,
# public one that gets cloned there. Rather than pick a default and risk the
# wrong address on a commit, there is no default at all:
#
#   ~/work/      -> work identity, from a hand-created file OUTSIDE this repo
#                   so the work email never enters public git history. Git
#                   silently ignores a missing include path, so nothing breaks
#                   before you create it — you just get the useConfigOnly error.
#   ~/projects/  -> personal identity, managed here.
#   anywhere else-> git refuses to commit until you say which hat you are
#                   wearing. That is the point.
#
# Create the work file by hand on the work Mac:
#
#   mkdir -p ~/.config/git
#   printf '[user]\n\tname = <name>\n\temail = <work email>\n' > ~/.config/git/work.inc
    includes = lib.optionals isWork [
      {
        condition = "gitdir:~/work/";
        path = "~/.config/git/work.inc";
      }
      {
        condition = "gitdir:~/projects/";
        contents.user = personalIdentity;
      }
    ];

    settings = {
      user = if isWork then { useConfigOnly = true; } else personalIdentity;

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
