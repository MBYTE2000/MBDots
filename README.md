# MBDots — NixOS config

Мой NixOS-конфиг (host: `nixos`, AMD Ryzen + NVIDIA GPU, LUKS + btrfs).
**Dendritic-style**: каждый файл `.nix` — самостоятельный модуль, авто-импорт
через `lib/importDir`.

`/etc/nixos` → symlink на этот репозиторий.

## Структура

```
.
├── flake.nix / flake.lock        — корневой flake (host: nixos)
├── hardware-configuration.nix    — сгенерирован install.sh
├── disko.nix                     — декларативная разметка (LUKS+btrfs)
├── install.sh                    — установщик для новой машины
├── WP.png                        — обои для Stylix
│
├── lib/default.nix               — importDir helper
│
├── hosts/nixos/default.nix       — сборка хоста: импорт + переключатели
│
├── modules/                      — системные (NixOS) модули
│   ├── core/                     — options, boot, nix, users, security
│   ├── hardware/                 — graphics, filesystems
│   ├── desktop/                  — sddm, xdg, fonts, stylix, audio, gvfs
│   ├── programs/                 — zsh, niri, dsh, system-packages
│   └── services/                 — docker/ollama/comfyui/wazuh/ssh
│                                   (по умолчанию выключены)
│
├── home/                         — home-manager модули (user mbyte)
│   ├── base.nix / packages.nix
│   ├── discord.nix               — nixcord + Vesktop (screen share fix)
│   ├── librewolf.nix
│   ├── noctalia.nix
│   └── nixvim/yazi/mangohud/flatpak.nix
│
├── gpu/                          — GPU-профили (install.sh кладёт в current.nix)
│   ├── nvidia.nix / amd.nix / intel.nix / none.nix
│   └── current.nix               — активный
│
├── config/                       — пользовательские dot-файлы для ~/.config/
│   ├── niri / alacritty / dolphinrc / okular* / etc
│
└── docs/
    ├── README.md / STRUCTURE.md / SERVICES.md / CUSTOMIZATION.md
```

## Быстрый старт

```bash
# Собрать и переключиться (создаёт rollback point):
update

# Эквиваленты + rollback-инструменты:
update-test     # nixos-rebuild test (без записи в загрузчик)
update-build    # nixos-rebuild build (только собрать в ./result)
update-full     # обновить flake inputs + switch
rollback        # nixos-rebuild switch --rollback (без ребута)
generations     # список всех поколений с датами
gen-diff        # diff между текущим и предыдущим (nvd)
```

GRUB держит последние 30 поколений (`boot.loader.grub.configurationLimit`),
из меню `NixOS - All configurations` доступен откат в 1 клик.

## Опциональные сервисы

Все "тяжёлые" сервисы выключены по умолчанию. Включаются флагом в
`hosts/nixos/default.nix`:

```nix
myConfig.services.docker.enable  = true;   # не автозапуск, только по требованию
myConfig.services.ollama.enable  = true;   # CUDA runtime для LLM
myConfig.services.comfyui.enable = true;   # требует внешний comfyui-nix input
myConfig.services.wazuh.enable   = true;   # SIEM-агент
myConfig.services.ssh.enable     = true;
```

Подробнее — `docs/SERVICES.md`.

## Установка на новую машину

```bash
git clone git@github.com:MBYTE2000/MBDots.git ~/nixos-config
cd ~/nixos-config
./install.sh              # ставит disko + rebuilds + монтирует конфиг
```

## Документация

- [docs/README.md](docs/README.md) — быстрый старт, откат
- [docs/STRUCTURE.md](docs/STRUCTURE.md) — дерево файлов и импорты
- [docs/SERVICES.md](docs/SERVICES.md) — опциональные сервисы + Vesktop screen share
- [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) — как добавить свой модуль/хост

## Discord + screen share (NVIDIA/Wayland)

Клиент — **Vesktop** (native PipeWire audio capture, единственный клиент
из семейства с работающим screen share со звуком на Wayland).
Vencord-плагины `webScreenShareFixes` (снимает лимит 2500kbps, чинит утечку
CPU) включены по умолчанию. Настройки — `home/discord.nix`.

## Кастомизация — коротко

Добавить пакет в систему → `modules/programs/system-packages.nix`.
Добавить пакет пользователю → `home/packages.nix`.
Добавить сервис → создать `modules/services/foo.nix` с `mkIf config.myConfig.services.foo.enable`, зарегистрировать опцию в `modules/core/options.nix`, включить в `hosts/nixos/default.nix`.

Полные примеры — `docs/CUSTOMIZATION.md`.
