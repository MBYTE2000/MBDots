# Опциональные сервисы

Все "тяжёлые" сервисы выключены по умолчанию и включаются флагом в
`hosts/nixos/default.nix`. Собери систему через `update` после изменений.

## Docker

```nix
myConfig.services.docker.enable = true;
```

Включает `virtualisation.docker`, но НЕ запускает daemon автоматически
(`wantedBy = [];`). Работает по требованию: `sudo systemctl start docker`.
Пользователь `mbyte` уже в группе `docker`.

## Ollama (LLM runtime с CUDA)

```nix
myConfig.services.ollama.enable = true;
```

Использует пакет `ollama-cuda`. После сборки:

```bash
ollama pull llama3.2:3b
ollama run llama3.2:3b
```

Чтобы предзагружать модели декларативно — раскомментируй `loadModels` в
`modules/services/ollama.nix`.

## ComfyUI (Stable Diffusion)

```nix
myConfig.services.comfyui.enable = true;
```

**Требует:**
1. Раскомментировать `comfyui-nix.url` в `flake.nix` (inputs).
2. Раскомментировать `comfyui-nix.nixosModules.default` в `flake.nix` (outputs modules).
3. Опционально раскомментировать `comfyui.cachix.org` в `modules/core/nix.nix`.
4. Данные в `/mnt/data/comfyui` (создаётся при первом запуске).

Порт: `127.0.0.1:8188`. Автозапуск отключён.

## Wazuh agent (SIEM)

```nix
myConfig.services.wazuh.enable = true;
```

Ставит пользователя `wazuh`, nix-ld окружение и helper-скрипты. Сам бинарник
не в nixpkgs — после `update` запусти:

```bash
wazuh-setup     # Скачивает .deb 4.14.3 и распаковывает в /var/ossec
wazuh-service {start|stop|restart|status|logs}
```

Сервер: `10.50.0.25:1514/tcp`. IP менять в `modules/services/wazuh.nix`.

## Discord (Vesktop) — screen share

Discord управляется через `home/discord.nix` (nixcord + Vesktop).
Vesktop выбран потому что он единственный из семейства умеет захватывать
системный звук через PipeWire на Wayland (виртуальный микрофон
`vencord-screen-share`).

Что должно быть включено (уже настроено):
- `hardware.graphics.enable = true` — иначе WebRTC capture молча падает
- `services.pipewire.enable = true`
- `xdg.portal` содержит `xdg-desktop-portal-gnome` (у -gtk нет ScreenCast)
- `GSK_RENDERER=gl` для xdg-desktop-portal-gnome (обход краша на NVIDIA)
- Vencord плагины `webScreenShareFixes` и `webScreenShare`

Если демонстрация экрана всё ещё чёрная на NVIDIA:
1. Открой Vesktop → Settings → Vesktop Settings → выключи **Hardware Acceleration**
2. Перезапусти Vesktop
3. При старте screen share выбирай источник через **xdg-desktop-portal**
   (Vesktop сам вызовет диалог GNOME)
4. В настройках стрима включи "Share Audio" — оно работает через PipeWire

## SSH

```nix
myConfig.services.ssh.enable = true;
```

Просто `services.openssh.enable = true`. Пробрось порт в firewall вручную,
если он у тебя включён.
