# GPU-профиль: Intel встроенная графика (iGPU).
{ pkgs, ... }:
{
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver        # iHD (Broadwell+, для VAAPI)
    intel-vaapi-driver        # i965 (старые поколения, fallback)
    libvdpau-va-gl
    vpl-gpu-rt                # для Tiger Lake / Alder Lake+ кодека
  ];

  hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
    intel-media-driver
    intel-vaapi-driver
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";  # переключи на "i965" для Haswell и старше
  };
}
