#!/usr/bin/env bash
# Автоустановка NixOS-конфига из этого репозитория.
# Запускать с NixOS Live ISO (minimal/graphical, 25.11+). Требует интернет.
#
# Использование:
#   sudo ./install.sh                    # интерактивно (диск, hostname, user, GPU)
#   DISK=/dev/nvme0n1 HOSTNAME=foo USERNAME=alice GPU=intel sudo -E ./install.sh
#
# Переменные:
#   DISK       — целевое блочное устройство (например /dev/nvme0n1)
#   HOSTNAME   — networking.hostName (он же ключ в nixosConfigurations.<...>)
#   USERNAME   — основной пользователь (заменяет 'mbyte' во всех местах)
#   GPU        — nvidia | intel | amd | none
#
# ВНИМАНИЕ: указанный диск будет ПОЛНОСТЬЮ ОЧИЩЕН.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK="${DISK:-}"
HOSTNAME_TARGET="${HOSTNAME:-}"
USERNAME_TARGET="${USERNAME:-}"
GPU="${GPU:-}"

OLD_USER="mbyte"
OLD_HOST="MB-PC"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Запусти через sudo."
command -v nix >/dev/null || die "nix не найден. Запускай с NixOS Live ISO."
command -v nixos-install >/dev/null || die "nixos-install не найден. Запускай с NixOS Live ISO."

# --- Интерактивный опрос параметров ------------------------------------------
if [[ -z "$DISK" ]]; then
  echo
  lsblk -dno NAME,SIZE,MODEL | sed 's/^/  /'
  echo
  read -rp "На какой диск ставим? (например /dev/nvme0n1): " DISK
fi
[[ -b "$DISK" ]] || die "Блочное устройство $DISK не найдено."
disk_type="$(lsblk -dno TYPE "$DISK" 2>/dev/null || true)"
[[ "$disk_type" == "disk" ]] || \
  die "$DISK — это '$disk_type', а не целый диск. Укажи /dev/nvmeN или /dev/sdX без номера раздела."

if [[ -z "$HOSTNAME_TARGET" ]]; then
  read -rp "Hostname [$OLD_HOST]: " HOSTNAME_TARGET
  HOSTNAME_TARGET="${HOSTNAME_TARGET:-$OLD_HOST}"
fi
[[ "$HOSTNAME_TARGET" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]] || \
  die "Невалидный hostname: $HOSTNAME_TARGET"

if [[ -z "$USERNAME_TARGET" ]]; then
  read -rp "Имя пользователя [$OLD_USER]: " USERNAME_TARGET
  USERNAME_TARGET="${USERNAME_TARGET:-$OLD_USER}"
fi
[[ "$USERNAME_TARGET" =~ ^[a-z_][a-z0-9_-]*$ ]] || \
  die "Невалидное имя пользователя: $USERNAME_TARGET"

if [[ -z "$GPU" ]]; then
  echo
  echo "  GPU-профили: nvidia, intel, amd, none"
  read -rp "Какой GPU? [nvidia]: " GPU
  GPU="${GPU:-nvidia}"
fi
case "$GPU" in
  nvidia|intel|amd|none) ;;
  *) die "Неизвестный GPU: $GPU (выбирай: nvidia | intel | amd | none)" ;;
esac
[[ -f "$DOTFILES_DIR/gpu/$GPU.nix" ]] || die "gpu/$GPU.nix не найден."

cat <<EOF

  Целевой диск:  $DISK
  Hostname:      $HOSTNAME_TARGET
  Пользователь:  $USERNAME_TARGET
  GPU-профиль:   $GPU
  Конфиг:        $DOTFILES_DIR

  Все данные на $DISK будут УНИЧТОЖЕНЫ.
EOF
read -rp "Продолжить? введи 'yes': " confirm
[[ "$confirm" == "yes" ]] || die "Отменено."

# --- 1. Готовим рабочую копию dotfiles в /tmp --------------------------------
# Все правки делаем в копии, чтобы не модифицировать репо.
WORK="$(mktemp -d -t mbdots-XXXXXX)"
LUKS_PWFILE="/tmp/disko-luks-password"  # путь захардкожен в disko.nix
cleanup() { rm -rf "$WORK" "$LUKS_PWFILE" 2>/dev/null || true; }
trap cleanup EXIT
cp -a "$DOTFILES_DIR/." "$WORK/"
log "Рабочая копия: $WORK"

# --- 1a. Запрос пароля LUKS (с верификацией) ---------------------------------
# Пароль кладём в /tmp/disko-luks-password, disko.nix ссылается на этот путь.
# Файл создаётся с правами 600 и стирается trap'ом при выходе.
log "Введи парольную фразу для LUKS-шифрования диска"
while true; do
  IFS= read -rsp "  Пароль: " pw1; echo
  IFS= read -rsp "  Повтор: " pw2; echo
  if [[ -z "$pw1" ]]; then
    warn "Пароль не может быть пустым."
    continue
  fi
  if [[ "$pw1" != "$pw2" ]]; then
    warn "Пароли не совпадают."
    continue
  fi
  break
done
( umask 077; printf '%s' "$pw1" > "$LUKS_PWFILE" )
unset pw1 pw2

# --- 2. Устройство передаётся в disko через --argstr disk (см. шаг 5) --------

# --- 3. Подмена hostname и username ------------------------------------------
if [[ "$HOSTNAME_TARGET" != "$OLD_HOST" ]]; then
  log "Подменяю hostname: $OLD_HOST → $HOSTNAME_TARGET"
  # configuration.nix: networking.hostName + zsh-alias 'update'
  sed -i \
    -e "s/networking.hostName = \"$OLD_HOST\"/networking.hostName = \"$HOSTNAME_TARGET\"/" \
    -e "s|/etc/nixos#$OLD_HOST|/etc/nixos#$HOSTNAME_TARGET|g" \
    "$WORK/configuration.nix"
  # flake.nix: nixosConfigurations.<host>
  sed -i "s/nixosConfigurations\.$OLD_HOST/nixosConfigurations.$HOSTNAME_TARGET/" \
    "$WORK/flake.nix"
fi

if [[ "$USERNAME_TARGET" != "$OLD_USER" ]]; then
  log "Подменяю имя пользователя: $OLD_USER → $USERNAME_TARGET"
  # configuration.nix: users.users.<user>
  sed -i "s/users\.users\.$OLD_USER/users.users.$USERNAME_TARGET/g" \
    "$WORK/configuration.nix"
  # flake.nix: home-manager users.<user>
  sed -i "s/users\.$OLD_USER = import/users.$USERNAME_TARGET = import/" \
    "$WORK/flake.nix"
  # home.nix: home.username + home.homeDirectory
  sed -i \
    -e "s/home\.username = \"$OLD_USER\"/home.username = \"$USERNAME_TARGET\"/" \
    -e "s|home\.homeDirectory = \"/home/$OLD_USER\"|home.homeDirectory = \"/home/$USERNAME_TARGET\"|" \
    "$WORK/home.nix"
fi

# --- 4. Активируем выбранный GPU-профиль -------------------------------------
log "GPU-профиль: gpu/$GPU.nix → gpu/current.nix"
cp "$WORK/gpu/$GPU.nix" "$WORK/gpu/current.nix"

# --- 4a. Временно вставляем passwordFile в disko.nix -------------------------
# disko-форматирование возьмёт пароль из $LUKS_PWFILE без интерактивного ввода.
# Эта правка живёт только в рабочей копии и до запуска disko.
sed -i \
  "s|name = \"crypted\";|name = \"crypted\";\n              passwordFile = \"$LUKS_PWFILE\";|" \
  "$WORK/disko.nix"

# --- 5. Disko: разметка, шифрование, монтирование ----------------------------
log "Запускаю disko на $DISK (пароль из $LUKS_PWFILE)..."
nix --experimental-features 'nix-command flakes' \
  run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --argstr disk "$DISK" \
  "$WORK/disko.nix"

# Стираем пароль и убираем passwordFile из рабочей копии (чтобы в
# /mnt/etc/nixos/disko.nix не осталось ссылок на /tmp-файл).
shred -u "$LUKS_PWFILE" 2>/dev/null || rm -f "$LUKS_PWFILE"
sed -i "\\|passwordFile = \"$LUKS_PWFILE\";|d" "$WORK/disko.nix"

# --- 6. Кладём конфиг в /mnt/etc/nixos ---------------------------------------
log "Копирую nix-конфиг в /mnt/etc/nixos"
install -d -m 0755 /mnt/etc/nixos
for f in configuration.nix flake.nix flake.lock home.nix discord.nix \
         noctalia.nix stylix.nix disko.nix WP.png; do
  if [[ -e "$WORK/$f" ]]; then
    cp -v "$WORK/$f" /mnt/etc/nixos/
  fi
done
install -d -m 0755 /mnt/etc/nixos/gpu
cp -v "$WORK/gpu/current.nix" /mnt/etc/nixos/gpu/

# --- 7. Свежий hardware-configuration.nix под целевое железо -----------------
# Генерируем после копирования, чтобы случайно не перезаписать его.
log "Генерирую hardware-configuration.nix"
nixos-generate-config --root /mnt --force
# nixos-generate-config пишет ./hardware-configuration.nix и
# ./configuration.nix в /mnt/etc/nixos. Наш configuration.nix только что был
# скопирован, поэтому затрём шаблон от generate-config повторно:
cp -v "$WORK/configuration.nix" /mnt/etc/nixos/configuration.nix

# --- 8. Установка ------------------------------------------------------------
log "Запускаю nixos-install (это надолго)"
nixos-install --root /mnt --flake "/mnt/etc/nixos#$HOSTNAME_TARGET" --no-root-passwd

# --- 9. Пользовательские конфиги ---------------------------------------------
USER_HOME="/mnt/home/$USERNAME_TARGET"
if [[ -d "$WORK/config" ]]; then
  log "Копирую ~/.config/* для $USERNAME_TARGET"
  install -d -m 0755 "$USER_HOME/.config"
  cp -rv "$WORK/config/." "$USER_HOME/.config/"
  uid="$(awk -F: -v u="$USERNAME_TARGET" '$1==u{print $3}' /mnt/etc/passwd)"
  gid="$(awk -F: -v u="$USERNAME_TARGET" '$1==u{print $4}' /mnt/etc/passwd)"
  if [[ -n "$uid" && -n "$gid" ]]; then
    chown -R "$uid:$gid" "$USER_HOME"
  fi
fi

# --- 10. Пароль пользователя -------------------------------------------------
log "Установи пароль для $USERNAME_TARGET (внутри chroot):"
nixos-enter --root /mnt -c "passwd $USERNAME_TARGET" || \
  warn "Пропускаю установку пароля — сделай 'passwd $USERNAME_TARGET' после ребута."

cat <<EOF

==> Готово.
    umount -R /mnt
    reboot
EOF
