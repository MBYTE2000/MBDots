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

    # Раньше здесь была hardware.nvidia.enable, но она нигде не читалась —
    # NVIDIA конфигурируется через ./gpu/current.nix (install.sh).
    hardware = {
      # Второй NVMe с ext4 как /mnt/data. Используется для хранилища ollama
      # (большие GGUF-блобы) и ComfyUI. На машинах без второго диска
      # оставить false — ollama тогда использует ~/.ollama по-умолчанию.
      dataDisk.enable = lib.mkEnableOption "вторичный NVMe как /mnt/data";
    };

    # Категории — крупные группы пакетов/настроек. Installer собирает выбор
    # пользователя (чекбоксы) и выставляет эти флаги. Отдельные модули
    # (home/packages-*.nix, modules/programs/steam.nix и т.д.) гейтятся
    # через `mkIf config.myConfig.categories.<name>.enable`.
    categories = {
      dev.enable        = lib.mkEnableOption "Dev tools (nvim/texlive/rust/python)"       // { default = true; };
      gaming.enable     = lib.mkEnableOption "Gaming (steam/proton/lutris/launchers)"     // { default = true; };
      ai.enable         = lib.mkEnableOption "AI/ML (ollama+cuda/huggingface/run-qwen)"   // { default = true; };
      multimedia.enable = lib.mkEnableOption "Multimedia (gimp/kdenlive/vlc/chromium)"    // { default = true; };
      office.enable     = lib.mkEnableOption "Office (onlyoffice/okular)"                 // { default = true; };
      comms.enable      = lib.mkEnableOption "Communications (vesktop/materialgram)"      // { default = true; };
      fileshare.enable  = lib.mkEnableOption "File sharing (qbittorrent)"                 // { default = true; };
    };
  };
}
