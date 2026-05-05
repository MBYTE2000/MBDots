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
├── gpu/                          — GPU-профили (включаются через
│   │                               imports в configuration.nix)
│   ├── nvidia.nix
│   ├── intel.nix                 — встроенная графика Intel (iHD/i965)
│   ├── amd.nix
│   ├── none.nix
│   └── current.nix               — активный профиль (install.sh
│                                   копирует сюда нужный)
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

4. Запустить установку (интерактивно — спросит диск, hostname, имя
   пользователя, GPU-профиль):

   ```sh
   sudo ./install.sh
   ```

   Или сразу с параметрами:

   ```sh
   DISK=/dev/nvme0n1 \
   HOSTNAME=mylaptop \
   USERNAME=alice \
   GPU=intel \
     sudo -E ./install.sh
   ```

   Поддерживаемые `GPU`: `nvidia` | `intel` | `amd` | `none`.

5. Скрипт по шагам:
   - валидирует параметры и просит подтверждения;
   - готовит правленную копию dotfiles в `/tmp` (репо не трогается);
   - подменяет в копии: устройство в `disko.nix`, hostname в
     `configuration.nix`/`flake.nix`/zsh-алиасе, имя пользователя
     в `configuration.nix`/`flake.nix`/`home.nix`, активный
     GPU-профиль (`gpu/<тип>.nix → gpu/current.nix`);
   - запускает **disko** (форматирование + шифрование + монтирование),
     запросит пароль LUKS;
   - копирует все `.nix`-файлы и `gpu/current.nix` в
     `/mnt/etc/nixos/`;
   - генерирует свежий `hardware-configuration.nix` под целевое
     железо;
   - запускает `nixos-install --flake /mnt/etc/nixos#<hostname>`;
   - копирует `config/*` в `/mnt/home/<username>/.config/` и
     выставляет владельца;
   - просит задать пароль пользователю через `nixos-enter`.

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
- Имя пользователя `mbyte` и hostname `MB-PC` — дефолты репозитория.
  `install.sh` подменяет их во всех нужных местах: `users.users.<u>`,
  `home.username`/`home.homeDirectory`, `users.<u> = import ./home.nix`,
  `networking.hostName`, `nixosConfigurations.<host>` и zsh-alias
  `update`.
- `WP.png` хранится в репо для воспроизводимости темы (используется
  через `stylix.nix`).
- `gpu/current.nix` по умолчанию = `gpu/nvidia.nix` (текущая машина
  MB-PC). На новой установке `install.sh` перезапишет его выбранным
  профилем.
