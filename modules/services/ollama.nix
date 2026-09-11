{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myConfig.services.ollama.enable {
    services.ollama = {
      enable = true;
      # CUDA-сборка Ollama для NVIDIA
      package = pkgs.ollama-cuda;
      # loadModels = [ "llama3.2:3b" ];
    };
  };
}
