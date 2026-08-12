{ ... }:
# No system-level packages on the work Mac.
#
# beast installs `mas` here, but a Managed Apple Account cannot purchase from
# the Mac App Store — apps arrive through the MDM instead — so mas would be
# dead weight.
{
  environment.systemPackages = [ ];
}
