# dotfiles — NixOS-конфиг MB-PC

Полная NixOS-конфигурация: flake + home-manager + disko, плюс несколько
пользовательских конфигов из `~/.config/`.

## Структура

```
.
├── flake.nix / flake.lock        — корневой flake (host: MB-PC)
├── configuration.nix             — системная конфигурация
├── hardware-configuration.nix    — текущая машина (на новой будет
│                                   перегенерирован install.sh)
├── home.nix                      — home-manager (пакеты пользователя)
├── discord.nix / noctalia.nix    — модули, подключаемые из home.nix
├── stylix.nix                    — тема системы
├── disko.nix                     — декларативная разметка диска
│                                   (nvme: ESP + LUKS → btrfs subvolumes)
├── WP.png                        — обои (используются stylix)
├── config/                       — пользовательские конфиги в ~/.config/
│   ├── niri/                     — оконник
│   ├── alacritty/
│   ├── mimeapps.list             — ассоциации файлов (PDF→Okular,
│   │                               DOC/DOCX→OnlyOffice)
│   ├── dolphinrc
│   ├── okularrc, okularpartrc
│   ├── trashrc
│   └── QtProject.conf
└── install.sh                    — автоустановщик на новый ПК
```

## Установка на новый ПК

1. Загрузиться с **NixOS Live ISO** (minimal или graphical, 25.11+).
2. Подключить интернет (`nmcli` / `nmtui` или ethernet).
3. Скачать репозиторий:

   ```sh
   nix-shell -p git --run "git clone <url-репо> /tmp/dotfiles"
   cd /tmp/dotfiles
   ```

4. Запустить установку:

   ```sh
   sudo ./install.sh
   ```

   Или с готовыми параметрами:

   ```sh
   DISK=/dev/nvme0n1 HOSTNAME=MB-PC sudo -E ./install.sh
   ```

5. Скрипт по шагам:
   - запросит подтверждение и пароль LUKS;
   - запустит **disko** (форматирование + шифрование + монтирование);
   - сгенерирует `hardware-configuration.nix` под целевое железо;
   - скопирует все `.nix`-файлы в `/mnt/etc/nixos/`;
   - запустит `nixos-install --flake /mnt/etc/nixos#<hostname>`;
   - скопирует `config/*` в `/mnt/home/mbyte/.config/`;
   - попросит задать пароль пользователю.

6. `umount -R /mnt && reboot`.

## После первой загрузки

- Пароль root: задаётся через `passwd` под рутом.
- Flatpak-приложения (Sober) подтянутся автоматически (`services.flatpak`
  в `home.nix`).
- Если нужно обновить flake-входы: `nix flake update /etc/nixos`.
- Пересборка системы (alias из `configuration.nix`): `update`.

## Disko-разметка

`disko.nix` описывает:

- `/dev/nvme1n1` (по умолчанию) — изменяется через `DISK=...` в
  `install.sh`;
- GPT, ESP 1 ГБ (`/boot`, vfat, fmask=0077);
- остальное — LUKS2 (`crypted`) → btrfs с subvolumes:
  - `root` → `/` (zstd, noatime)
  - `home` → `/home`
  - `nix` → `/nix`
  - `swap` → `/.swapvol` (swapfile 8 ГБ)

Если хочешь подключить disko декларативно (чтобы и `nixos-rebuild`
управлял разметкой), добавь в `flake.nix`:

```nix
inputs.disko = {
  url = "github:nix-community/disko";
  inputs.nixpkgs.follows = "nixpkgs";
};
# в modules:
inputs.disko.nixosModules.disko
./disko.nix
```

…и убери `fileSystems` из `hardware-configuration.nix` (или генерируй с
`--no-filesystems`).

## Замечания

- `hardware-configuration.nix` в репо — снимок текущей машины. На новом
  ПК `install.sh` его перезапишет (`nixos-generate-config --force`).
  Менять руками не нужно.
- Привязка к hostname `MB-PC` — в `flake.nix`. `install.sh` подменит
  `networking.hostName`, но имя в `nixosConfigurations.<имя>` останется
  тем же — поэтому `--flake ...#MB-PC` будет работать всегда.
- `WP.png` хранится в репо для воспроизводимости темы (используется
  через `stylix.nix`).
