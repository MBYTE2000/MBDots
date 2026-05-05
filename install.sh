#!/usr/bin/env bash
# Автоустановка NixOS-конфига из этого репозитория.
# Запускать с NixOS Live ISO (minimal/graphical). Требует интернет.
#
# Использование:
#   sudo ./install.sh                       # интерактивно (диск, hostname)
#   DISK=/dev/nvme0n1 HOSTNAME=MB-PC sudo -E ./install.sh
#
# ВНИМАНИЕ: указанный диск будет ПОЛНОСТЬЮ ОЧИЩЕН.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK="${DISK:-}"
HOSTNAME_TARGET="${HOSTNAME:-MB-PC}"
USERNAME="${USERNAME:-mbyte}"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Запусти через sudo."
command -v nix >/dev/null || die "nix не найден. Запускай с NixOS Live ISO."
command -v nixos-install >/dev/null || die "nixos-install не найден. Запускай с NixOS Live ISO."

# --- 1. Выбор диска -----------------------------------------------------------
if [[ -z "$DISK" ]]; then
  echo
  lsblk -dno NAME,SIZE,MODEL | sed 's/^/  /'
  echo
  read -rp "На какой диск ставим? (например /dev/nvme0n1): " DISK
fi
[[ -b "$DISK" ]] || die "Блочное устройство $DISK не найдено."

cat <<EOF

  Целевой диск:  $DISK
  Hostname:      $HOSTNAME_TARGET
  Пользователь:  $USERNAME
  Конфиг:        $DOTFILES_DIR

  Все данные на $DISK будут УНИЧТОЖЕНЫ.
EOF
read -rp "Продолжить? введи 'yes': " confirm
[[ "$confirm" == "yes" ]] || die "Отменено."

# --- 2. Подмена устройства в disko.nix (если нужно) --------------------------
DISKO_FILE="$DOTFILES_DIR/disko.nix"
if [[ "$DISK" != "/dev/nvme1n1" ]]; then
  log "Подменяю устройство в disko.nix на $DISK"
  TMP_DISKO="$(mktemp --suffix=.nix)"
  sed "s|/dev/nvme1n1|$DISK|g" "$DISKO_FILE" > "$TMP_DISKO"
  DISKO_FILE="$TMP_DISKO"
fi

# --- 3. Disko: разметка, шифрование, монтирование -----------------------------
log "Запускаю disko (запросит пароль LUKS)..."
nix --experimental-features 'nix-command flakes' \
  run github:nix-community/disko/latest -- \
  --mode destroy,format,mount "$DISKO_FILE"

# --- 4. Копируем nix-конфиг в /mnt/etc/nixos ---------------------------------
log "Копирую nix-конфиг в /mnt/etc/nixos"
install -d -m 0755 /mnt/etc/nixos
for f in configuration.nix flake.nix flake.lock home.nix discord.nix \
         noctalia.nix stylix.nix disko.nix WP.png; do
  if [[ -e "$DOTFILES_DIR/$f" ]]; then
    cp -v "$DOTFILES_DIR/$f" /mnt/etc/nixos/
  fi
done

# --- 5. Генерируем hardware-configuration.nix под целевое железо --------------
# Без --no-filesystems: disko не подключён к системному модулю, fileSystems
# должны быть описаны через стандартный hardware-configuration.nix. UUID
# берутся со свежеразмеченных и смонтированных дисков.
log "Генерирую hardware-configuration.nix"
nixos-generate-config --root /mnt --force

# Меняем hostname в configuration.nix и flake.nix, если задано другое имя.
if [[ "$HOSTNAME_TARGET" != "MB-PC" ]]; then
  log "Меняю hostname на $HOSTNAME_TARGET (configuration.nix + flake.nix)"
  sed -i "s/networking.hostName = \"MB-PC\"/networking.hostName = \"$HOSTNAME_TARGET\"/" \
    /mnt/etc/nixos/configuration.nix
  sed -i "s/nixosConfigurations.MB-PC/nixosConfigurations.$HOSTNAME_TARGET/" \
    /mnt/etc/nixos/flake.nix
  # Алиас 'update' в zsh тоже ссылается на #MB-PC.
  sed -i "s|nixos-rebuild switch --flake /etc/nixos#MB-PC|nixos-rebuild switch --flake /etc/nixos#$HOSTNAME_TARGET|" \
    /mnt/etc/nixos/configuration.nix
fi

# --- 6. Установка -------------------------------------------------------------
log "Запускаю nixos-install (это надолго)"
nixos-install --root /mnt --flake "/mnt/etc/nixos#$HOSTNAME_TARGET" --no-root-passwd

# --- 7. Пользовательские конфиги ---------------------------------------------
USER_HOME="/mnt/home/$USERNAME"
if [[ -d "$DOTFILES_DIR/config" && -d "$USER_HOME" ]]; then
  log "Копирую ~/.config/* для $USERNAME"
  install -d -m 0755 "$USER_HOME/.config"
  cp -rv "$DOTFILES_DIR/config/." "$USER_HOME/.config/"
  # UID/GID берём из /mnt/etc/passwd, чтобы не зависеть от хост-системы
  uid="$(awk -F: -v u="$USERNAME" '$1==u{print $3}' /mnt/etc/passwd)"
  gid="$(awk -F: -v u="$USERNAME" '$1==u{print $4}' /mnt/etc/passwd)"
  if [[ -n "$uid" && -n "$gid" ]]; then
    chown -R "$uid:$gid" "$USER_HOME/.config"
  fi
fi

# --- 8. Пароль пользователя ---------------------------------------------------
log "Установи пароль для $USERNAME (внутри chroot):"
nixos-enter --root /mnt -c "passwd $USERNAME" || \
  warn "Пропускаю установку пароля — сделай 'passwd $USERNAME' после ребута."

cat <<EOF

==> Готово.
    umount -R /mnt
    reboot
EOF
