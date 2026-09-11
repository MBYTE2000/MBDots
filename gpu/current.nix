# GPU-профиль: NVIDIA (проприетарные драйверы).
{ config, pkgs, ... }:
{
  boot.kernelParams = [ "nvidia_drm.modeset=1" ];
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" "nvidia_uvm" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
  ];

  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
  ];
}
