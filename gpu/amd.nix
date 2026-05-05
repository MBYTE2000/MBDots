# GPU-профиль: AMD (radeon/amdgpu, открытые драйверы).
{ pkgs, ... }:
{
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    libvdpau-va-gl
  ];
}
