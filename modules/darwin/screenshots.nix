{ username, ... }:
{
  system.defaults.screencapture = {
    location = "/Users/${username}/Pictures/Screenshots";
    type = "png";
    disable-shadow = true;
  };
}
