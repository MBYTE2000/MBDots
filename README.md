# nixos-config

Мой NixOS-конфиг для хоста `nixos` (AMD Ryzen + NVIDIA GPU, LUKS + btrfs).
Dendritic-style: каждый файл `.nix` — самостоятельный модуль, авто-импорт
через `lib/importDir`.

`/etc/nixos` → symlink на этот репозиторий.

## Сборка

```bash
update
# = sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

## Документация

- [docs/README.md](docs/README.md) — быстрый старт, откат
- [docs/STRUCTURE.md](docs/STRUCTURE.md) — дерево файлов
- [docs/SERVICES.md](docs/SERVICES.md) — docker/ollama/comfyui/wazuh/vesktop
- [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) — как добавлять свои модули
