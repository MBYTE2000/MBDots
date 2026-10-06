#!/usr/bin/env bash
# MBDots installer — bootstrap.
#
# Что делает:
#   1. Требует root (иначе re-exec через sudo -E).
#   2. Устанавливает UTF-8 локаль и cyrillic-capable консольный шрифт
#      (минимальный live ISO по-умолчанию может некорректно рисовать кириллицу).
#   3. Через nix-shell подтягивает node + kbd + terminus_font (нет на базовой
#      системе — ничего в /nix/store не оседает постоянно).
#   4. npm install зависимостей TUI в installer/node_modules.
#   5. Запускает node installer/index.mjs — интерактивный TUI на русском/английском.
#
# Использование:
#   ./install.sh                       # интерактивно
#   sudo ./install.sh                  # если уже sudo
#
# Требования:
#   • NixOS Live ISO (25.05+), с интернетом
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

# --- 2. UTF-8 локаль + cyrillic console font ------------------------------
# На минимальной ISO не всегда загружен шрифт с кириллицей — руссифицируем tty.
# `|| true` — на не-tty (ssh/graphical) setfont молча пропускаем.
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

# --- 3. Готовим TUI через nix-shell ----------------------------------------
export MBDOTS_REPO="$DIR"

exec nix-shell \
  -p nodejs_22 kbd terminus_font \
  --run "$(cat <<'INNER'
set -euo pipefail

# Пробуем переключить консоль на кириллический Terminus (большой/жирный —
# крупнее дефолта, лучше читается на HiDPI/4K). Если не tty — просто пропустим.
if [ -t 0 ] && [ -w /dev/console ] 2>/dev/null; then
  for font in \
    /nix/store/*terminus-font*/share/consolefonts/ter-v22b.psf.gz \
    /nix/store/*terminus-font*/share/consolefonts/ter-v20b.psf.gz \
    /nix/store/*terminus-font*/share/consolefonts/ter-v18b.psf.gz \
    /nix/store/*kbd*/share/consolefonts/LatArCyrHeb-16.psfu.gz
  do
    [ -f "$font" ] && setfont "$font" 2>/dev/null && break
  done
fi

cd "$MBDOTS_REPO/installer"

# npm install — только если node_modules/ отсутствует или устарел.
if [[ ! -d node_modules ]] || [[ package.json -nt node_modules ]]; then
  echo "→ ставлю npm-зависимости TUI (одноразово)…"
  npm install --omit=dev --no-audit --no-fund --loglevel=error
fi

exec node index.mjs "$MBDOTS_REPO"
INNER
)"
