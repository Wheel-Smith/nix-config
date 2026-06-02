{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];
}
