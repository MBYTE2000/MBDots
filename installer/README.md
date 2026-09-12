# MBDots installer

TUI-установщик NixOS для этого репозитория.

## Как запустить

С NixOS Live ISO (25.11+):

```bash
git clone https://github.com/MBYTE2000/MBDots.git
cd MBDots
./install.sh
```

`install.sh` — тонкий bootstrap: поднимает `nix-shell -p nodejs_22`,
ставит npm-зависимости TUI в `installer/node_modules/` (одноразово,
кешируется в /nix/store через npm) и запускает `installer/index.mjs`.

## Что спрашивает TUI

1. **Диск** — выбор из `lsblk` (стрелки, Enter). Размер + модель + транспорт.
2. **Hostname** — валидируется (буквы/цифры/дефис).
3. **Пользователь** — валидируется (unix-username).
4. **GPU-профиль** — nvidia / amd / intel / none.
5. **Timezone** — с автодополнением.
6. **LUKS-пароль** — с подтверждением.
7. **Финальное подтверждение** — введи `YES` заглавными, чтобы стереть диск.

## Что делает

1. Клонирует репо в `/tmp/mbdots-XXXX`.
2. Патчит копию: hostname во всех местах (flake output, `networking.hostName`,
   `update` alias), username (users, home-manager), timezone,
   активирует `gpu/<gpu>.nix` → `gpu/current.nix`.
3. Кладёт LUKS-пароль в файл (mode 600), подставляет `passwordFile` в disko.nix.
4. `nix run github:nix-community/disko` → destroy, format, mount `/mnt`.
5. Копирует конфиг в `/mnt/etc/nixos`.
6. `nixos-generate-config --root /mnt --force`.
7. `nixos-install --flake /mnt/etc/nixos#<hostname>`.
8. Копирует `config/` в `~/.config/`, репо — в `~/nixos-config`,
   `/etc/nixos` → symlink на git-репо в $HOME.
9. Пароль пользователя через `nixos-enter -c passwd`.
10. Спрашивает про reboot.

## Файлы

```
installer/
├── package.json           — npm-deps (prompts, chalk, figlet, gradient, ora, execa, boxen)
├── index.mjs              — оркестратор
└── lib/
    ├── branding.mjs       — banner, палитра, боксы (MBDots gradient)
    ├── prompts.mjs        — интерактивные вопросы + валидация
    ├── steps.mjs          — patchFile, disko, nixos-install
    └── util.mjs           — sh/shStream/lsblk/preflight
```

## Demo (просмотр UI без установки)

```bash
cd installer
nix-shell -p nodejs_22 --run "npm install --omit=dev --loglevel=error && npm run demo"
```

Или, если node уже стоит:

```bash
cd installer && npm install --omit=dev && node demo.mjs
```

Демо неинтерактивно проигрывает все 8 экранов подряд с задержками —
баннер, preflight, промпты, summary/warning/success боксы, эмуляцию
disko/nixos-install streams. Реальной установки не происходит.

## Development

Установщик — чистый Node 20+ ESM, без билд-шага (JSX / TS / bundler не нужны).

- `bash -n install.sh` — проверка синтаксиса
- `node --check installer/**/*.mjs` — проверка JS
- `npm run demo` — визуальный smoke-test

Полный запуск возможен только с NixOS Live ISO — на живой системе шаг disko
попытается стереть диск.
