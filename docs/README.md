# MBYTE NixOS Config

Дендритный (dendritic-style) NixOS конфиг с фокусом на текущий ПК — `nixos`
(AMD CPU + NVIDIA GPU, LUKS + btrfs).

## Что это такое

Каждый файл `.nix` — самостоятельный модуль, отвечающий ровно за одну вещь
(один сервис, один блок настроек, один пакет). Файлы автоматически подхватываются
из директорий через `lib/importDir`. Композиция и переключатели сведены
в один хост-файл `hosts/nixos/default.nix`.

## Быстрый старт

```bash
# Собрать и переключиться (алиас, атомарно, создаёт поколение → пункт в GRUB):
update

# Только собрать в ./result, не активировать:
update-build

# Активировать без записи в загрузчик (откатится сам после ребута):
update-test

# Обновить flake inputs и пересобрать:
update-full
```

## Откат

Каждый `update` создаёт новое поколение → пункт в GRUB. Держим последние 30
(см. `configurationLimit` в `modules/core/boot.nix`).

```bash
generations       # список всех поколений с датами
rollback          # откатиться на предыдущее (без ребута)
gen-diff          # что изменилось между текущим и прошлым

# Из GRUB: `NixOS - All configurations` → выбрать нужное поколение.
```

## Куда смотреть

| Задача | Файл |
|---|---|
| Включить/выключить сервис (docker/ollama/comfyui/wazuh) | `hosts/nixos/default.nix` |
| Добавить пакет в систему | `modules/programs/system-packages.nix` |
| Добавить пакет в home-manager | `home/packages.nix` |
| Настройка загрузчика | `modules/core/boot.nix` |
| Сеть, IP | `modules/core/networking.nix` |
| Пользователь | `modules/core/users.nix` |
| DE (SDDM/Niri) | `modules/desktop/*.nix` |
| GPU-профиль | `gpu/current.nix` (`install.sh` управляет) |
| Firefox/LibreWolf | `home/librewolf.nix` |
| Discord/Vesktop | `home/discord.nix` |

## Документация

- [STRUCTURE.md](STRUCTURE.md) — дерево файлов и как что импортируется
- [SERVICES.md](SERVICES.md) — как включить docker/ollama/comfyui/wazuh
- [CUSTOMIZATION.md](CUSTOMIZATION.md) — как добавлять свои модули
