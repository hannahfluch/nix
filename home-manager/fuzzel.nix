{ pkgs, ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        layer = "overlay";
        terminal = "${pkgs.alacritty}/bin/alacritty";
      };
      colors.background = "000000ff"; # todo: stylix
    };
  };
}
