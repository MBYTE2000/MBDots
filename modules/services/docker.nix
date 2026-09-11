{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myConfig.services.docker.enable {
    virtualisation.docker.enable = true;
    # Не запускаем автоматически: docker поднимается по требованию (сокет).
    systemd.services.docker.wantedBy = lib.mkForce [];
    systemd.sockets.docker.wantedBy = lib.mkForce [];
  };
}
