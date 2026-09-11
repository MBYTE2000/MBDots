{
  pkgs,
  inputs,
  lib,
  ...
}:
{
   stylix = {
      enable = true;
      #autoEnable = false;
      image = ./WP.png;
      polarity = "dark";
      #homeManagerIntegration.autoImport = false;
      #homeManagerIntegration.followSystem = false;
      targets = { 
         #noctalia-shell.enable = true;
         #qt.enable = false;
	 grub.enable = false;
	 #gnome.enable = false;
         #gtk.enable = false;
	 #anki.enable = false;
	 #plymouth.enable = false;
      };
      cursor.package = pkgs.bibata-cursors;
      #cursor.package = pkgs.apple-cursor; 
      #cursor.name = "macOS-BigSur";
      cursor.name = "Bibata-Modern-Classic";
      cursor.size = 22;
   };
}
