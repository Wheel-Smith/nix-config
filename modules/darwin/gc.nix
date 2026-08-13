{ ... }:
# Weekly garbage collection.
#
# Why a hand-rolled launchd daemon instead of `nix.gc.automatic`: nix.enable is
# false here because Determinate owns the Nix installation, and nix-darwin gates
# its entire managed-config block — nix.gc included — behind that flag. Reading
# those options with it off is flagged upstream as a bug, so the scheduling has
# to be ours.
#
# Retention matches `just clean` deliberately: 7 days. The manual recipe stays
# for cleaning up straight after a heavy day rather than waiting for Sunday.
#
# Root-only is sufficient. useUserPackages = true puts home-manager's output
# into the system-managed per-user profile, which is part of the system closure,
# so there are no separate user generations to collect — ~/.local/state/nix/
# profiles is empty.
#
# The absolute path is required: launchd daemons run with a minimal PATH that
# does not include the Nix profile.
#
#   log:   /var/log/nix-gc.log
#   run now:  sudo launchctl kickstart -k system/org.nixos.nix-gc
{
  launchd.daemons.nix-gc = {
    serviceConfig = {
      ProgramArguments = [
        "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
        "--delete-older-than"
        "7d"
      ];

      # Sundays at 03:30. launchd runs a missed job once the machine wakes, so
      # this still fires on a laptop that sleeps through the schedule.
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 3;
          Minute = 30;
        }
      ];

      # Never at load: activation is the worst possible moment to start deleting
      # store paths.
      RunAtLoad = false;

      # GC is IO-heavy and entirely unurgent; stay out of the way of real work.
      LowPriorityIO = true;
      Nice = 10;

      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
    };
  };
}
