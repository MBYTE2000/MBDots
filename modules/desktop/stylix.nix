{ config, pkgs, lib, ... }:
lib.mkIf config.myConfig.desktop.stylix.enable {
  stylix = {
    enable = true;
    image = ../../WP.png;
    polarity = "dark";
    targets = {
      grub.enable = false;
    };
    cursor.package = pkgs.bibata-cursors;
    cursor.name = "Bibata-Modern-Classic";
    cursor.size = 22;
  };
}
