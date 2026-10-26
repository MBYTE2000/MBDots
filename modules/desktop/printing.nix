{ pkgs, ... }:

{
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
    # Отключаем встроенный escl, если sane-airscan находит сканер дважды
    # (Раскомментируйте, если scanimage -L показывает два одинаковых устройства)
    # disabledDefaultBackends = [ "escl" ];
  };

  # Важно для работы udev-правил SANE
  services.udev.packages = [ pkgs.sane-airscan ];

  # Если сканер подключен по USB и поддерживает IPP-USB
  services.ipp-usb.enable = true;

  #users.users.mbyte.extraGroups = [ "scanner" "lp" ];
}
