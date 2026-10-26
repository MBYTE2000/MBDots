{ config, pkgs, lib, ... }:
{
  config = lib.mkIf config.myConfig.programs.dsh.enable {
    programs.dsh = {
      enable = true;
      profiles.web.bundles = [ pkgs.dsh.bundles.web-ui ];
      profiles.tui.bundles = [ pkgs.dsh.bundles.tui ];
    };

    # DSH web GUI — remote-access плагин слушает на 0.0.0.0:3080,
    # поэтому порт должен быть открыт во входящих (LAN).
    networking.firewall.allowedTCPPorts = [
      3080
    ];
  };
}
