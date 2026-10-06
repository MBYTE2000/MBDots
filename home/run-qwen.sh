#!/usr/bin/env bash
# Launcher for Qwen3.8-27B через ollama. По умолчанию поднимает API + прогревает модель.
# Устанавливается в $HOME/.local/bin/run-qwen из home/ai/run-qwen.sh (nix-managed).

set -euo pipefail

MODEL_NAME="qwen3.8-27b"
MODEL_DIR="$HOME/AI/qwen3.8-27b"
GGUF="$MODEL_DIR/Qwen3.8-27B-UD-Q3_K_XL.gguf"
MODELFILE="$HOME/AI/qwen3.8-27b/Modelfile.generated"
export OLLAMA_MODELS="/mnt/data/mbyte/ollama"
export OLLAMA_HOST="127.0.0.1:11434"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-24h}"
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
  ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "${MODEL_NAME}:latest"
}

ensure_model() {
  [ -f "$GGUF" ] || die "GGUF не найден: $GGUF — скачай его сначала (hf download …)"
  [ -f "$MODELFILE" ] || die "Modelfile не найден: $MODELFILE — пересобери конфиг"
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
    ok "модель в VRAM. Прогрев ${ms}ms."
  else
    warn "прогрев вернул неожиданный ответ:"
    echo "$response" | head -3
  fi
}

print_endpoints() {
  printf "\n%bAPI endpoints:%b\n" "$c_b" "$c_0"
  printf "  %bhttp://%s%b                — база\n" "$c_c" "$OLLAMA_HOST" "$c_0"
  printf "  %bhttp://%s/v1/%b            — OpenAI-совместимый (dsh)\n" "$c_c" "$OLLAMA_HOST" "$c_0"
  printf "  %bhttp://%s/api/chat%b       — native chat\n" "$c_c" "$OLLAMA_HOST" "$c_0"
  printf "  %bhttp://%s/api/generate%b   — native completion\n" "$c_c" "$OLLAMA_HOST" "$c_0"
  printf "\nМодель: %b%s%b  |  в VRAM: %b%s%b\n" "$c_b" "$MODEL_NAME" "$c_0" "$c_b" "$OLLAMA_KEEP_ALIVE" "$c_0"
  printf "Остановить: %brun-qwen --stop%b  |  Логи: %btail -f %s%b\n\n" "$c_c" "$c_0" "$c_c" "$LOG" "$c_0"
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

cmd_help() {
  cat <<'HELP'
Использование:
  run-qwen             # API-сервер + прогрев модели (default)
  run-qwen --chat      # интерактивный чат
  run-qwen "prompt"    # одноразовый ответ
  run-qwen --stop      # остановить daemon
  run-qwen --status    # состояние
  run-qwen --recreate  # пересоздать модель
HELP
}

case "${1:-serve}" in
  --stop|stop)         cmd_stop ;;
  --status|status)     cmd_status ;;
  --recreate|recreate) cmd_recreate ;;
  --chat|chat)         cmd_chat ;;
  --serve|serve|"")    cmd_serve ;;
  --help|-h|help)      cmd_help ;;
  *)                   cmd_prompt "$@" ;;
esac
