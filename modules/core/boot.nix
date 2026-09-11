{ config, pkgs, lib, ... }:
{
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      # Хранить последние 30 поколений в GRUB для отката из меню загрузки.
      # Меньше 20 — теряем историю после недели активных `update`.
      configurationLimit = 30;
      minegrub-theme = {
        enable = true;
        splash = "100% Flakes!";
        background = "background_options/1.8  - [Classic Minecraft].png";
        boot-options-count = 4;
      };
      memtest86.enable = true;
    };
    efi.canTouchEfiVariables = true;
  };

  boot.plymouth.enable = true;
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "quiet" "splash" ];

  boot.initrd.systemd.services.plymouth-start = {
    after = [ "systemd-modules-load.service" ];
    requires = [ "systemd-modules-load.service" ];
  };
}
