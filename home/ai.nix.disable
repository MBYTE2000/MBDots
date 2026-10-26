{ config, osConfig, pkgs, lib, ... }:
# AI-окружение пользователя: launcher ollama + Modelfile для Qwen3.8-27B.
# Раньше оба файла жили только на диске (~/AI/) и терялись при переустановке.
let
  modelDir = "AI/qwen3.8-27b";
  ggufPath = "${config.home.homeDirectory}/${modelDir}/Qwen3.8-27B-UD-Q3_K_XL.gguf";

  modelfile = pkgs.writeText "qwen3.8-27b-Modelfile" ''
    FROM ${ggufPath}

    # 32K контекст с q4_0 kv-cache ≈ 1GB. Умещается на 16GB VRAM рядом с 13GB модели.
    PARAMETER num_ctx 32768

    PARAMETER num_gpu 999
    PARAMETER num_predict -1
    PARAMETER temperature 0.6
    PARAMETER top_p 0.8
    PARAMETER top_k 20
    PARAMETER min_p 0.0
    PARAMETER repeat_penalty 1.05
    PARAMETER stop "<|im_end|>"
    PARAMETER stop "<|endoftext|>"
  '';

  # Launcher-скрипт лежит в home/run-qwen.sh — обычный bash-файл.
  # Оборачиваем в писатель, который экспортирует PATH с CUDA-версией ollama.
  runQwen = pkgs.writeShellScriptBin "run-qwen" ''
    export PATH="${lib.makeBinPath (with pkgs; [ ollama-cuda curl jq coreutils gnugrep gawk procps ])}:$PATH"
    exec ${./run-qwen.sh} "$@"
  '';
in
lib.mkIf osConfig.myConfig.categories.ai.enable {
  home.packages = [ runQwen ];

  # Modelfile — сгенерированный путь из nix store. run-qwen.sh читает его
  # через ~/AI/qwen3.8-27b/Modelfile.generated (symlink).
  home.file."AI/qwen3.8-27b/Modelfile.generated".source = modelfile;

  # README рядом.
  home.file."AI/README.md".text = ''
    AI-окружение управляется через nix: `home/ai.nix` в репе.

    Команды:
      run-qwen            — поднять API + прогреть модель
      run-qwen --chat     — интерактивный чат
      run-qwen --status   — проверить состояние
      run-qwen --recreate — пересобрать модель по Modelfile.generated

    Модель (`Qwen3.8-27B-UD-Q3_K_XL.gguf`) — лежит в `qwen3.8-27b/` и НЕ
    трекается в nix (~13GB). Скачать:

      hf download unsloth/Qwen3.8-27B-GGUF \
        --include "*UD-Q3_K_XL*.gguf" \
        --local-dir ~/AI/qwen3.8-27b/

    Blobs ollama хранятся на /mnt/data/mbyte/ollama (OLLAMA_MODELS env).
  '';
}
