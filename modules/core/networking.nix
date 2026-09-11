{ config, lib, ... }:
{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  networking.networkmanager.ensureProfiles.profiles = {
    "ethPort" = {
      connection = {
        id = "ethPort";
        type = "ethernet";
        interface-name = "enp11s0";
      };
      ipv4 = {
        address1 = "10.20.0.10/16,10.20.0.1";
        dns = "10.20.0.1";
        method = "manual";
      };
    };
  };
}
