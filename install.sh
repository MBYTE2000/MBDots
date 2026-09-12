#!/usr/bin/env bash
# MBDots installer — bootstrap.
#
# Что делает:
#   1. Проверяет что мы root (иначе re-exec через sudo -E).
#   2. Через nix-shell подтягивает node+npm (не требует установленного nodejs).
#   3. npm install зависимостей TUI в installer/node_modules (кешируется).
#   4. Запускает node installer/index.mjs — красивый интерактивный TUI:
#        • выбор диска, hostname, user, GPU, timezone
#        • LUKS-пароль с подтверждением
#        • disko destroy,format,mount → nixos-install → dotfiles → passwd
#
# Использование:
#   ./install.sh                       # интерактивно
#   sudo ./install.sh                  # если уже sudo
#
# Требования:
#   • NixOS Live ISO (25.11+), с интернетом
#   • disk с EFI (для GRUB-EFI + LUKS/btrfs схемы из disko.nix)

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 0. Требуем root -------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "→ повышаю привилегии через sudo…" >&2
  exec sudo -E env PATH="$PATH" "$0" "$@"
fi

# --- 1. Проверка окружения (базовое) ---------------------------------------
if ! command -v nix >/dev/null; then
  echo "!! nix не найден — запусти с NixOS Live ISO." >&2
  exit 1
fi

# --- 2. Готовим TUI через nix-shell ----------------------------------------
# nix-shell -p nodejs — временное окружение, ничего в /nix/store не оседает
# постоянно (только на время сессии).
export MBDOTS_REPO="$DIR"

exec nix-shell \
  -p nodejs_22 \
  --run "$(cat <<'INNER'
set -euo pipefail
cd "$MBDOTS_REPO/installer"

# npm install — только если node_modules/ отсутствует или устарел.
if [[ ! -d node_modules ]] || [[ package.json -nt node_modules ]]; then
  echo "→ ставлю npm-зависимости TUI (одноразово)…"
  # --no-audit --no-fund — молча, --loglevel=error — только реальные ошибки.
  npm install --omit=dev --no-audit --no-fund --loglevel=error
fi

exec node index.mjs "$MBDOTS_REPO"
INNER
)"
