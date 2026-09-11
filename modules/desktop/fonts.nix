{ config, pkgs, lib, ... }:
lib.mkIf config.myConfig.desktop.fonts.enable {
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
    liberation_ttf
    dejavu_fonts
    noto-fonts-cjk-sans
    cm_unicode
    libertine
    times-newer-roman
  ];
  fonts.enableDefaultPackages = true;
  fonts.fontconfig = {
    antialias = true;
    hinting.enable = true;
  };
}
