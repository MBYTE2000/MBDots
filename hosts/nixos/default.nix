{ config, pkgs, inputs, lib, ... }:
# Хост: nixos (текущий ПК, AMD CPU + NVIDIA GPU, LUKS/btrfs)
{
  imports = [
    # Автоматически сгенерированный hardware config
    ../../hardware-configuration.nix
    # GPU-профиль. install.sh кладёт сюда nvidia.nix/amd.nix/intel.nix/none.nix
    ../../gpu/current.nix
    # Общее дерево модулей
    ../../modules
  ];

  # ---- Хост-специфичные переключатели ----
  # Сервисы, отключённые по умолчанию — включаем то, что нужно ИМЕННО этому ПК.
  myConfig = {
    services = {
      # По умолчанию всё выключено. Раскомментируй нужное:
      #docker.enable  = true;   # включает docker.service (не автозапуск)
      #ollama.enable  = true;   # LLM runtime с CUDA
      #comfyui.enable = true;   # требует раскомментировать comfyui-nix в flake.nix
      #wazuh.enable   = true;   # SIEM-агент (после ставить `wazuh-setup`)
      #ssh.enable     = true;
    };

    desktop = {
      niri.enable   = true;
      sddm.enable   = true;
      stylix.enable = true;
      fonts.enable  = true;
    };

    programs = {
      zsh.enable         = true;
      niriProgram.enable = true;
      dsh.enable         = true;
    };

    hardware.nvidia.enable = true;
  };

  # Пакеты из flake-inputs, доступные глобально
  environment.systemPackages = [
    inputs.prismlauncher.packages.${pkgs.system}.prismlauncher
    inputs.freesmlauncher.packages.${pkgs.system}.freesmlauncher
    inputs.vintagestory.packages.${pkgs.system}.default
  ];

  system.stateVersion = "25.05";
}
