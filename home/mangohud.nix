{ osConfig, lib, ... }:
lib.mkIf osConfig.myConfig.categories.gaming.enable {
  programs.mangohud.enable = true;
}
