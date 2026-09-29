# /etc/nixos/modules/services/ollama.nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myConfig.services.ollama.enable {
    # ollama-cuda — GPU inference через CUDA (RTX 5080). Обычный pkgs.ollama
    # собирается CPU-only, GPU не видит.
    environment.systemPackages = [ pkgs.ollama-cuda ];

    # Модели/blob-store лежат на втором SSD — на /home мало места.
    environment.sessionVariables.OLLAMA_MODELS = "/mnt/data/mbyte/ollama";

    # Директория создаётся с правильным владельцем.
    systemd.tmpfiles.rules = [
      "d /mnt/data/mbyte/ollama 0755 mbyte users -"
    ];

    # Демон НЕ запускается автоматически; включать вручную (`ollama serve &`)
    # или через systemctl --user, если хочешь.
    services.ollama.enable = lib.mkForce false;
  };
}
