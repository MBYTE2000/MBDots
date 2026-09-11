{ config, lib, ... }:
{
  config = lib.mkIf config.myConfig.services.ssh.enable {
    services.openssh.enable = true;
  };
}
