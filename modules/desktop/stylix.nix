{ config, pkgs, lib, ... }:
lib.mkIf config.myConfig.desktop.stylix.enable {
  stylix = {
    enable = true;
    image = ../../WP.png;
    polarity = "dark";

    # Явные шрифты для всех stylix-целей. Раньше stylix брал дефолтные
    # (DejaVu Sans / IBM Plex Mono и т.п.) — теперь alacritty, kitty, nvim,
    # gtk и qt получают одинаковый JetBrains Mono/Noto из этого модуля.
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        terminal = 12;
        desktop = 10;
        popups = 10;
      };
    };

    targets = {
      grub.enable = false;  # minegrub-theme занимает загрузчик
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 22;
    };
  };
}
