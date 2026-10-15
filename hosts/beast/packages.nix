{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mas
    powershell # pwsh; self-contained, no separate .NET install
  ];
}
