{ lib, ... }:
{
  # Единая точка для всех переключателей проекта.
  # Каждая опциональная фича добавляет сюда свой enable через mkEnableOption
  # в соответствующем файле modules/<категория>/<фича>.nix.
  options.myConfig = {
    services = {
      docker.enable   = lib.mkEnableOption "Docker (по требованию, не автозапуск)";
      ollama.enable   = lib.mkEnableOption "Ollama (LLM runner c CUDA)";
      comfyui.enable  = lib.mkEnableOption "ComfyUI (Stable Diffusion UI)";
      wazuh.enable    = lib.mkEnableOption "Wazuh agent (SIEM/EDR)";
      ssh.enable      = lib.mkEnableOption "OpenSSH server";
    };

    desktop = {
      niri.enable   = lib.mkEnableOption "Niri (Wayland compositor)"        // { default = true; };
      sddm.enable   = lib.mkEnableOption "SDDM display manager"             // { default = true; };
      stylix.enable = lib.mkEnableOption "Stylix (единая тема)"             // { default = true; };
      fonts.enable  = lib.mkEnableOption "Расширенный набор шрифтов"        // { default = true; };
    };

    programs = {
      zsh.enable        = lib.mkEnableOption "ZSH + Oh-My-Zsh + Starship"    // { default = true; };
      niriProgram.enable = lib.mkEnableOption "programs.niri модуль"         // { default = true; };
      dsh.enable        = lib.mkEnableOption "dsh (Nix bundles launcher)"    // { default = true; };
    };

    hardware = {
      nvidia.enable = lib.mkEnableOption "NVIDIA (проприетарный драйвер)";
      # Реальный выбор идёт через ./gpu/current.nix (install.sh).
    };
  };
}
