{ config, lib, ... }:
# ComfyUI (Stable Diffusion Web-UI).
# Модуль подключается только при myConfig.services.comfyui.enable = true.
#
# ВАЖНО: детальные опции (gpuSupport/enableManager/user/group/createUser/
# listenAddress) есть только во внешнем модуле `comfyui-nix`. Чтобы ими
# пользоваться:
#   1) раскомментируй `comfyui-nix` в flake.nix (inputs + modules);
#   2) раскомментируй расширенный блок ниже.
{
  config = lib.mkIf config.myConfig.services.comfyui.enable {
    services.comfyui = {
      enable = true;
      # dataDir = "/mnt/data/comfyui";
      # listen = "127.0.0.1";
    };
    # Не автозапускать
    systemd.services.comfyui.wantedBy = lib.mkForce [];

    # Расширенная конфигурация (comfyui-nix), раскомментируй когда подключишь модуль:
    # services.comfyui = {
    #   gpuSupport = "cuda";
    #   enableManager = true;
    #   port = 8188;
    #   listenAddress = "127.0.0.1";
    #   user = "mbyte";
    #   group = "users";
    #   createUser = false;
    # };
  };
}
