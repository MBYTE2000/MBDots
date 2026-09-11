# Структура конфига

```
/etc/nixos/
├── flake.nix                 — entry point, inputs, home-manager сборка
├── flake.lock
├── hardware-configuration.nix — сгенерирован nixos-generate-config, не трогать
├── disko.nix                 — схема разметки (LUKS+btrfs) для install.sh
├── gpu/
│   └── current.nix           — текущий GPU-профиль (install.sh кладёт nvidia/amd/intel/none)
├── WP.png                    — обои для Stylix
│
├── lib/
│   └── default.nix           — importDir: авто-подхват .nix из директории
│
├── hosts/
│   └── nixos/
│       └── default.nix       — сборка хоста: импорт modules + переключатели фич
│
├── modules/                  — системные модули (NixOS), автоимпорт через importDir
│   ├── core/                 — обязательное ядро
│   │   ├── options.nix       — определения myConfig.* (mkEnableOption)
│   │   ├── nix.nix           — nix.settings, GC, allowUnfree
│   │   ├── boot.nix          — GRUB, plymouth, sysctl
│   │   ├── networking.nix    — hostname, NM, ethernet profile
│   │   ├── locale.nix        — timezone
│   │   ├── users.nix         — user mbyte
│   │   ├── security.nix      — auditd
│   │   └── session-env.nix   — Wayland/Ozone env
│   │
│   ├── hardware/
│   │   ├── graphics.nix      — hardware.graphics + Vulkan
│   │   └── filesystems.nix   — mount /mnt/data (Samsung 1TB SSD)
│   │
│   ├── desktop/
│   │   ├── sddm.nix          — display manager (по флагу)
│   │   ├── xdg.nix           — xdg-desktop-portal + GNOME/GTK
│   │   ├── audio.nix         — pipewire+pulse
│   │   ├── gvfs.nix          — gvfs/udisks
│   │   ├── stylix.nix        — тема (по флагу)
│   │   ├── fonts.nix         — шрифты (по флагу)
│   │   └── printing.nix      — CUPS + Samsung
│   │
│   ├── programs/
│   │   ├── zsh.nix           — zsh+oh-my-zsh+starship+aliases (update alias)
│   │   ├── niri.nix          — programs.niri
│   │   ├── dsh.nix           — Nix bundles launcher
│   │   └── system-packages.nix — глобальные CLI/GUI пакеты
│   │
│   └── services/             — всё выключено по умолчанию, включай в hosts/nixos/default.nix
│       ├── docker.nix        — myConfig.services.docker.enable
│       ├── ollama.nix        — myConfig.services.ollama.enable  (CUDA)
│       ├── comfyui.nix       — myConfig.services.comfyui.enable
│       ├── wazuh.nix         — myConfig.services.wazuh.enable
│       ├── ssh.nix           — myConfig.services.ssh.enable
│       └── flatpak.nix       — Flatpak (включён)
│
├── home/                     — home-manager модули (пользователь mbyte)
│   ├── base.nix              — username, homeDir, stateVersion, импорт nixvim/nixcord
│   ├── packages.nix          — home.packages
│   ├── shell/nixvim/yazi/mangohud/flatpak.nix — по одной программе
│   ├── discord.nix           — nixcord + Vesktop
│   ├── librewolf.nix         — LibreWolf через programs.firefox
│   └── noctalia.nix          — top bar / launcher / control center
│
└── docs/
    ├── README.md
    ├── STRUCTURE.md          — этот файл
    ├── SERVICES.md
    └── CUSTOMIZATION.md
```

## Как работает автоимпорт

`lib/default.nix` предоставляет `importDir`, который читает содержимое директории,
пропускает `default.nix`, и возвращает список путей ко всем `.nix` файлам и
поддиректориям. Каждая директория содержит `default.nix` вида:

```nix
{ lib, ... }:
let myLib = import ../../lib { inherit lib; };
in { imports = myLib.importDir ./.; }
```

## Как работают переключатели

`modules/core/options.nix` определяет пространство опций `myConfig.*`:

```nix
options.myConfig.services.docker.enable = lib.mkEnableOption "Docker";
```

Модули-сервисы оборачивают свои настройки в `config = lib.mkIf ...`:

```nix
config = lib.mkIf config.myConfig.services.docker.enable {
  virtualisation.docker.enable = true;
};
```

Хост включает нужные фичи в `hosts/nixos/default.nix`:

```nix
myConfig.services.docker.enable = true;
```
