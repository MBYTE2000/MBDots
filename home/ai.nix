{ config, osConfig, pkgs, lib, ... }:
# AI-окружение пользователя: launcher ollama + Modelfile для Qwen3.8-27B.
# Раньше оба файла жили только на диске (~/AI/) и терялись при переустановке.
# Теперь — через home.file, с actualPath вне nix-store (writable).
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

  runQwen = pkgs.writeShellApplication {
    name = "run-qwen";
    runtimeInputs = with pkgs; [ ollama-cuda curl jq coreutils ];
    text = ''
      # Launcher for Qwen3.8-27B через ollama. По умолчанию поднимает API-сервер
      # и прогревает модель в VRAM — после этого dsh или любой OpenAI-совместимый
      # клиент может подключаться. Код см. в home/ai.nix.

      set -euo pipefail

      MODEL_NAME="qwen3.8-27b"
      MODEL_DIR="$HOME/${modelDir}"
      GGUF="${ggufPath}"
      MODELFILE="${modelfile}"
      export OLLAMA_MODELS="/mnt/data/mbyte/ollama"
      export OLLAMA_HOST="127.0.0.1:11434"
      export OLLAMA_KEEP_ALIVE="''${OLLAMA_KEEP_ALIVE:-24h}"
      export OLLAMA_FLASH_ATTENTION=1
      export OLLAMA_KV_CACHE_TYPE=q4_0
      LOG="/tmp/ollama-mbyte.log"

      c_g=$'\e[32m'; c_y=$'\e[33m'; c_r=$'\e[31m'; c_c=$'\e[36m'; c_b=$'\e[1m'; c_0=$'\e[0m'
      info() { printf "%s→%s %s\n" "$c_c" "$c_0" "$*"; }
      ok()   { printf "%s✓%s %s\n" "$c_g" "$c_0" "$*"; }
      warn() { printf "%s!%s %s\n" "$c_y" "$c_0" "$*"; }
      die()  { printf "%s✗%s %s\n" "$c_r" "$c_0" "$*" >&2; exit 1; }

      daemon_up() { curl -sf "http://$OLLAMA_HOST/api/version" >/dev/null 2>&1; }

      start_daemon() {
        if daemon_up; then ok "daemon уже на http://$OLLAMA_HOST"; return; fi
        info "стартую ollama serve (log → $LOG)"
        nohup ollama serve >"$LOG" 2>&1 &
        disown || true
        for _ in {1..15}; do sleep 1; daemon_up && { ok "daemon поднят"; return; }; done
        die "daemon не поднялся за 15с. Смотри $LOG"
      }

      model_registered() {
        ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "''${MODEL_NAME}:latest"
      }

      ensure_model() {
        [ -f "$GGUF" ] || die "GGUF не найден: $GGUF — скачай его сначала."
        if model_registered; then return; fi
        info "регистрирую $MODEL_NAME (≈30с)"
        ollama create "$MODEL_NAME" -f "$MODELFILE"
        ok "готово"
      }

      warmup_model() {
        info "прогреваю модель — загружаю веса в VRAM..."
        local start ms response
        start=$(date +%s%N)
        response=$(curl -sS -X POST "http://$OLLAMA_HOST/api/generate" \
          -H "Content-Type: application/json" \
          -d "{\"model\":\"$MODEL_NAME\",\"prompt\":\"ok\",\"stream\":false,\"keep_alive\":\"$OLLAMA_KEEP_ALIVE\",\"options\":{\"num_predict\":1}}" 2>&1)
        ms=$(( ($(date +%s%N) - start) / 1000000 ))
        if echo "$response" | grep -q '"done":true'; then
          ok "модель в VRAM. Прогрев ''${ms}ms."
        else
          warn "прогрев вернул неожиданный ответ:"
          echo "$response" | head -3
        fi
      }

      print_endpoints() {
        cat <<E

      ''${c_b}API endpoints:''${c_0}
        ''${c_c}http://$OLLAMA_HOST''${c_0}                — база
        ''${c_c}http://$OLLAMA_HOST/v1/''${c_0}            — OpenAI-совместимый (dsh это использует)
        ''${c_c}http://$OLLAMA_HOST/api/chat''${c_0}       — native chat
        ''${c_c}http://$OLLAMA_HOST/api/generate''${c_0}   — native completion

      Модель: ''${c_b}$MODEL_NAME''${c_0}  |  в VRAM: ''${c_b}$OLLAMA_KEEP_ALIVE''${c_0}
      Остановить: ''${c_c}run-qwen --stop''${c_0}  |  Логи: ''${c_c}tail -f $LOG''${c_0}
      E
      }

      cmd_stop() {
        if ! daemon_up; then warn "daemon уже выключен"; return; fi
        info "останавливаю ollama"; pkill -x ollama || true; sleep 1
        daemon_up && die "не умер" || ok "остановлен"
      }

      cmd_status() {
        if daemon_up; then
          ok "daemon работает → http://$OLLAMA_HOST"
          echo; info "модели:";    ollama list
          echo; info "параметры:"; ollama show --parameters "$MODEL_NAME" 2>/dev/null || warn "модель не зарегистрирована"
          echo; info "в VRAM:";    ollama ps 2>/dev/null
          echo; info "GPU:";       grep -m1 "inference compute.*CUDA" "$LOG" 2>/dev/null | sed 's/.*msg=/  /' || echo "  (GPU-info в $LOG не найден)"
        else
          warn "daemon не работает"
        fi
      }

      cmd_recreate() {
        start_daemon
        info "удаляю старую регистрацию"
        ollama rm "$MODEL_NAME" 2>/dev/null || true
        info "создаю заново с Modelfile=$MODELFILE"
        ollama create "$MODEL_NAME" -f "$MODELFILE"
        ok "готово"; warmup_model
      }

      cmd_chat()   { start_daemon; ensure_model; info "интерактивный чат. Выход: /bye"; exec ollama run "$MODEL_NAME"; }
      cmd_prompt() { start_daemon; ensure_model; ollama run "$MODEL_NAME" "$*"; }
      cmd_serve()  { start_daemon; ensure_model; warmup_model; print_endpoints; }

      case "''${1:-serve}" in
        --stop|stop)         cmd_stop ;;
        --status|status)     cmd_status ;;
        --recreate|recreate) cmd_recreate ;;
        --chat|chat)         cmd_chat ;;
        --serve|serve|"")    cmd_serve ;;
        --help|-h|help)
          cat <<E
      Использование:
        run-qwen             # API-сервер + прогрев модели (default)
        run-qwen --chat      # интерактивный чат
        run-qwen "prompt"    # одноразовый ответ
        run-qwen --stop      # остановить daemon
        run-qwen --status    # состояние
        run-qwen --recreate  # пересоздать модель
      E
          ;;
        *) cmd_prompt "$@" ;;
      esac
    '';
  };
in
lib.mkIf osConfig.myConfig.categories.ai.enable {
  home.packages = [ runQwen ];

  # Modelfile тоже сохраняем — чтобы можно было вручную `ollama create` или
  # ссылаться на него в скрипте. Это сгенерированная копия, живая версия —
  # всегда в /nix/store, писать в ~/AI/ руками не надо.
  home.file."AI/qwen3.8-27b/Modelfile.generated".source = modelfile;

  # README рядом — чтобы помнить что к чему.
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
