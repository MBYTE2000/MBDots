# /etc/nixos/modules/services/ollama.nix
{ config, lib, pkgs, ... }:
let
  hasDataDisk = config.myConfig.hardware.dataDisk.enable;
in
{
  config = lib.mkIf config.myConfig.services.ollama.enable (lib.mkMerge [
    {
      # ollama-cuda — GPU inference через CUDA (RTX 5080). Обычный pkgs.ollama
      # собирается CPU-only, GPU не видит.
      environment.systemPackages = [ pkgs.ollama-cuda ];

      # Демон НЕ запускается автоматически; поднимать через `run-qwen` или
      # systemctl --user enable --now ollama.
      services.ollama.enable = lib.mkForce false;
    }

    # Если есть вторичный диск — храним blobs ollama на нём (многие GGUF
    # по 10-20GB, на основном SSD мало места).
    (lib.mkIf hasDataDisk {
      environment.sessionVariables.OLLAMA_MODELS = "/mnt/data/mbyte/ollama";
      systemd.tmpfiles.rules = [
        "d /mnt/data/mbyte/ollama 0755 mbyte users -"
      ];
    })
    # Иначе ollama будет использовать ~/.ollama по умолчанию.
  ]);
}
