{ config, pkgs, lib, ... }:
lib.mkIf config.myConfig.desktop.sddm.enable {
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
    defaultSession = "niri";
    sddm.theme = "sddm-astronaut-theme";
    sddm.extraPackages = [ pkgs.sddm-astronaut ];
  };
}
