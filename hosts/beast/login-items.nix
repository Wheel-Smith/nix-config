{ ... }:
# Apps to open at login, as launchd agents rather than System Settings >
# Login Items, so they are declared here and survive a reinstall. `open`
# hands off to LaunchServices and does nothing if the app is already running.
# Each app must also be in homebrew.nix (cleanup = "uninstall" removes the
# app, and the agent then fails harmlessly at login).
{
  launchd.user.agents.reminders-menubar.serviceConfig = {
    ProgramArguments = [ "/usr/bin/open" "-a" "Reminders MenuBar" ];
    RunAtLoad = true;
  };
}
