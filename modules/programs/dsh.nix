{ config, pkgs, lib, ... }:
{
  config = lib.mkIf config.myConfig.programs.dsh.enable {
    programs.dsh = {
      enable = true;
      profiles.web.bundles = [ pkgs.dsh.bundles.web-ui ];
      profiles.tui.bundles = [ pkgs.dsh.bundles.tui ];
    };
  };
}
